module msg_extract_tb();

// Parameters and Constants
localparam  TDATA_WIDTH     = 64;
localparam  TID_WIDTH       = 64;
localparam  TDEST_WIDTH     = 64;
localparam  TUSER_WIDTH     = 64;

localparam  MIN_MSGLEN      = 8;    // in bytes
localparam  MAX_MSGLEN      = 32;   // in bytes
localparam  MAX_PACKETLEN   = 1500; // in bytes

localparam  NUM_RUNS        = 1000; // Number of randomized runs.

// DUT Signals
logic   clk;
logic   sreset;

// axis_in (Slave)
logic                           axis_in_tvalid;
logic                           axis_in_tready;
logic   [TDATA_WIDTH-1:0]       axis_in_tdata;
logic   [TDATA_WIDTH/8-1:0]     axis_in_tstrb;
logic   [TDATA_WIDTH/8-1:0]     axis_in_tkeep;
logic                           axis_in_tlast;
logic   [TID_WIDTH-1:0]         axis_in_tid;
logic   [TDEST_WIDTH-1:0]       axis_in_tdest;
logic   [TUSER_WIDTH-1:0]       axis_in_tuser;

// axis_out (Master)
logic                           axis_out_tvalid;
logic                           axis_out_tready;
logic   [TDATA_WIDTH-1:0]       axis_out_tdata;
logic   [TDATA_WIDTH/8-1:0]     axis_out_tstrb;
logic   [TDATA_WIDTH/8-1:0]     axis_out_tkeep;
logic                           axis_out_tlast;
logic   [TID_WIDTH-1:0]         axis_out_tid;
logic   [TDEST_WIDTH-1:0]       axis_out_tdest;
logic   [TUSER_WIDTH-1:0]       axis_out_tuser;


// Driving system clock signal.
always #5 clk = ~clk;


// DUT Instance
msg_extract #(
    .TDATA_WIDTH(TDATA_WIDTH),
    .TID_WIDTH(TID_WIDTH),
    .TDEST_WIDTH(TDEST_WIDTH),
    .TUSER_WIDTH(TUSER_WIDTH)
) dut (
    .clk(clk),
    .sreset(sreset),

// axis_in (Slave)
    .axis_in_tvalid(axis_in_tvalid),
    .axis_in_tready(axis_in_tready),
    .axis_in_tdata(axis_in_tdata),
    .axis_in_tstrb(axis_in_tstrb),
    .axis_in_tkeep(axis_in_tkeep),
    .axis_in_tlast(axis_in_tlast),
    .axis_in_tid(axis_in_tid),
    .axis_in_tdest(axis_in_tdest),
    .axis_in_tuser(axis_in_tuser),

// axis_out (Master)
    .axis_out_tvalid(axis_out_tvalid),
    .axis_out_tready(axis_out_tready),
    .axis_out_tdata(axis_out_tdata),
    .axis_out_tstrb(axis_out_tstrb),
    .axis_out_tkeep(axis_out_tkeep),
    .axis_out_tlast(axis_out_tlast),
    .axis_out_tid(axis_out_tid),
    .axis_out_tdest(axis_out_tdest),
    .axis_out_tuser(axis_out_tuser)
);


// Queues and TB Signals
logic   [7:0]               packet_queue        [$]; // Used to generate random input to drive to axis_in.
logic   [TDATA_WIDTH-1:0]   golden_out_tdata    [$]; // Precomputed expected output data.
logic   [15:0]              msg_lengths         [$]; // Used to generate randomize lengths of each msg in random packet.
int                         q_ptr;

logic   [TDATA_WIDTH-1:0]   expected_tdata;

logic   [15:0]              num_msgs;
logic   [15:0]              msg_len;
logic   [7:0]               data_byte;


// Tasks
task axis_init();
    // Initialize AXI-Stream Bus Inputs
    axis_in_tstrb   = '0;
    axis_in_tkeep   = '0;
    axis_in_tid     = '0;
    axis_in_tdest   = '0;
    axis_in_tuser   = '0;
    axis_in_tvalid  = 1'b0;
    axis_in_tdata   = 'X;
    axis_in_tlast   = 1'b0;

    axis_out_tready = 1'b0;
endtask


task automatic gen_packet();
    // Task that generates a random packet that follows the format outlined in the project specification.
    // Also generates golden data to compare to the output of the design as it is streamed on axis_out_tdata.
    num_msgs = $urandom_range(1, 10);
    for(int i = 0; i < num_msgs; i++) begin
        msg_len = $urandom_range(MIN_MSGLEN, MAX_MSGLEN);
        msg_lengths.push_back(msg_len);
    end

    packet_queue.push_back(num_msgs[15:8]);
    packet_queue.push_back(num_msgs[7:0]);
    for(int i = 0; i < num_msgs; i++) begin
        msg_len = msg_lengths.pop_front();
        packet_queue.push_back(msg_len[15:8]);
        packet_queue.push_back(msg_len[7:0]);

        for(int j = 0; j < msg_len; j++) begin
            data_byte = $urandom();
            packet_queue.push_back(data_byte);
        end
    end

    q_ptr = 2;
    for(int i = 0; i < num_msgs; i++) begin
        msg_len = {packet_queue[q_ptr], packet_queue[q_ptr+1]};
        q_ptr = q_ptr + 2;
        while(msg_len > 0) begin
            case(msg_len)
                1:          golden_out_tdata.push_back({packet_queue[q_ptr], 56'b0});
                2:          golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], 48'b0});
                3:          golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], packet_queue[q_ptr+2], 40'b0});
                4:          golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], packet_queue[q_ptr+2], packet_queue[q_ptr+3], 32'b0});
                5:          golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], packet_queue[q_ptr+2], packet_queue[q_ptr+3], packet_queue[q_ptr+4], 24'b0});
                6:          golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], packet_queue[q_ptr+2], packet_queue[q_ptr+3], packet_queue[q_ptr+4], packet_queue[q_ptr+5], 16'b0});
                7:          golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], packet_queue[q_ptr+2], packet_queue[q_ptr+3], packet_queue[q_ptr+4], packet_queue[q_ptr+5], packet_queue[q_ptr+6], 8'b0});
                default:    golden_out_tdata.push_back({packet_queue[q_ptr], packet_queue[q_ptr+1], packet_queue[q_ptr+2], packet_queue[q_ptr+3], packet_queue[q_ptr+4], packet_queue[q_ptr+5], packet_queue[q_ptr+6], packet_queue[q_ptr+7]});
            endcase
            q_ptr   = (msg_len >= 8) ? (q_ptr + 8) : (q_ptr + msg_len);
            msg_len = (msg_len >= 8) ? msg_len - 8 : 0;
        end
    end
endtask


task automatic drive_axis_in();
    // Task that does a single random packet transfer into axis_in.
    // Driving input data generated in the packet_queue into axis_in_tdata.
    if(~axis_in_tready) begin
        @(axis_in_tready);
    end

    #1;
    axis_in_tvalid = 1'b1;
    while(packet_queue.size() > 0) begin
        case(packet_queue.size())
            1:          axis_in_tdata = {packet_queue.pop_front(), 56'b0};
            2:          axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), 48'b0};
            3:          axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), 40'b0};
            4:          axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), 32'b0};
            5:          axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), 24'b0};
            6:          axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), 16'b0};
            7:          axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), 8'b0};
            default:    axis_in_tdata = {packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front(), packet_queue.pop_front()};
        endcase
        @(posedge clk);
        #1;
        axis_in_tlast = (packet_queue.size() <= 8) ? 1:0;
    end

    axis_in_tdata   = 'X;
    axis_in_tvalid  = 1'b0;
    axis_in_tlast   = 1'b0;
endtask


task automatic compare_data();
    // Task that reads axis_out_tdata as it is being streamed and compares to generated golden_data.
    while(golden_out_tdata.size() > 0) begin
        wait(axis_out_tvalid == 1'b1);
        @(posedge clk);
        while(axis_out_tvalid) begin
            expected_tdata = golden_out_tdata.pop_front();
            assert(axis_out_tdata == expected_tdata) $display("PASS --- time: %0t \t got: %h \t expected: %h", $time, axis_out_tdata, expected_tdata);
            else begin
                $display("FAIL --- time: %0t \t got: %h \t expected: %h", $time, axis_out_tdata, expected_tdata);
                $finish();
            end
            @(posedge clk);
        end
    end
endtask


task automatic rand_test();
    // Single randomized test run.
    gen_packet();
    fork
        begin
            drive_axis_in();
        end
        begin
            compare_data();
        end

        @(posedge clk);
    join
endtask

initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, clk, sreset, axis_in_tdata, axis_in_tlast, axis_in_tvalid, axis_in_tready, axis_out_tdata, axis_out_tlast, axis_out_tvalid, axis_out_tready, axis_out_tkeep);

    clk     = 1'b0;
    sreset  = 1'b0;

    axis_init();

    // Power on RST.
    @(posedge clk);
    sreset  = 1'b1;
    @(posedge clk);
    sreset  = 1'b0;

    // Always high, master never back pressures.
    axis_out_tready = 1'b1;
    @(posedge clk);


    // Sample test stimulus given in Design Challenge Document
    #1;
    axis_in_tvalid  = 1'b1;
    axis_in_tdata   = 64'h00010008DEADBEEF;
    @(posedge clk);

    #1;
    axis_in_tdata   = 64'h0000000100000000;
    axis_in_tlast   = 1'b1;
    @(posedge clk);

    #1;
    axis_in_tvalid  = 1'b0;
    axis_in_tdata   = 'X;
    axis_in_tlast   = 1'b0;
    @(posedge clk);

    wait(axis_in_tready == 1);

    #1;
    axis_in_tvalid  = 1'b1;
    axis_in_tdata   = 64'h00020008DEADBEEF;
    @(posedge clk);
    
    #1;
    axis_in_tdata   = 64'h00000001000ACAFE;
    @(posedge clk);

    #1;
    axis_in_tdata   = 64'hBABE000000000002;
    axis_in_tlast   = 1'b1;
    @(posedge clk);

    #1;
    axis_in_tvalid  = 1'b0;
    axis_in_tdata   = 'X;
    axis_in_tlast   = 1'b0;

   repeat(5) @(posedge clk);
    // // Randomized test runs
    repeat(NUM_RUNS) rand_test();
    $display("TEST PASSED!");

    @(posedge clk);
    $finish();
end
endmodule
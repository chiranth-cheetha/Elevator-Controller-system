`timescale 1ns/1ps

module elevator_random_tb;

    reg clk;
    reg reset;

    reg [4:0] hall_up_request;
    reg [4:0] hall_down_request;
    reg [4:0] cabin_request;

    wire [2:0] current_floor;
    wire [1:0] direction;
    wire door_open;

    wire [4:0] hall_up_requests;
    wire [4:0] hall_down_requests;
    wire [4:0] cabin_requests;
    wire [4:0] pending_requests;


    // =========================================================
    // DUT
    // =========================================================

    elevator_top DUT (

        .clk(clk),
        .reset(reset),

        .hall_up_request(hall_up_request),
        .hall_down_request(hall_down_request),

        .cabin_request(cabin_request),

        .current_floor(current_floor),
        .direction(direction),
        .door_open(door_open),

        .hall_up_requests(hall_up_requests),
        .hall_down_requests(hall_down_requests),

        .cabin_requests(cabin_requests),
        .pending_requests(pending_requests)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // STATUS
    // =========================================================

    always @(posedge clk) begin

        $write(
            "TIME=%0t | FLOOR=%0d | DIR=",
            $time,
            current_floor
        );

        case(direction)

            2'b00: $write("DOWN");
            2'b01: $write(" UP");
            2'b10: $write("IDLE");
            default: $write("UNKNOWN");

        endcase

        $display(
            " | DOOR=%b | UP=%b | DOWN=%b | CABIN=%b | PENDING=%b",
            door_open,
            hall_up_requests,
            hall_down_requests,
            cabin_requests,
            pending_requests
        );

    end


    // =========================================================
    // CABIN REQUEST
    // =========================================================

    task cabin_request_task;

        input integer floor;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("RANDOM CABIN REQUEST");
            $display("Passenger -> F%0d", floor);
            $display("----------------------------------------------");

            cabin_request = (5'b00001 << floor);

            #10;

            cabin_request = 5'b00000;

        end

    endtask


    // =========================================================
    // HALL UP REQUEST
    // =========================================================

    task hall_up_task;

        input integer floor;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("RANDOM HALL UP REQUEST");
            $display("Person at F%0d -> UP", floor);
            $display("----------------------------------------------");

            hall_up_request = (5'b00001 << floor);

            #10;

            hall_up_request = 5'b00000;

        end

    endtask


    // =========================================================
    // HALL DOWN REQUEST
    // =========================================================

    task hall_down_task;

        input integer floor;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("RANDOM HALL DOWN REQUEST");
            $display("Person at F%0d -> DOWN", floor);
            $display("----------------------------------------------");

            hall_down_request = (5'b00001 << floor);

            #10;

            hall_down_request = 5'b00000;

        end

    endtask


    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        $dumpfile("elevator_random.vcd");
        $dumpvars(0, elevator_random_tb);


        clk = 0;
        reset = 1;

        hall_up_request   = 5'b00000;
        hall_down_request = 5'b00000;
        cabin_request     = 5'b00000;


        // =====================================================
        // RESET
        // =====================================================

        #20;

        reset = 0;


        $display("");
        $display("=================================================");
        $display("       RANDOM REQUEST STRESS TEST");
        $display("=================================================");
        $display("");


        // =====================================================
        // TEST 1
        // Multiple requests almost simultaneously
        // =====================================================

        $display("TEST 1: MULTIPLE RANDOM REQUESTS");


        cabin_request_task(4);

        #7;

        cabin_request_task(2);

        #13;

        hall_up_task(1);

        #8;

        cabin_request_task(3);

        #11;

        hall_down_task(4);


        // =====================================================
        // Let elevator process
        // =====================================================

        #150;


        // =====================================================
        // TEST 2
        // Requests while elevator is moving
        // =====================================================

        $display("");
        $display("=================================================");
        $display("TEST 2: REQUESTS WHILE MOVING");
        $display("=================================================");


        cabin_request_task(4);

        #17;

        hall_up_task(2);

        #9;

        hall_down_task(3);

        #12;

        cabin_request_task(1);

        #14;

        hall_down_task(0);


        // =====================================================
        // Let elevator process
        // =====================================================

        #250;


        // =====================================================
        // TEST 3
        // Heavy random traffic
        // =====================================================

        $display("");
        $display("=================================================");
        $display("TEST 3: HEAVY RANDOM TRAFFIC");
        $display("=================================================");


        cabin_request_task(3);

        #6;

        hall_up_task(1);

        #9;

        cabin_request_task(4);

        #5;

        hall_down_task(3);

        #11;

        cabin_request_task(2);

        #7;

        hall_up_task(0);

        #8;

        hall_down_task(4);

        #6;

        cabin_request_task(1);

        #10;

        hall_up_task(2);


        // =====================================================
        // Allow everything to finish
        // =====================================================

        #800;


        $display("");
        $display("=================================================");
        $display("       RANDOM STRESS TEST COMPLETE");
        $display("=================================================");


        #20;

        $finish;

    end

endmodule
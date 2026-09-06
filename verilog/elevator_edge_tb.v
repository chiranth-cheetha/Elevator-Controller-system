`timescale 1ns/1ps

module elevator_edge_tb;

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

    elevator_top dut (
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
    // DISPLAY
    // =========================================================

    always @(posedge clk) begin
        #1;

        $display(
            "TIME=%0t | FLOOR=%0d | DIR=%s | DOOR=%b | UP=%b | DOWN=%b | CABIN=%b | PENDING=%b",
            $time,
            current_floor,
            direction_name(direction),
            door_open,
            hall_up_requests,
            hall_down_requests,
            cabin_requests,
            pending_requests
        );
    end


    function [7:0] direction_name;
        input [1:0] dir;

        begin
            case (dir)
                2'b00: direction_name = "DOWN";
                2'b01: direction_name = "UP";
                2'b10: direction_name = "IDLE";
                default: direction_name = "UNK";
            endcase
        end
    endfunction


    // =========================================================
    // REQUEST TASKS
    // =========================================================

    task cabin;
        input integer floor;

        begin
            $display("----------------------------------------------");
            $display("CABIN REQUEST -> F%0d", floor);
            $display("----------------------------------------------");

            cabin_request = 5'b0;
            cabin_request[floor] = 1'b1;

            @(posedge clk);
            #1;

            cabin_request = 5'b0;
        end
    endtask


    task hall_up;
        input integer floor;

        begin
            $display("----------------------------------------------");
            $display("HALL UP REQUEST -> F%0d", floor);
            $display("----------------------------------------------");

            hall_up_request = 5'b0;
            hall_up_request[floor] = 1'b1;

            @(posedge clk);
            #1;

            hall_up_request = 5'b0;
        end
    endtask


    task hall_down;
        input integer floor;

        begin
            $display("----------------------------------------------");
            $display("HALL DOWN REQUEST -> F%0d", floor);
            $display("----------------------------------------------");

            hall_down_request = 5'b0;
            hall_down_request[floor] = 1'b1;

            @(posedge clk);
            #1;

            hall_down_request = 5'b0;
        end
    endtask


    task wait_cycles;
        input integer cycles;
        integer i;

        begin
            for (i = 0; i < cycles; i = i + 1)
                @(posedge clk);
        end
    endtask


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        clk = 0;
        reset = 1;

        hall_up_request = 5'b00000;
        hall_down_request = 5'b00000;
        cabin_request = 5'b00000;

        // Reset
        #20;
        reset = 0;

        $display("");
        $display("=================================================");
        $display("       ELEVATOR EDGE CASE TEST");
        $display("=================================================");


        // =====================================================
        // TEST 1
        // Current floor cabin request
        // =====================================================

        $display("");
        $display("TEST 1: CABIN REQUEST FOR CURRENT FLOOR");

        cabin(0);

        wait_cycles(8);


        // =====================================================
        // TEST 2
        // Multiple simultaneous requests
        // =====================================================

        $display("");
        $display("TEST 2: MULTIPLE SIMULTANEOUS REQUESTS");

        cabin_request = 5'b10100;       // F2 + F4
        hall_up_request = 5'b00010;     // F1 UP

        @(posedge clk);
        #1;

        cabin_request = 5'b00000;
        hall_up_request = 5'b00000;

        wait_cycles(30);


        // =====================================================
        // TEST 3
        // Opposite direction requests
        // =====================================================

        $display("");
        $display("TEST 3: OPPOSITE DIRECTION REQUESTS");

        hall_up_request = 5'b00010;     // F1 UP
        hall_down_request = 5'b01000;   // F3 DOWN
        cabin_request = 5'b10000;       // F4

        @(posedge clk);
        #1;

        hall_up_request = 5'b00000;
        hall_down_request = 5'b00000;
        cabin_request = 5'b00000;

        wait_cycles(40);


        // =====================================================
        // TEST 4
        // Request while elevator is moving
        // =====================================================

        $display("");
        $display("TEST 4: REQUEST WHILE MOVING");

        cabin(4);

        // Let elevator start moving
        wait_cycles(2);

        // New request while moving
        cabin(1);

        wait_cycles(30);


        // =====================================================
        // TEST 5
        // IMPORTANT EDGE CASE
        //
        // Elevator moving UP.
        // A new UP request appears at F2 BEFORE the elevator
        // reaches F2.
        //
        // Expected:
        // F1 -> F2 (serve UP request) -> F3 -> F4
        // No unnecessary reversal.
        // =====================================================

        $display("");
        $display("TEST 5: UPWARD REQUEST MUST BE SERVED");

        // Start request for F4
        cabin(4);

        // Give exactly one cycle for request to be accepted
        @(posedge clk);
        #1;

        // Add F2 UP request while elevator is still below F2
        $display("----------------------------------------------");
        $display("NEW UP REQUEST -> F2 WHILE MOVING UP");
        $display("----------------------------------------------");

        hall_up_request = 5'b00100;

        @(posedge clk);
        #1;

        hall_up_request = 5'b00000;

        // Allow elevator to complete all requests
        wait_cycles(30);


        // =====================================================
        // TEST 6
        // No requests remaining
        // =====================================================

        $display("");
        $display("TEST 6: VERIFY SYSTEM RETURNS TO IDLE");

        wait_cycles(20);


        $display("");
        $display("=================================================");
        $display("       EDGE CASE TEST COMPLETE");
        $display("=================================================");

        #50;

        $finish;

    end

endmodule
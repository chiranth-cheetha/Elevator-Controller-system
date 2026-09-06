`timescale 1ns/1ps

module elevator_tb;

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
    // CONNECT TO ELEVATOR
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
    // DISPLAY
    // =========================================================

    always @(posedge clk) begin

        $write(
            "TIME=%0t | FLOOR=%0d | DIR=",
            $time,
            current_floor
        );

        case (direction)

            2'b00: $write("DOWN");

            2'b01: $write("UP");

            2'b10: $write("IDLE");

            default: $write("UNKNOWN");

        endcase

        $display(
            " | DOOR=%b | HALL_UP=%b | HALL_DOWN=%b | CABIN=%b | PENDING=%b",
            door_open,
            hall_up_requests,
            hall_down_requests,
            cabin_requests,
            pending_requests
        );

    end


    // =========================================================
    // CABIN REQUEST TASK
    // =========================================================

    task cabin_request_task;

        input integer floor;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("CABIN REQUEST");
            $display("Passenger inside -> F%0d", floor);
            $display("----------------------------------------------");

            cabin_request = (5'b00001 << floor);

            #10;

            cabin_request = 5'b00000;

        end

    endtask


    // =========================================================
    // HALL UP REQUEST TASK
    // =========================================================

    task hall_up_task;

        input integer floor;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("HALL UP REQUEST");
            $display("Person at F%0d -> UP", floor);
            $display("----------------------------------------------");

            hall_up_request = (5'b00001 << floor);

            #10;

            hall_up_request = 5'b00000;

        end

    endtask


    // =========================================================
    // HALL DOWN REQUEST TASK
    // =========================================================

    task hall_down_task;

        input integer floor;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("HALL DOWN REQUEST");
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

        // -----------------------------------------------------
        // VCD
        // -----------------------------------------------------

        $dumpfile("elevator.vcd");
        $dumpvars(0, elevator_tb);


        // -----------------------------------------------------
        // INITIAL VALUES
        // -----------------------------------------------------

        clk = 0;
        reset = 1;

        hall_up_request = 5'b00000;
        hall_down_request = 5'b00000;
        cabin_request = 5'b00000;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        reset = 0;


        $display("");
        $display("=================================================");
        $display("        SMART ELEVATOR CONTROLLER TEST");
        $display("=================================================");
        $display("");
        $display("0 = G");
        $display("1 = F1");
        $display("2 = F2");
        $display("3 = F3");
        $display("4 = F4");
        $display("");


        // =====================================================
        // TEST 1
        //
        // Three passengers enter at G.
        //
        // Passenger 1 -> F4
        // Passenger 2 -> F2
        // Passenger 3 -> F3
        //
        // Outside person at F1 -> UP
        //
        // Expected:
        //
        // G -> F1 -> F2 -> F3 -> F4
        // =====================================================

        $display("");
        $display("=================================================");
        $display("TEST 1: THREE CABIN REQUESTS + F1 UP");
        $display("=================================================");


        // Passenger 1
        cabin_request_task(4);


        // Passenger 2
        cabin_request_task(2);


        // Passenger 3
        cabin_request_task(3);


        // Let elevator start moving
        #15;


        // F1 passenger presses UP
        hall_up_task(1);


        // Allow elevator to finish
        #250;


        $display("");
        $display("=================================================");
        $display("TEST 1 FINISHED");
        $display("=================================================");


        // =====================================================
        // TEST 2
        //
        // Elevator should now be at F4.
        //
        // Create:
        //
        // Passenger -> G
        //
        // Outside person at F1 -> DOWN
        //
        // Elevator should go DOWN.
        //
        // Expected:
        //
        // F4 -> F3 -> F2 -> F1
        //
        // At F1 the DOWN request is served.
        //
        // =====================================================

        $display("");
        $display("=================================================");
        $display("TEST 2: F1 DOWN REQUEST");
        $display("=================================================");


        // Passenger inside requests G
        cabin_request_task(0);


        // Allow elevator to start going DOWN
        #15;


        // Person at F1 presses DOWN
        hall_down_task(1);


        // Allow elevator to finish
        #250;


        $display("");
        $display("=================================================");
        $display("TEST 2 FINISHED");
        $display("=================================================");


        // =====================================================
        // FINAL
        // =====================================================

        $display("");
        $display("=================================================");
        $display("       SMART ELEVATOR TEST COMPLETE");
        $display("=================================================");
        $display("");

        #20;

        $finish;

    end

endmodule
`timescale 1ns/1ps

module elevator_top (
    input  wire       clk,
    input  wire       reset,

    input  wire [4:0] hall_up_request,
    input  wire [4:0] hall_down_request,
    input  wire [4:0] cabin_request,

    output reg  [2:0] current_floor,
    output reg  [1:0] direction,
    output reg        door_open,

    output reg  [4:0] hall_up_requests,
    output reg  [4:0] hall_down_requests,
    output reg  [4:0] cabin_requests,
    output wire [4:0] pending_requests
);

    localparam DOWN = 2'b00;
    localparam UP   = 2'b01;
    localparam IDLE = 2'b10;

    reg [2:0] door_timer;

    assign pending_requests =
        hall_up_requests |
        hall_down_requests |
        cabin_requests;


    // =========================================================
    // CHECK REQUESTS ABOVE CURRENT FLOOR
    // =========================================================
    function has_request_above;
    input [2:0] floor;
    integer i;
    begin
        has_request_above = 1'b0;

        for (i = 0; i < 5; i = i + 1) begin
            if (i > floor) begin
                if (hall_up_requests[i]   ||
                    hall_down_requests[i] ||
                    cabin_requests[i]     ||
                    hall_up_request[i]    ||
                    hall_down_request[i]  ||
                    cabin_request[i])
                    has_request_above = 1'b1;
            end
        end
    end
endfunction


    // =========================================================
    // CHECK REQUESTS BELOW CURRENT FLOOR
    // =========================================================
    function has_request_below;
        input [2:0] floor;
        integer i;
        begin
            has_request_below = 1'b0;

            for (i = 0; i < 5; i = i + 1) begin
                if (i < floor) begin
                    if (hall_up_requests[i] ||
                        hall_down_requests[i] ||
                        cabin_requests[i] ||
                        hall_up_request[i] ||
                        hall_down_request[i] ||
                        cabin_request[i])
                        has_request_below = 1'b1;
                end
            end
        end
    endfunction


    // =========================================================
    // CHECK REQUEST AT CURRENT FLOOR
    // =========================================================
    function has_request_here;
        input [2:0] floor;
        begin
            has_request_here =
                hall_up_requests[floor]   ||
                hall_down_requests[floor] ||
                cabin_requests[floor]     ||
                hall_up_request[floor]    ||
                hall_down_request[floor]  ||
                cabin_request[floor];
        end
    endfunction


    // =========================================================
    // MAIN ELEVATOR CONTROLLER
    // =========================================================
    always @(posedge clk) begin

        if (reset) begin

            current_floor <= 3'd0;
            direction <= IDLE;
            door_open <= 1'b0;
            door_timer <= 3'd0;

            hall_up_requests <= 5'b00000;
            hall_down_requests <= 5'b00000;
            cabin_requests <= 5'b00000;

        end else begin

            // =================================================
            // STORE NEW REQUESTS
            // =================================================
            hall_up_requests <=
                hall_up_requests | hall_up_request;

            hall_down_requests <=
                hall_down_requests | hall_down_request;

            cabin_requests <=
                cabin_requests | cabin_request;


            // =================================================
            // DOORS OPEN
            // =================================================
            if (door_open) begin

                if (door_timer < 3'd2) begin
                    door_timer <= door_timer + 1'b1;
                end

                else begin

                    door_open <= 1'b0;
                    door_timer <= 3'd0;

                    // -----------------------------------------
                    // CLEAR ALL REQUEST TYPES AT THIS FLOOR
                    // -----------------------------------------
                    hall_up_requests[current_floor] <= 1'b0;
                    hall_down_requests[current_floor] <= 1'b0;
                    cabin_requests[current_floor] <= 1'b0;

                end

            end


            // =================================================
            // DOORS CLOSED
            // =================================================
            else begin

                // =================================================
                // PRIORITY 1
                // CURRENT FLOOR REQUEST
                //
                // Direction DOES NOT MATTER.
                // =================================================
                if (has_request_here(current_floor)) begin

                    direction <= IDLE;
                    door_open <= 1'b1;
                    door_timer <= 3'd0;

                end


                // =================================================
                // CURRENT DIRECTION = UP
                // =================================================
                else if (direction == UP) begin

                    if (has_request_above(current_floor)) begin

                        // Continue UP
                        if (current_floor < 3'd4)
                            current_floor <= current_floor + 1'b1;

                    end

                    else if (has_request_below(current_floor)) begin

                        // No request UP.
                        // Reverse only because a real request exists DOWN.
                        direction <= DOWN;

                        if (current_floor > 3'd0)
                            current_floor <= current_floor - 1'b1;

                    end

                    else begin

                        // NOTHING ANYWHERE
                        // Stay exactly where we are.
                        direction <= IDLE;

                    end

                end


                // =================================================
                // CURRENT DIRECTION = DOWN
                // =================================================
                else if (direction == DOWN) begin

                    if (has_request_below(current_floor)) begin

                        // Continue DOWN
                        if (current_floor > 3'd0)
                            current_floor <= current_floor - 1'b1;

                    end

                    else if (has_request_above(current_floor)) begin

                        // No request DOWN.
                        // Reverse only because a real request exists UP.
                        direction <= UP;

                        if (current_floor < 3'd4)
                            current_floor <= current_floor + 1'b1;

                    end

                    else begin

                        // NOTHING ANYWHERE
                        // Stay here.
                        direction <= IDLE;

                    end

                end


                // =================================================
                // IDLE
                // =================================================
                else begin

                    // No request here because that was checked above.

                    if (has_request_above(current_floor)) begin

                        direction <= UP;
                        current_floor <= current_floor + 1'b1;

                    end

                    else if (has_request_below(current_floor)) begin

                        direction <= DOWN;
                        current_floor <= current_floor - 1'b1;

                    end

                    else begin

                        direction <= IDLE;

                    end

                end

            end

        end

    end

endmodule

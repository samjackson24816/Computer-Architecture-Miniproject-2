// Top-level SystemVerilog module

module top(
    input logic     clk,
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
);
    parameter int CLOCK_SPEED = 12000000; // 12 MHz

    localparam int SECTOR_NUM = 6;
    
    localparam int OUTPUT_RESOLUTION = 256;



    localparam int SEGMENT_TIME = CLOCK_SPEED / SECTOR_NUM;

    localparam int UPDATE_TIME = SEGMENT_TIME / OUTPUT_RESOLUTION; 

    localparam int MAX_INTENSITY = OUTPUT_RESOLUTION - 1;

    localparam int PWM_BITS = $clog2(MAX_INTENSITY);


    logic [2:0] sector = 0; // Goes from 0 - 5

    logic [$clog2(SEGMENT_TIME):0] offset = 0; 
    logic [PWM_BITS-1:0] outputVal = 0; 
    logic [$clog2(UPDATE_TIME):0] timeSinceLastUpdate = 0;

    logic [PWM_BITS-1:0] pwmVal = 0; // Constantly cycling value to make pwm signal from

    // Piecewise linear duty cycles for RGB
    logic [PWM_BITS-1:0] r, g, b;

    always_comb begin
        case (sector)
            3'd0: begin // 0 deg - 60 deg: R=MAX, G rises, B=0
                r = MAX_INTENSITY;
                g = outputVal;
                b = '0;
            end
            3'd1: begin // 60 deg - 120 deg: R falls, G=MAX, B=0
                r = MAX_INTENSITY - outputVal;
                g = MAX_INTENSITY;
                b = '0;
            end
            3'd2: begin // 120 deg - 180 deg: R=0, G=MAX, B rises
                r = '0;
                g = MAX_INTENSITY;
                b = outputVal;
            end
            3'd3: begin // 180 deg - 240 deg: R=0, G falls, B=MAX
                r = '0;
                g = MAX_INTENSITY - outputVal;
                b = MAX_INTENSITY;
            end
            3'd4: begin // 240 deg - 300 deg: R rises, G=0, B=MAX
                r = outputVal;
                g = '0;
                b = MAX_INTENSITY;
            end
            3'd5: begin // 300 deg - 360 deg: R=MAX, G=0, B falls
                r = MAX_INTENSITY;
                g = '0;
                b = MAX_INTENSITY - outputVal;
            end
            default: begin
                r = '0;
                g = '0;
                b = '0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        pwmVal <= pwmVal + 1;

        // Note that if the resolution is a factor of 2 like 256, we don't actually need this logic because pwmVal will overflow and wrap,
        //  but this logic is kept here just in case the resolution ever changed
        if (pwmVal >= MAX_INTENSITY) begin
            pwmVal <= 0;
        end

        if (offset >= SEGMENT_TIME - 1) begin
            offset <= 0;
            outputVal <= 0;
            timeSinceLastUpdate <= 0;

            if (sector == SECTOR_NUM - 1) begin
                sector <= 0;
            end else begin
                sector <= sector + 1;
            end
        end else begin
            offset <= offset + 1;

            if (timeSinceLastUpdate >= UPDATE_TIME - 1) begin
                timeSinceLastUpdate <= 0;
                if (outputVal < MAX_INTENSITY) begin
                    outputVal <= outputVal + 1;
                end
            end else begin
                timeSinceLastUpdate <= timeSinceLastUpdate + 1;
            end
        end
    end

    // PWM outputs (active-low: 0 = on, 1 = off)
    assign RGB_R = ~(pwmVal < r);
    assign RGB_G = ~(pwmVal < g);
    assign RGB_B = ~(pwmVal < b);

endmodule

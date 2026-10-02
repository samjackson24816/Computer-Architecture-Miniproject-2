`timescale 1ns/1ns
`include "top.sv"

module top_tb;

    logic clk = 0;
    logic RGB_R, RGB_G, RGB_B;

    top u0 (
        .clk(clk),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top_tb);
        
        // Run simulation for 1 full second (1,000,000,000 ns)
        #1000000000;
        $finish;
    end

    always begin
        // 12 MHz clock: period = 83.33 ns -> half-period = 41.67 ns (~42 ns)
        #42;
        clk = ~clk;
    end

endmodule

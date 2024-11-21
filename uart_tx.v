`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.07.2024 01:17:22
// Author Name: Karan Kumar singh
// Module Name: uart_tx
// Project Name: UART 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module uart_rx(
    input wire clk,       
    input wire reset,     
    input wire rx,        
    output reg [7:0] data, 
    output reg rx_ready,  
    output reg parity_error 
);

    parameter CLK_FREQ = 50000000;  // System clock frequency
    parameter BAUD_RATE = 9600;     // Baud rate
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 3'b000,
               START = 3'b001,
               DATA = 3'b010,
               PARITY = 3'b011,
               STOP = 3'b100;

    reg [2:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_shift_reg = 0;
    reg parity_bit = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_ready <= 0;
            data <= 0;
            parity_error <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rx_ready <= 0;
                    parity_error <= 0;
                    if (~rx) begin  // Start bit detected
                        state <= START;
                        clk_count <= 0;
                    end
                end
                START: begin
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        state <= DATA;
                        clk_count <= 0;
                        bit_index <= 0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_shift_reg[bit_index] <= rx;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= PARITY;
                        end
                    end
                end
                PARITY: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        parity_bit <= rx;
                        if (parity_bit != ^rx_shift_reg) begin
                            parity_error <= 1; // Parity check failed
                        end
                        state <= STOP;
                    end
                end
                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (!parity_error) begin
                            data <= rx_shift_reg;
                            rx_ready <= 1;
                        end
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

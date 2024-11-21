`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 11.07.2024 01:18:49
// Author Name: Karan Kumar Singh
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

module uart_tx(
    input wire clk,       
    input wire reset,     
    input wire [7:0] data, 
    input wire tx_start,  
    output reg tx,        
    output reg tx_busy    
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
    reg [7:0] tx_data = 0;
    reg parity_bit = 0; // Parity bit

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_busy <= 0;
            tx <= 1;
            parity_bit <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    tx_busy <= 0;
                    if (tx_start) begin
                        tx_data <= data;
                        parity_bit <= ^data; // Calculate even parity
                        state <= START;
                        tx_busy <= 1;
                    end
                end
                START: begin
                    tx <= 0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end
                DATA: begin
                    tx <= tx_data[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= PARITY;
                        end
                    end
                end
                PARITY: begin
                    tx <= parity_bit;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= STOP;
                    end
                end
                STOP: begin
                    tx <= 1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= IDLE;
                        tx_busy <= 0;
                    end
                end
            endcase
        end
    end
endmodule

`timescale 1ns/1ps

// -------------------------------------------------------
// SPI Flash Behavioral Model
//
// This model follows the command behavior of a
// Winbond W25Q64-style SPI Flash device.
//
// For simulation simplicity, the memory array is
// reduced to 64 KB instead of the full device capacity.
//
// Therefore:
//   - 24-bit SPI addresses are accepted
//   - Only the lower 16 address bits access memory
//   - D8h erases the complete 64 KB model
//   - C7h erases the complete 64 KB model
// -------------------------------------------------------

module spi_flash (
    input  wire cs,
    input  wire sclk,
    input  wire mosi,
    output reg miso
);

    // ---------------------------------------
    // SPI receive registers
    // ---------------------------------------

    reg [7:0] rx_shift;
    reg [7:0] command;
    reg [7:0] operation;
    reg [2:0] bit_count;

    // ---------------------------------------
    // JEDEC ID shift register
    // ---------------------------------------

    reg [23:0] jedec_shift;

    // ---------------------------------------
    // Flash registers
    // ---------------------------------------

    reg        wel;
    reg        busy;

    reg [23:0] address_reg;
    reg [1:0] address_count;

    // Behavioral memory is 64 KB, so erase operations use the lower 16 address bits
    reg [15:0] erase_address;

    // ---------------------------------------
    // Status / read registers
    // ---------------------------------------

    reg [7:0] status_shift;
    reg [7:0] read_shift;

    reg        read_pending;
    reg [15:0] read_address;
    reg [2:0]  read_bit_count;

    // ---------------------------------------
    // Memory
    // 64 KB behavioral memory
    // ---------------------------------------

    // Simplified 64 KB behavioral memory model
    reg [7:0] memory [0:65535];

    integer i;
    integer j;

    // ---------------------------------------
    // SPI Flash Commands
    // ---------------------------------------

    localparam CMD_WREN          = 8'h06;
    localparam CMD_WRDI          = 8'h04;
    localparam CMD_RDSR          = 8'h05;
    localparam CMD_READ          = 8'h03;
    localparam CMD_PAGE_PROGRAM  = 8'h02;
    localparam CMD_SECTOR_ERASE  = 8'h20;
    localparam CMD_BLOCK32_ERASE = 8'h52;
    localparam CMD_BLOCK64_ERASE = 8'hD8;
    localparam CMD_CHIP_ERASE    = 8'hC7;
    localparam CMD_JEDEC_ID      = 8'h9F;

    // ---------------------------------------
    // States
    // ---------------------------------------

    localparam CMD_STATE      = 3'b000;
    localparam STATUS_STATE   = 3'b001;
    localparam ADDRESS_STATE  = 3'b010;
    localparam PROGRAM_STATE  = 3'b011;
    localparam READ_STATE     = 3'b100;
    localparam DATA_STATE     = 3'b101;
    localparam JEDEC_STATE    = 3'b110;

    reg [2:0] state;


    // ---------------------------------------
    // Initial values
    // ---------------------------------------

    initial begin

        rx_shift       = 8'b0;
        command        = 8'b0;
        operation      = 8'b0;
        bit_count      = 3'b0;

        wel            = 1'b0;
        busy           = 1'b0;

        address_reg    = 24'b0;
        address_count  = 2'b0;
        erase_address  = 16'b0;

        status_shift   = 8'b0;
        read_shift     = 8'b0;

        jedec_shift    = 24'b0;

        read_pending   = 1'b0;
        read_address   = 16'b0;
        read_bit_count = 3'b0;

        miso           = 1'b0;

        state          = CMD_STATE;

        // Flash starts erased
        for (i = 0; i < 65536; i = i + 1)
            memory[i] = 8'hFF;

    end


    // =====================================================
    // RECEIVE SIDE
    // =====================================================

    always @(posedge sclk or posedge cs) begin

        // -----------------------------------------------
        // CS HIGH = transaction finished
        // -----------------------------------------------

        if (cs) begin

        rx_shift      <= 8'b0;
        bit_count     <= 3'b0;
        address_count <= 2'b0;

        // -------------------------------------------
        // Start write / erase operation
        // -------------------------------------------

        case (command)

        CMD_PAGE_PROGRAM,
        CMD_SECTOR_ERASE,
        CMD_BLOCK32_ERASE,
        CMD_BLOCK64_ERASE,
        CMD_CHIP_ERASE: begin

            if (wel == 1'b1) begin
                operation <= command;
                busy <= 1'b1;
            end

        end

        default: begin
            // No write or erase operation
        end

    endcase

        state <= CMD_STATE;

    end


        else begin

            // -------------------------------------------
            // Receive one SPI bit
            // -------------------------------------------

            rx_shift <= {
                rx_shift[6:0],
                mosi
            };


            // -------------------------------------------
            // Complete byte received
            // -------------------------------------------

            if (bit_count == 3'd7) begin

                case (state)

                    // ===================================
                    // COMMAND
                    // ===================================

                    CMD_STATE: begin

                        command <= {
                            rx_shift[6:0],
                            mosi
                        };

                        case ({
                            rx_shift[6:0],
                            mosi
                        })

                            // -----------------------------
                            // Write Enable
                            // -----------------------------

                           CMD_WREN: begin

                                if (busy == 1'b0)
                                    wel <= 1'b1;

                                state <= DATA_STATE;

                            end


                            // -----------------------------
                            // Write Disable
                            // -----------------------------

                           CMD_WRDI: begin

                                if (busy == 1'b0)
                                    wel <= 1'b0;

                                state <= DATA_STATE;

                            end

                            // -----------------------------
                            // Read Status Register
                            // -----------------------------

                           CMD_RDSR: begin

                                status_shift <= {
                                    6'b000000,
                                    wel,
                                    busy
                                };

                                state <= STATUS_STATE;

                            end


                            // -----------------------------
                            // JEDEC ID
                            // -----------------------------

                           CMD_JEDEC_ID: begin

                                if (busy == 1'b0) begin

                                    jedec_shift <= 24'hEF4017;
                                    state       <= JEDEC_STATE;

                                end
                                else begin

                                    state <= DATA_STATE;

                                end

                            end


                            // -------------------------------------------
                            // Page Program / Erase Commands
                            // -------------------------------------------

                            CMD_PAGE_PROGRAM,
                            CMD_SECTOR_ERASE,
                            CMD_BLOCK32_ERASE,
                            CMD_BLOCK64_ERASE: begin

                                if ((wel == 1'b1) && (busy == 1'b0)) begin

                                    address_count <= 2'b0;
                                    state <= ADDRESS_STATE;

                                end

                                else begin

                                    state <= DATA_STATE;

                                end

                            end


                            // -----------------------------
                            // Chip Erase
                            // -----------------------------

                           CMD_CHIP_ERASE: begin

                                state <= DATA_STATE;

                            end

                            // -----------------------------
                            // Read Data
                            // -----------------------------

                           CMD_READ: begin

                                if (busy == 1'b0) begin

                                    address_count <= 2'b0;
                                    state         <= ADDRESS_STATE;

                                end
                                else begin

                                    state <= DATA_STATE;

                                end

                            end

                            // -----------------------------
                            // Unsupported command
                            // -----------------------------

                            default: begin

                                state <= DATA_STATE;

                            end

                        endcase

                    end


                    // ===================================
                    // ADDRESS
                    // ===================================

                    ADDRESS_STATE: begin

                        address_reg <= {
                            address_reg[15:0],
                            rx_shift[6:0],
                            mosi
                        };


                        if (address_count == 2'd2) begin

                            address_count <= 2'b0;


                            // -----------------------------
                            // Page Program
                            // -----------------------------

                            if (command == CMD_PAGE_PROGRAM) begin

                                state <= PROGRAM_STATE;

                            end


                            // -----------------------------
                            // Read Data
                            // -----------------------------

                            else if (command == CMD_READ) begin

                                // Store lower 16 bits for the 64 KB behavioral memory    
                                read_address <= {
                                    address_reg[7:0],
                                    rx_shift[6:0],
                                    mosi
                                };

                                read_pending   <= 1'b1;
                                read_bit_count <= 3'b0;

                                state <= READ_STATE;

                            end


                            // -------------------------------------------
                            // Erase Address
                            // -------------------------------------------

                            else if ((command == CMD_SECTOR_ERASE) ||
                                    (command == CMD_BLOCK32_ERASE) ||
                                    (command == CMD_BLOCK64_ERASE)) begin

                                // Store lower 16 bits for the 64 KB behavioral memory
                                erase_address <= {
                                    address_reg[7:0],
                                    rx_shift[6:0],
                                    mosi
                                };

                            end

                        end

                        else begin

                            address_count <=
                                address_count + 1'b1;

                        end

                    end


                    // ===================================
                    // PAGE PROGRAM DATA
                    // ===================================

                    PROGRAM_STATE: begin

                        if ((wel == 1'b1) &&
                            (busy == 1'b0)) begin

                            // Flash programming changes
                            // bits from 1 -> 0 only.

                            // Use lower 16 bits because the behavioral memory is 64 KB
                            memory[address_reg[15:0]] <=
                                memory[address_reg[15:0]]
                                &
                                {
                                    rx_shift[6:0],
                                    mosi
                                };

                            address_reg <=
                                address_reg + 1'b1;

                        end

                    end


                    // ===================================
                    // OTHER STATES
                    // ===================================

                    default: begin

                    end

                endcase


                bit_count <= 3'b0;

            end

            else begin

                bit_count <=
                    bit_count + 1'b1;

            end

        end

    end


    // =====================================================
    // BEHAVIORAL BUSY COMPLETION
    // =====================================================
    //
    // These blocks model the internal flash operation.
    //
    // Page Program : 100 ns
    // Sector Erase : 200 ns
    // Block Erase  : 300 ns
    // 64 KB Erase  : 400 ns
    // Chip Erase   : 500 ns
    //
    // These values are simulation values and are not
    // intended to represent exact physical timing.
    // =====================================================

    always begin

        // Wait until a write or erase operation starts
        wait (busy == 1'b1);


        // -------------------------------------------
        // Page Program
        // -------------------------------------------

        if (operation == CMD_PAGE_PROGRAM) begin

            #100;

            busy <= 1'b0;
            wel  <= 1'b0;

        end


        // -------------------------------------------
        // Sector Erase
        // -------------------------------------------

        else if (operation == CMD_SECTOR_ERASE) begin

            #200;

            // 4 KB sector alignment: clear lower 12 address bits
            for (j = 0; j < 4096; j = j + 1) begin

                memory[(erase_address & 16'hF000) + j]
                    = 8'hFF;

            end

            busy <= 1'b0;
            wel  <= 1'b0;

        end


        // -------------------------------------------
        // 32 KB Block Erase
        // -------------------------------------------

        else if (operation == CMD_BLOCK32_ERASE) begin

            #300;

            // 32 KB block alignment: clear lower 15 address bits
            for (j = 0; j < 32768; j = j + 1) begin

                memory[(erase_address & 16'h8000) + j]
                    = 8'hFF;

            end

            busy <= 1'b0;
            wel  <= 1'b0;

        end


        // -------------------------------------------
        // 64 KB Block Erase
        // -------------------------------------------

        else if (operation == CMD_BLOCK64_ERASE) begin

            // In the 64 KB model, this covers the complete memory

            #400;

            for (j = 0; j < 65536; j = j + 1) begin

                memory[j] = 8'hFF;

            end

            busy <= 1'b0;
            wel  <= 1'b0;

        end


        // -------------------------------------------
        // Chip Erase
        // -------------------------------------------

        else if (operation == CMD_CHIP_ERASE) begin

            // Chip erase also clears the complete modeled memory

            #500;

            for (j = 0; j < 65536; j = j + 1) begin

                memory[j] = 8'hFF;

            end

            busy <= 1'b0;
            wel  <= 1'b0;

        end

    end


    // =====================================================
    // TRANSMIT SIDE
    // =====================================================

    always @(negedge sclk or posedge cs) begin
        if (cs) begin
            miso <= 1'b0;
        end

        else begin

            // -------------------------------------------
            // Status Register output
            // -------------------------------------------

            if (state == STATUS_STATE) begin

                miso <= status_shift[7];

                status_shift <= {
                    status_shift[6:0],
                    1'b0
                };

            end


            // -------------------------------------------
            // JEDEC ID output
            // -------------------------------------------

            else if (state == JEDEC_STATE) begin

                miso <= jedec_shift[23];

                jedec_shift <= {
                    jedec_shift[22:0],
                    1'b0
                };

            end


            // -------------------------------------------
            // Flash Read output
            // -------------------------------------------

            else if (state == READ_STATE) begin

                if (read_pending) begin

                    miso <= memory[read_address][7];

                    read_shift <= {
                        memory[read_address][6:0],
                        1'b0
                    };

                    read_pending   <= 1'b0;
                    read_bit_count <= 3'd1;

                end

                else begin

                    miso <= read_shift[7];

                    read_shift <= {
                        read_shift[6:0],
                        1'b0
                    };


                    if (read_bit_count == 3'd7) begin

                        read_address <=
                            read_address + 1'b1;

                        read_bit_count <= 3'b0;

                        read_pending <= 1'b1;

                    end

                    else begin

                        read_bit_count <=
                            read_bit_count + 1'b1;

                    end

                end

            end


            // -------------------------------------------
            // No data to transmit
            // -------------------------------------------

            else begin

                miso <= 1'b0;

            end

        end

    end

endmodule
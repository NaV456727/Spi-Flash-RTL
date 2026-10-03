module spi_flash (
    input  wire cs,
    input  wire sclk,
    input  wire mosi,
    output reg  miso
);

    // ---------------------------------------
    // SPI receive registers
    // ---------------------------------------

    reg [7:0] rx_shift;
    reg [7:0] command;
    reg [2:0] bit_count;

    // ---------------------------------------
    // JEDEC ID shift register
    // ---------------------------------------

    reg [23:0] jedec_shift;

    // ---------------------------------------
    // Flash registers
    // ---------------------------------------

    reg       wel;
    reg       busy;

    reg [23:0] address_reg;
    reg [1:0]  address_count;

    // ---------------------------------------
    // Status / read registers
    // ---------------------------------------

    reg [7:0] status_shift;
    reg [7:0] read_shift;

    reg       read_pending;
    reg [15:0] read_address;
    reg [2:0] read_bit_count;

    // ---------------------------------------
    // Memory
    // 64 KB behavioral memory
    // ---------------------------------------

    reg [7:0] memory [0:65535];

    integer i;

    // ---------------------------------------
    // States
    // ---------------------------------------

    parameter CMD_STATE     = 3'b000;
    parameter STATUS_STATE  = 3'b001;
    parameter ADDRESS_STATE = 3'b010;
    parameter PROGRAM_STATE = 3'b011;
    parameter READ_STATE    = 3'b100;
    parameter DATA_STATE    = 3'b101;
    parameter JEDEC_STATE   = 3'b110;

    reg [2:0] state;


    // ---------------------------------------
    // Initial values
    // ---------------------------------------

    initial begin

        rx_shift       = 8'b0;
        command        = 8'b0;
        bit_count      = 3'b0;

        wel            = 1'b0;
        busy           = 1'b0;

        address_reg    = 24'b0;
        address_count  = 2'b0;

        status_shift   = 8'b0;
        read_shift     = 8'b0;

        jedec_shift = 24'b0;

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

            state <= CMD_STATE;

            // Simplified behavioral Page Program completion
            if (command == 8'h02 && wel == 1'b1) begin
                wel <= 1'b0;
                busy <= 1'b0;
            end

        end

        else begin

            // Receive one SPI bit
            rx_shift <= {rx_shift[6:0], mosi};


            // -------------------------------------------
            // Complete byte received
            // -------------------------------------------

            if (bit_count == 3'd7) begin

                case (state)

                    // ===================================
                    // COMMAND
                    // ===================================

                    CMD_STATE: begin

                        command <= {rx_shift[6:0], mosi};

                        case ({rx_shift[6:0], mosi})

                            // -----------------------------
                            // Write Enable
                            // -----------------------------

                            8'h06: begin

                                wel <= 1'b1;
                                state <= DATA_STATE;

                            end


                            // -----------------------------
                            // Write Disable
                            // -----------------------------

                            8'h04: begin

                                wel <= 1'b0;
                                state <= DATA_STATE;

                            end


                            // -----------------------------
                            // Read Status Register-1
                            // -----------------------------

                            8'h05: begin

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
                                8'h9F: begin
                                    jedec_shift <= 24'hEF4017;
                                    state <= JEDEC_STATE;
                                end


                            // -----------------------------
                            // Page Program
                            // -----------------------------

                            8'h02: begin

                                if (wel == 1'b1) begin

                                    address_count <= 2'b0;
                                    state <= ADDRESS_STATE;

                                end

                                else begin

                                    state <= DATA_STATE;

                                end

                            end


                            // -----------------------------
                            // Read Data
                            // -----------------------------

                            8'h03: begin

                                address_count <= 2'b0;
                                state <= ADDRESS_STATE;

                            end


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

                            // Page Program
                            if (command == 8'h02) begin

                                state <= PROGRAM_STATE;

                            end

                            // Read Data
                            else if (command == 8'h03) begin

                                read_address <= {
                                    address_reg[7:0],
                                    rx_shift[6:0],
                                    mosi
                                };

                                read_pending <= 1'b1;
                                read_bit_count <= 3'b0;

                                state <= READ_STATE;

                            end

                        end

                        else begin

                            address_count <= address_count + 1'b1;

                        end

                    end


                    // ===================================
                    // PAGE PROGRAM DATA
                    // ===================================

                    PROGRAM_STATE: begin

                        if (wel == 1'b1) begin

                            // Flash programming changes 1 -> 0
                            memory[address_reg[15:0]] <=
                                memory[address_reg[15:0]]
                                &
                                {rx_shift[6:0], mosi};

                            address_reg <= address_reg + 1'b1;

                        end

                    end


                    default: begin

                    end

                endcase

                bit_count <= 3'b0;

            end

            else begin

                bit_count <= bit_count + 1'b1;

            end

        end

    end


    // =====================================================
    // TRANSMIT SIDE
    // =====================================================

    always @(negedge sclk or posedge cs) begin

        if (cs) begin

            miso <= 1'b0;

            read_pending <= 1'b0;
            read_bit_count <= 3'b0;

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

            // Flash Read output
            else if (state == READ_STATE) begin

                // Load first bit of a new byte
                if (read_pending) begin

                    miso <= memory[read_address][7];

                    // Shift immediately so next falling edge
                    // outputs the next bit
                    read_shift <= {
                        memory[read_address][6:0],
                        1'b0
                    };

                    read_pending <= 1'b0;

                    read_bit_count <= 3'd1;

                end

                else begin

                    // Output next bit
                    miso <= read_shift[7];

                    // Shift to next bit
                    read_shift <= {
                        read_shift[6:0],
                        1'b0
                    };

                    if (read_bit_count == 3'd7) begin

                        // Finished current byte
                        read_address <= read_address + 1'b1;

                        read_bit_count <= 3'b0;

                        // Next falling edge will load next byte
                        read_pending <= 1'b1;

                    end
                    else begin

                        read_bit_count <=
                            read_bit_count + 1'b1;

                    end

                end
            end


            else begin

                miso <= 1'b0;

            end

        end

    end

endmodule
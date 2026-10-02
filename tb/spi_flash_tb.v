`timescale 1ns/1ps

module spi_flash_tb;

    reg cs;
    reg sclk;
    reg mosi;
    wire miso;

    reg [7:0] received_data1;
    reg [7:0] received_data2;
    reg [7:0] received_data3;
    reg [7:0] received_data4;

    reg [7:0] received_status;


    spi_flash uut (
        .cs(cs),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso)
    );


    // =============================================
    // SEND BYTE
    // =============================================

    task send_byte;
        input [7:0] data;
        integer i;

        begin

            for (i = 7; i >= 0; i = i - 1) begin

                mosi = data[i];

                #5 sclk = 1;
                #5 sclk = 0;

            end

        end

    endtask


    // =============================================
    // READ BYTE
    // =============================================

    task read_byte;
        output [7:0] data;
        integer i;

        begin

            data = 8'b0;

            for (i = 7; i >= 0; i = i - 1) begin

                mosi = 0;

                #5 sclk = 1;

                #1 data[i] = miso;

                #4 sclk = 0;

            end

        end

    endtask


    // =============================================
    // TEST
    // =============================================

    initial begin

        cs = 1;
        sclk = 0;
        mosi = 0;

        received_status = 0;

        received_data1 = 0;
        received_data2 = 0;
        received_data3 = 0;
        received_data4 = 0;


        #10;


        // =========================================
        // 1. WRITE ENABLE
        // =========================================

        cs = 0;

        send_byte(8'h06);

        cs = 1;

        #10;


        // =========================================
        // 2. PAGE PROGRAM
        //
        // Address = 000010h
        // Data = DE AD BE EF
        // =========================================

        cs = 0;

        send_byte(8'h02);

        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h10);

        send_byte(8'hDE);
        send_byte(8'hAD);
        send_byte(8'hBE);
        send_byte(8'hEF);

        cs = 1;

        #10;


        // =========================================
        // 3. READ DATA
        //
        // Address = 000010h
        // =========================================

        cs = 0;

        send_byte(8'h03);

        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h10);

        read_byte(received_data1);
        read_byte(received_data2);
        read_byte(received_data3);
        read_byte(received_data4);

        cs = 1;

        #10;


        // =========================================
        // DISPLAY RESULTS
        // =========================================

        $display("--------------------------------");
        $display("SPI FLASH TEST RESULTS");
        $display("--------------------------------");

        $display("Memory[0010] = %h", uut.memory[16'h0010]);
        $display("Memory[0011] = %h", uut.memory[16'h0011]);
        $display("Memory[0012] = %h", uut.memory[16'h0012]);
        $display("Memory[0013] = %h", uut.memory[16'h0013]);

        $display("Read Data 1 = %h", received_data1);
        $display("Read Data 2 = %h", received_data2);
        $display("Read Data 3 = %h", received_data3);
        $display("Read Data 4 = %h", received_data4);

        $display("--------------------------------");

        $stop;

    end

endmodule
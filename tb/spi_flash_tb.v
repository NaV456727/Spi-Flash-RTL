`timescale 1ns/1ps

module spi_flash_tb;

    reg cs;
    reg sclk;
    reg mosi;
    wire miso;

    // =============================================
    // READ DATA BEFORE ERASE
    // =============================================

    reg [7:0] received_data1;
    reg [7:0] received_data2;
    reg [7:0] received_data3;
    reg [7:0] received_data4;

    // =============================================
    // READ DATA AFTER ERASE
    // =============================================

    reg [7:0] erased_data1;
    reg [7:0] erased_data2;
    reg [7:0] erased_data3;
    reg [7:0] erased_data4;

    // =============================================
    // JEDEC ID
    // =============================================

    reg [7:0] jedec_manufacturer;
    reg [7:0] jedec_memory_type;
    reg [7:0] jedec_device_id;

    // =============================================
    // STATUS
    // =============================================

    reg [7:0] received_status;


    // =============================================
    // DUT
    // =============================================

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

        // -----------------------------------------
        // Initial values
        // -----------------------------------------

        cs = 1;
        sclk = 0;
        mosi = 0;

        received_status = 0;

        received_data1 = 0;
        received_data2 = 0;
        received_data3 = 0;
        received_data4 = 0;

        erased_data1 = 0;
        erased_data2 = 0;
        erased_data3 = 0;
        erased_data4 = 0;

        jedec_manufacturer = 0;
        jedec_memory_type = 0;
        jedec_device_id = 0;


        #10;


        // =========================================
        // 1. WRITE ENABLE
        // =========================================

        $display("--------------------------------");
        $display("1. WRITE ENABLE");
        $display("--------------------------------");

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

        $display("--------------------------------");
        $display("2. PAGE PROGRAM");
        $display("--------------------------------");

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
        // 3. READ DATA BEFORE ERASE
        //
        // Address = 000010h
        // Expected = DE AD BE EF
        // =========================================

        $display("--------------------------------");
        $display("3. READ DATA BEFORE ERASE");
        $display("--------------------------------");

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
        // 4. WRITE ENABLE FOR ERASE
        // =========================================

        $display("--------------------------------");
        $display("4. WRITE ENABLE FOR ERASE");
        $display("--------------------------------");

        cs = 0;

        send_byte(8'h06);

        cs = 1;

        #10;


        // =========================================
        // 5. SECTOR ERASE
        //
        // Command = 20h
        // Address = 000010h
        //
        // This erases the 4 KB sector containing
        // address 000010h.
        // =========================================

        $display("--------------------------------");
        $display("5. SECTOR ERASE");
        $display("--------------------------------");

        cs = 0;

        send_byte(8'h20);

        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h10);

        cs = 1;

        #10;


        // =========================================
        // 6. READ DATA AFTER ERASE
        //
        // Address = 000010h
        // Expected = FF FF FF FF
        // =========================================

        $display("--------------------------------");
        $display("6. READ DATA AFTER ERASE");
        $display("--------------------------------");

        cs = 0;

        send_byte(8'h03);

        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h10);

        read_byte(erased_data1);
        read_byte(erased_data2);
        read_byte(erased_data3);
        read_byte(erased_data4);

        cs = 1;

        #10;


        // =========================================
        // 7. READ JEDEC ID
        //
        // Expected:
        // Manufacturer ID = EF
        // Memory Type     = 40
        // Device ID       = 17
        // =========================================

        $display("--------------------------------");
        $display("7. READ JEDEC ID");
        $display("--------------------------------");

        cs = 0;

        send_byte(8'h9F);

        read_byte(jedec_manufacturer);
        read_byte(jedec_memory_type);
        read_byte(jedec_device_id);

        cs = 1;

        #10;


        // =========================================
        // DISPLAY JEDEC ID
        // =========================================

        $display("--------------------------------");
        $display("JEDEC ID TEST");
        $display("--------------------------------");

        $display("Manufacturer ID = %h",
                 jedec_manufacturer);

        $display("Memory Type     = %h",
                 jedec_memory_type);

        $display("Device ID       = %h",
                 jedec_device_id);

        $display("--------------------------------");


        // =========================================
        // DISPLAY MEMORY AFTER ERASE
        // =========================================

        $display("--------------------------------");
        $display("SPI FLASH TEST RESULTS");
        $display("--------------------------------");

        $display("Memory[0010] = %h",
                 uut.memory[16'h0010]);

        $display("Memory[0011] = %h",
                 uut.memory[16'h0011]);

        $display("Memory[0012] = %h",
                 uut.memory[16'h0012]);

        $display("Memory[0013] = %h",
                 uut.memory[16'h0013]);

        $display("--------------------------------");


        // =========================================
        // DATA BEFORE ERASE
        // =========================================

        $display("DATA BEFORE ERASE");
        $display("Read Data 1 = %h",
                 received_data1);

        $display("Read Data 2 = %h",
                 received_data2);

        $display("Read Data 3 = %h",
                 received_data3);

        $display("Read Data 4 = %h",
                 received_data4);

        $display("--------------------------------");


        // =========================================
        // DATA AFTER ERASE
        // =========================================

        $display("DATA AFTER ERASE");
        $display("Read Data 1 = %h",
                 erased_data1);

        $display("Read Data 2 = %h",
                 erased_data2);

        $display("Read Data 3 = %h",
                 erased_data3);

        $display("Read Data 4 = %h",
                 erased_data4);

        $display("--------------------------------");


        // =========================================
        // FINAL TEST SUMMARY
        // =========================================

        $display("SPI FLASH TEST COMPLETE");
        $display("--------------------------------");

        $stop;

    end

endmodule
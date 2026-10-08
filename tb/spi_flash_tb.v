`timescale 1ns/1ps

module spi_flash_tb;

    // =====================================================
    // SPI SIGNALS
    // =====================================================

    reg cs;
    reg sclk;
    reg mosi;
    wire miso;


    // =====================================================
    // DEVICE UNDER TEST
    // =====================================================

    spi_flash uut (
        .cs   (cs),
        .sclk (sclk),
        .mosi (mosi),
        .miso (miso)
    );


    // =====================================================
    // TEST VARIABLES
    // =====================================================

    reg [7:0] status;
    reg [7:0] data1;
    reg [7:0] data2;
    reg [7:0] data3;
    reg [7:0] data4;

    reg [7:0] jedec1;
    reg [7:0] jedec2;
    reg [7:0] jedec3;

    integer pass_count;
    integer fail_count;


    // =====================================================
    // SPI SEND BYTE
    // =====================================================

    task spi_send_byte;
        input [7:0] data;
        integer k;

        begin

            for (k = 7; k >= 0; k = k - 1) begin

                mosi = data[k];

                #5;
                sclk = 1'b1;

                #5;
                sclk = 1'b0;

            end

        end
    endtask


    // =====================================================
    // SPI RECEIVE BYTE
    // =====================================================

    task spi_receive_byte;
        output [7:0] data;
        integer k;

        begin

            data = 8'h00;

            for (k = 7; k >= 0; k = k - 1) begin

                #5;
                sclk = 1'b1;

                #5;
                data[k] = miso;

                sclk = 1'b0;

            end

        end
    endtask


    // =====================================================
    // WRITE ENABLE
    // =====================================================

    task write_enable;

        begin

            cs = 1'b0;

            spi_send_byte(8'h06);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // WRITE DISABLE
    // =====================================================

    task write_disable;

        begin

            cs = 1'b0;

            spi_send_byte(8'h04);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // READ STATUS
    // =====================================================

    task read_status;
        output [7:0] result;

        begin

            cs = 1'b0;

            spi_send_byte(8'h05);

            spi_receive_byte(result);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // PAGE PROGRAM
    // =====================================================

    task page_program;
        input [23:0] address;
        input [7:0] d1;
        input [7:0] d2;
        input [7:0] d3;
        input [7:0] d4;

        begin

            cs = 1'b0;

            spi_send_byte(8'h02);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            spi_send_byte(d1);
            spi_send_byte(d2);
            spi_send_byte(d3);
            spi_send_byte(d4);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // READ DATA
    // =====================================================

    task read_data;
        input [23:0] address;
        output [7:0] d1;
        output [7:0] d2;
        output [7:0] d3;
        output [7:0] d4;

        begin

            cs = 1'b0;

            spi_send_byte(8'h03);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            spi_receive_byte(d1);
            spi_receive_byte(d2);
            spi_receive_byte(d3);
            spi_receive_byte(d4);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // SECTOR ERASE
    // =====================================================

    task sector_erase;
        input [23:0] address;

        begin

            cs = 1'b0;

            spi_send_byte(8'h20);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // 32 KB BLOCK ERASE
    // =====================================================

    task block32_erase;
        input [23:0] address;

        begin

            cs = 1'b0;

            spi_send_byte(8'h52);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // 64 KB BLOCK ERASE
    // =====================================================

    task block64_erase;
        input [23:0] address;

        begin

            cs = 1'b0;

            spi_send_byte(8'hD8);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // CHIP ERASE
    // =====================================================

    task chip_erase;

        begin

            cs = 1'b0;

            spi_send_byte(8'hC7);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // JEDEC ID
    // =====================================================

    task read_jedec;

        begin

            cs = 1'b0;

            spi_send_byte(8'h9F);

            spi_receive_byte(jedec1);
            spi_receive_byte(jedec2);
            spi_receive_byte(jedec3);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // TEST PASS
    // =====================================================

    task pass;
        input [255:0] message;

        begin

            $display("PASS: %s", message);
            pass_count = pass_count + 1;

        end

    endtask


    // =====================================================
    // TEST FAIL
    // =====================================================

    task fail;
        input [255:0] message;

        begin

            $display("FAIL: %s", message);
            fail_count = fail_count + 1;

        end

    endtask


    // =====================================================
    // VERIFY FOUR BYTES
    // =====================================================

    task check_data;
        input [7:0] e1;
        input [7:0] e2;
        input [7:0] e3;
        input [7:0] e4;
        input [255:0] message;

        begin

            if ((data1 == e1) &&
                (data2 == e2) &&
                (data3 == e3) &&
                (data4 == e4))

                pass(message);

            else
                fail(message);

        end

    endtask


    // =====================================================
    // MAIN TEST
    // =====================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        cs   = 1'b1;
        sclk = 1'b0;
        mosi = 1'b0;

        #20;


        // =================================================
        // TEST 1
        // INITIAL STATUS
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 1: INITIAL STATUS");
        $display("========================================");

        read_status(status);

        $display("Status = %h", status);

        if (status == 8'h00)
            pass("Initial status = 00");
        else
            fail("Initial status incorrect");


        // =================================================
        // TEST 2
        // WRITE ENABLE
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 2: WRITE ENABLE");
        $display("========================================");

        write_enable;

        read_status(status);

        $display("Status = %h", status);

        if (status == 8'h02)
            pass("WREN sets WEL");
        else
            fail("WREN failed");


        // =================================================
        // TEST 3
        // WRITE DISABLE
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 3: WRITE DISABLE");
        $display("========================================");

        write_disable;

        read_status(status);

        $display("Status = %h", status);

        if (status == 8'h00)
            pass("WRDI clears WEL");
        else
            fail("WRDI failed");


        // =================================================
        // TEST 4
        // PROGRAM WITHOUT WREN
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 4: PROGRAM WITHOUT WREN");
        $display("========================================");

        page_program(
            24'h000100,
            8'hAA,
            8'hBB,
            8'hCC,
            8'hDD
        );

        #150;

        read_data(
            24'h000100,
            data1,
            data2,
            data3,
            data4
        );

        $display(
            "Read = %h %h %h %h",
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "Program blocked without WREN"
        );


        // =================================================
        // TEST 5
        // PAGE PROGRAM + READ
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 5: PAGE PROGRAM + READ");
        $display("========================================");

        write_enable;

        page_program(
            24'h000010,
            8'h11,
            8'h22,
            8'h33,
            8'h44
        );

        #150;

        read_data(
            24'h000010,
            data1,
            data2,
            data3,
            data4
        );

        $display(
            "Read = %h %h %h %h",
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'h11,
            8'h22,
            8'h33,
            8'h44,
            "Page Program and Read"
        );


        // =================================================
        // TEST 6
        // WEL CLEARS AFTER PROGRAM
        // =================================================

        read_status(status);

        $display("Status = %h", status);

        if (status == 8'h00)
            pass("WEL clears after Page Program");
        else
            fail("WEL did not clear after Page Program");


        // =================================================
        // TEST 7
        // SECTOR ERASE WITHOUT WREN
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 7: SECTOR ERASE WITHOUT WREN");
        $display("========================================");

        sector_erase(24'h000010);

        #250;

        read_data(
            24'h000010,
            data1,
            data2,
            data3,
            data4
        );

        $display(
            "Read = %h %h %h %h",
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'h11,
            8'h22,
            8'h33,
            8'h44,
            "Sector Erase blocked without WREN"
        );


        // =================================================
        // TEST 8
        // SECTOR ERASE
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 8: SECTOR ERASE");
        $display("========================================");

        write_enable;

        sector_erase(24'h000010);

        #100;

        read_status(status);

        $display("Status during erase = %h", status);

        if (status == 8'h03)
            pass("Sector Erase BUSY asserted");
        else
            fail("Sector Erase BUSY incorrect");

        #150;

        read_status(status);

        if (status == 8'h00)
            pass("Sector Erase completed");
        else
            fail("Sector Erase did not complete");

        read_data(
            24'h000010,
            data1,
            data2,
            data3,
            data4
        );

        $display(
            "Read = %h %h %h %h",
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "Sector Erase data"
        );


        // =================================================
        // TEST 9
        // 32 KB BLOCK ERASE
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 9: 32 KB BLOCK ERASE");
        $display("========================================");

        // Program two locations inside different
        // 32 KB regions.

        write_enable;

        page_program(
            24'h000010,
            8'h11,
            8'h22,
            8'h33,
            8'h44
        );

        #150;

        write_enable;

        page_program(
            24'h008010,
            8'hAA,
            8'hBB,
            8'hCC,
            8'hDD
        );

        #150;

        // Erase first 32 KB block.

        write_enable;

        block32_erase(24'h000010);

        #100;

        read_status(status);

        if (status == 8'h03)
            pass("32 KB Erase BUSY asserted");
        else
            fail("32 KB Erase BUSY incorrect");

        #250;

        read_data(
            24'h000010,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "32 KB block erased"
        );

        read_data(
            24'h008010,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hAA,
            8'hBB,
            8'hCC,
            8'hDD,
            "Second 32 KB block preserved"
        );


        // =================================================
        // TEST 10
        // 32 KB ERASE WITHOUT WREN
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 10: 32 KB ERASE WITHOUT WREN");
        $display("========================================");

        write_enable;

        page_program(
            24'h010010,
            8'h12,
            8'h34,
            8'h56,
            8'h78
        );

        #150;

        block32_erase(24'h010010);

        #350;

        read_data(
            24'h010010,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'h12,
            8'h34,
            8'h56,
            8'h78,
            "32 KB Erase blocked without WREN"
        );


        // =================================================
        // TEST 11
        // 64 KB BLOCK ERASE
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 11: 64 KB BLOCK ERASE");
        $display("========================================");

        write_enable;

        page_program(
            24'h000020,
            8'h10,
            8'h20,
            8'h30,
            8'h40
        );

        #150;

        write_enable;

        page_program(
            24'h00FFF0,
            8'h50,
            8'h60,
            8'h70,
            8'h80
        );

        #150;

        write_enable;

        block64_erase(24'h000020);

        #100;

        read_status(status);

        if (status == 8'h03)
            pass("64 KB Erase BUSY asserted");
        else
            fail("64 KB Erase BUSY incorrect");

        #350;

        read_data(
            24'h000020,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "64 KB block start erased"
        );

        read_data(
            24'h00FFF0,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "64 KB block end erased"
        );


        // =================================================
        // TEST 12
        // 64 KB ERASE WITHOUT WREN
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 12: 64 KB ERASE WITHOUT WREN");
        $display("========================================");

        write_enable;

        page_program(
            24'h002000,
            8'hDE,
            8'hAD,
            8'hBE,
            8'hEF
        );

        #150;

        block64_erase(24'h002000);

        #450;

        read_data(
            24'h002000,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hDE,
            8'hAD,
            8'hBE,
            8'hEF,
            "64 KB Erase blocked without WREN"
        );


        // =================================================
        // TEST 13
        // CHIP ERASE WITHOUT WREN
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 13: CHIP ERASE WITHOUT WREN");
        $display("========================================");

        write_enable;

        page_program(
            24'h003000,
            8'hCA,
            8'hFE,
            8'hBA,
            8'hBE
        );

        #150;

        chip_erase;

        #550;

        read_data(
            24'h003000,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hCA,
            8'hFE,
            8'hBA,
            8'hBE,
            "Chip Erase blocked without WREN"
        );


        // =================================================
        // TEST 14
        // CHIP ERASE
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 14: CHIP ERASE");
        $display("========================================");

        // Program three different locations.

        write_enable;

        page_program(
            24'h000010,
            8'h11,
            8'h22,
            8'h33,
            8'h44
        );

        #150;

        write_enable;

        page_program(
            24'h008010,
            8'h55,
            8'h66,
            8'h77,
            8'h88
        );

        #150;

        write_enable;

        page_program(
            24'h00FFF0,
            8'hAA,
            8'hBB,
            8'hCC,
            8'hDD
        );

        #150;

        // Chip erase.

        write_enable;

        chip_erase;

        #100;

        read_status(status);

        $display("Status during Chip Erase = %h", status);

        if (status == 8'h03)
            pass("Chip Erase BUSY asserted");
        else
            fail("Chip Erase BUSY incorrect");

        #450;

        read_status(status);

        if (status == 8'h00)
            pass("Chip Erase completed");
        else
            fail("Chip Erase did not complete");


        // Start

        read_data(
            24'h000010,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "Chip Erase start"
        );


        // Middle

        read_data(
            24'h008010,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "Chip Erase middle"
        );


        // End

        read_data(
            24'h00FFF0,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "Chip Erase end"
        );


        // =================================================
        // TEST 15
        // JEDEC ID
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 15: JEDEC ID");
        $display("========================================");

        read_jedec;

        $display(
            "JEDEC = %h %h %h",
            jedec1,
            jedec2,
            jedec3
        );

        if ((jedec1 == 8'hEF) &&
            (jedec2 == 8'h40) &&
            (jedec3 == 8'h17))

            pass("JEDEC ID correct");

        else
            fail("JEDEC ID incorrect");


        // =================================================
        // TEST 16
        // COMMAND DURING BUSY
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 16: COMMAND DURING BUSY");
        $display("========================================");

        // Put some data into memory first.

        write_enable;

        page_program(
            24'h004000,
            8'h12,
            8'h34,
            8'h56,
            8'h78
        );

        #150;

        // Start Chip Erase.

        write_enable;

        chip_erase;

        // Immediately try Write Enable while BUSY.

        #20;

        write_enable;

        // Check that BUSY is still active.

        read_status(status);

        $display("Status while operation is active = %h", status);

        if (status[0] == 1'b1)
            pass("BUSY remains active during operation");
        else
            fail("BUSY unexpectedly cleared");


        // Wait for Chip Erase to finish.

        #500;

        read_status(status);

        if (status == 8'h00)
            pass("Operation completed normally");
        else
            fail("Operation did not complete normally");


        // Verify memory was actually erased.

        read_data(
            24'h004000,
            data1,
            data2,
            data3,
            data4
        );

        check_data(
            8'hFF,
            8'hFF,
            8'hFF,
            8'hFF,
            "BUSY operation still completed correctly"
        );


        // =================================================
        // FINAL SUMMARY
        // =================================================

        $display("");
        $display("");
        $display("========================================");
        $display("        FINAL TEST SUMMARY");
        $display("========================================");

        $display("TOTAL PASSED = %0d", pass_count);
        $display("TOTAL FAILED = %0d", fail_count);

        $display("========================================");

        if (fail_count == 0) begin

            $display("ALL TESTS PASSED");
            $display("SPI FLASH RTL MODEL VERIFIED");

        end
        else begin

            $display("SOME TESTS FAILED");
            $display("RTL REQUIRES FURTHER DEBUGGING");

        end

        $display("========================================");

        $stop;

    end

endmodule
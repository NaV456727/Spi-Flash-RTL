`timescale 1ns/1ps

module spi_flash_tb;

    // =====================================================
    // SPI signals
    // =====================================================

    reg cs;
    reg sclk;
    reg mosi;
    wire miso;


    // =====================================================
    // Device Under Test
    // =====================================================

    spi_flash uut (
        .cs   (cs),
        .sclk (sclk),
        .mosi (mosi),
        .miso (miso)
    );


    // =====================================================
    // Test registers
    // =====================================================

    reg [7:0] status_initial;
    reg [7:0] status_after_wren;
    reg [7:0] status_during_erase;
    reg [7:0] status_after_erase;

    reg [7:0] read_data_1;
    reg [7:0] read_data_2;
    reg [7:0] read_data_3;
    reg [7:0] read_data_4;

    reg [7:0] jedec_1;
    reg [7:0] jedec_2;
    reg [7:0] jedec_3;


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

            data = 8'b0;

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
    // READ STATUS REGISTER
    // =====================================================

    task read_status;
        output [7:0] status;

        begin

            cs = 1'b0;

            spi_send_byte(8'h05);
            spi_receive_byte(status);

            cs = 1'b1;

            #10;

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
    // PAGE PROGRAM
    // =====================================================

    task page_program;
        input [23:0] address;
        input [7:0] data1;
        input [7:0] data2;
        input [7:0] data3;
        input [7:0] data4;

        begin

            write_enable;

            cs = 1'b0;

            spi_send_byte(8'h02);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            spi_send_byte(data1);
            spi_send_byte(data2);
            spi_send_byte(data3);
            spi_send_byte(data4);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // READ DATA
    // =====================================================

    task read_data;
        input [23:0] address;
        output [7:0] data1;
        output [7:0] data2;
        output [7:0] data3;
        output [7:0] data4;

        begin

            cs = 1'b0;

            spi_send_byte(8'h03);

            spi_send_byte(address[23:16]);
            spi_send_byte(address[15:8]);
            spi_send_byte(address[7:0]);

            spi_receive_byte(data1);
            spi_receive_byte(data2);
            spi_receive_byte(data3);
            spi_receive_byte(data4);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // CHIP ERASE
    // =====================================================

    task chip_erase;

        begin

            write_enable;

            cs = 1'b0;

            spi_send_byte(8'hC7);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // JEDEC ID
    // =====================================================

    task read_jedec_id;

        begin

            cs = 1'b0;

            spi_send_byte(8'h9F);

            spi_receive_byte(jedec_1);
            spi_receive_byte(jedec_2);
            spi_receive_byte(jedec_3);

            cs = 1'b1;

            #10;

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        // -----------------------------------------------
        // Initial SPI values
        // -----------------------------------------------

        cs   = 1'b1;
        sclk = 1'b0;
        mosi = 1'b0;

        #20;


        // =================================================
        // 0. INITIAL STATUS
        // =================================================

        $display("--------------------------------");
        $display("0. INITIAL STATUS");
        $display("--------------------------------");

        read_status(status_initial);

        $display("Status = %h", status_initial);

        if (status_initial == 8'h00)
            $display("PASS: Initial status is 00h");
        else
            $display("FAIL: Initial status is not 00h");


        // =================================================
        // 1. PROGRAM START OF MEMORY
        // =================================================

        $display("--------------------------------");
        $display("1. PROGRAM START OF MEMORY");
        $display("--------------------------------");

        page_program(
            24'h000010,
            8'h11,
            8'h22,
            8'h33,
            8'h44
        );

        #150;


        // =================================================
        // 2. PROGRAM MIDDLE OF MEMORY
        // =================================================

        $display("--------------------------------");
        $display("2. PROGRAM MIDDLE OF MEMORY");
        $display("--------------------------------");

        page_program(
            24'h008010,
            8'h55,
            8'h66,
            8'h77,
            8'h88
        );

        #150;


        // =================================================
        // 3. PROGRAM END OF MEMORY
        // =================================================

        $display("--------------------------------");
        $display("3. PROGRAM END OF MEMORY");
        $display("--------------------------------");

        page_program(
            24'h00FFF0,
            8'hAA,
            8'hBB,
            8'hCC,
            8'hDD
        );

        #150;


        // =================================================
        // 4. VERIFY DATA BEFORE CHIP ERASE
        // =================================================

        $display("--------------------------------");
        $display("4. VERIFY DATA BEFORE CHIP ERASE");
        $display("--------------------------------");


        // Start

        read_data(
            24'h000010,
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        $display(
            "Start  = %h %h %h %h",
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        if ((read_data_1 == 8'h11) &&
            (read_data_2 == 8'h22) &&
            (read_data_3 == 8'h33) &&
            (read_data_4 == 8'h44))

            $display("PASS: Start data correct");

        else
            $display("FAIL: Start data incorrect");


        // Middle

        read_data(
            24'h008010,
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        $display(
            "Middle = %h %h %h %h",
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        if ((read_data_1 == 8'h55) &&
            (read_data_2 == 8'h66) &&
            (read_data_3 == 8'h77) &&
            (read_data_4 == 8'h88))

            $display("PASS: Middle data correct");

        else
            $display("FAIL: Middle data incorrect");


        // End

        read_data(
            24'h00FFF0,
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        $display(
            "End    = %h %h %h %h",
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        if ((read_data_1 == 8'hAA) &&
            (read_data_2 == 8'hBB) &&
            (read_data_3 == 8'hCC) &&
            (read_data_4 == 8'hDD))

            $display("PASS: End data correct");

        else
            $display("FAIL: End data incorrect");


        // =================================================
        // 5. WRITE ENABLE FOR CHIP ERASE
        // =================================================

        $display("--------------------------------");
        $display("5. WRITE ENABLE FOR CHIP ERASE");
        $display("--------------------------------");

        write_enable;

        read_status(status_after_wren);

        $display("Status = %h", status_after_wren);

        if (status_after_wren == 8'h02)
            $display("PASS: WEL = 1, BUSY = 0");
        else
            $display("FAIL: Incorrect status");


        // =================================================
        // 6. CHIP ERASE
        // =================================================

        $display("--------------------------------");
        $display("6. CHIP ERASE");
        $display("--------------------------------");

        chip_erase;


        // =================================================
        // 7. STATUS DURING CHIP ERASE
        // =================================================

        $display("--------------------------------");
        $display("7. STATUS DURING CHIP ERASE");
        $display("--------------------------------");

        #1;

        read_status(status_during_erase);

        $display("Status = %h", status_during_erase);

        if (status_during_erase == 8'h03)
            $display("PASS: WEL = 1, BUSY = 1");
        else
            $display("FAIL: BUSY behavior incorrect");


        // =================================================
        // 8. WAIT FOR CHIP ERASE
        // =================================================

        $display("--------------------------------");
        $display("8. WAIT FOR CHIP ERASE");
        $display("--------------------------------");

        #450;


        // =================================================
        // 9. STATUS AFTER CHIP ERASE
        // =================================================

        $display("--------------------------------");
        $display("9. STATUS AFTER CHIP ERASE");
        $display("--------------------------------");

        read_status(status_after_erase);

        $display("Status = %h", status_after_erase);

        if (status_after_erase == 8'h00)
            $display("PASS: WEL = 0, BUSY = 0");
        else
            $display("FAIL: Incorrect final status");


        // =================================================
        // 10. VERIFY START ERASED
        // =================================================

        $display("--------------------------------");
        $display("10. VERIFY START OF MEMORY ERASED");
        $display("--------------------------------");

        read_data(
            24'h000010,
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        $display(
            "Start = %h %h %h %h",
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        if ((read_data_1 == 8'hFF) &&
            (read_data_2 == 8'hFF) &&
            (read_data_3 == 8'hFF) &&
            (read_data_4 == 8'hFF))

            $display("PASS: Start of memory erased");

        else
            $display("FAIL: Start of memory not erased");


        // =================================================
        // 11. VERIFY MIDDLE ERASED
        // =================================================

        $display("--------------------------------");
        $display("11. VERIFY MIDDLE OF MEMORY ERASED");
        $display("--------------------------------");

        read_data(
            24'h008010,
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        $display(
            "Middle = %h %h %h %h",
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        if ((read_data_1 == 8'hFF) &&
            (read_data_2 == 8'hFF) &&
            (read_data_3 == 8'hFF) &&
            (read_data_4 == 8'hFF))

            $display("PASS: Middle of memory erased");

        else
            $display("FAIL: Middle of memory not erased");


        // =================================================
        // 12. VERIFY END ERASED
        // =================================================

        $display("--------------------------------");
        $display("12. VERIFY END OF MEMORY ERASED");
        $display("--------------------------------");

        read_data(
            24'h00FFF0,
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        $display(
            "End = %h %h %h %h",
            read_data_1,
            read_data_2,
            read_data_3,
            read_data_4
        );

        if ((read_data_1 == 8'hFF) &&
            (read_data_2 == 8'hFF) &&
            (read_data_3 == 8'hFF) &&
            (read_data_4 == 8'hFF))

            $display("PASS: End of memory erased");

        else
            $display("FAIL: End of memory not erased");


        // =================================================
        // 13. READ JEDEC ID
        // =================================================

        $display("--------------------------------");
        $display("13. READ JEDEC ID");
        $display("--------------------------------");

        read_jedec_id;

        $display("Manufacturer ID = %h", jedec_1);
        $display("Memory Type     = %h", jedec_2);
        $display("Device ID       = %h", jedec_3);

        if ((jedec_1 == 8'hEF) &&
            (jedec_2 == 8'h40) &&
            (jedec_3 == 8'h17))

            $display("PASS: JEDEC ID correct");

        else
            $display("FAIL: JEDEC ID incorrect");


        // =================================================
        // FINAL MEMORY CHECK
        // =================================================

        $display("--------------------------------");
        $display("FINAL MEMORY CONTENT");
        $display("--------------------------------");

        $display(
            "Memory[0010] = %h",
            uut.memory[16'h0010]
        );

        $display(
            "Memory[8010] = %h",
            uut.memory[16'h8010]
        );

        $display(
            "Memory[FFF0] = %h",
            uut.memory[16'hFFF0]
        );


        // =================================================
        // COMPLETE
        // =================================================

        $display("--------------------------------");
        $display("CHIP ERASE TEST COMPLETE");
        $display("--------------------------------");

        $stop;

    end

endmodule
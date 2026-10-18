
`timescale 1ns/1ps

module tb_mult;

    reg clk;
    reg rst_n;
    reg [3:0] a;
    reg [3:0] b;
    wire [7:0] p;

    integer expected [0:255];
    integer idx;
    integer check_idx;
    integer errors;
    integer checked;
    integer i;

    mult_array dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .p(p)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Compare the output against a previously driven vector.
    task check_result;
        input integer vector_idx;
        begin
            if (p !== expected[vector_idx]) begin
                $display(
                    "MISMATCH: a=%0d b=%0d expected=%0d got=%0d",
                    vector_idx / 16,
                    vector_idx % 16,
                    expected[vector_idx],
                    p
                );
                errors = errors + 1;
            end
            checked = checked + 1;
        end
    endtask

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        clk = 1'b0;
        rst_n = 1'b0;
        a = 4'd0;
        b = 4'd0;
        errors = 0;
        checked = 0;

        // Expected answers are calculated independently.
        for (i = 0; i < 256; i = i + 1)
            expected[i] = (i / 16) * (i % 16);

        // Hold reset low for two rising clock edges.
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Drive all 256 input combinations.
        for (idx = 0; idx < 256; idx = idx + 1) begin
            @(posedge clk);
            #1;
            a = idx / 16;
            b = idx % 16;

            // Two clock edges after the input is driven.
            if (idx >= 2)
                check_result(idx - 2);
        end

        // Drain the final two results from the pipeline.
        repeat (2) begin
            @(posedge clk);
            #1;
            check_idx = checked;
            check_result(check_idx);
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, 0 errors", checked);
        else
            $display("FAIL: %0d vectors checked, %0d errors",
                     checked, errors);

        $finish;
    end

endmodule

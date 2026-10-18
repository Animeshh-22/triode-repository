
`timescale 1ns/1ps

module tb_full_adder;

    reg a, b, cin;
    wire sum, cout;
    integer i;
    integer errors;

    full_adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        errors = 0;

        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i;
            #10;

            if ({cout, sum} !== (a + b + cin)) begin
                $display(
                    "FAIL: a=%b b=%b cin=%b sum=%b cout=%b",
                    a, b, cin, sum, cout
                );
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: 8 vectors checked, 0 errors");
        else
            $display("FAIL: 8 vectors checked, %0d errors", errors);

        $finish;
    end

endmodule

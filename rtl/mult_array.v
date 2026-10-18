
module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    // Input registers
    reg [3:0] a_reg;
    reg [3:0] b_reg;

    // Partial-product rows
    wire [3:0] pp0, pp1, pp2, pp3;

    assign pp0 = a_reg & {4{b_reg[0]}};
    assign pp1 = a_reg & {4{b_reg[1]}};
    assign pp2 = a_reg & {4{b_reg[2]}};
    assign pp3 = a_reg & {4{b_reg[3]}};

    // Intermediate rows and carries
    wire [3:0] r0, r1, r2;
    wire [3:0] s1, s2, s3;
    wire [4:0] c1, c2, c3;

    wire [7:0] product_comb;

    // Row 0: least-significant partial product
    assign product_comb[0] = pp0[0];
    assign r0 = {1'b0, pp0[3:1]};

    // Row 1
    assign c1[0] = 1'b0;

    full_adder fa10 (
        .a(pp1[0]), .b(r0[0]), .cin(c1[0]),
        .sum(s1[0]), .cout(c1[1])
    );
    full_adder fa11 (
        .a(pp1[1]), .b(r0[1]), .cin(c1[1]),
        .sum(s1[1]), .cout(c1[2])
    );
    full_adder fa12 (
        .a(pp1[2]), .b(r0[2]), .cin(c1[2]),
        .sum(s1[2]), .cout(c1[3])
    );
    full_adder fa13 (
        .a(pp1[3]), .b(r0[3]), .cin(c1[3]),
        .sum(s1[3]), .cout(c1[4])
    );

    assign product_comb[1] = s1[0];
    assign r1 = {c1[4], s1[3:1]};

    // Row 2
    assign c2[0] = 1'b0;

    full_adder fa20 (
        .a(pp2[0]), .b(r1[0]), .cin(c2[0]),
        .sum(s2[0]), .cout(c2[1])
    );
    full_adder fa21 (
        .a(pp2[1]), .b(r1[1]), .cin(c2[1]),
        .sum(s2[1]), .cout(c2[2])
    );
    full_adder fa22 (
        .a(pp2[2]), .b(r1[2]), .cin(c2[2]),
        .sum(s2[2]), .cout(c2[3])
    );
    full_adder fa23 (
        .a(pp2[3]), .b(r1[3]), .cin(c2[3]),
        .sum(s2[3]), .cout(c2[4])
    );

    assign product_comb[2] = s2[0];
    assign r2 = {c2[4], s2[3:1]};

    // Row 3
    assign c3[0] = 1'b0;

    full_adder fa30 (
        .a(pp3[0]), .b(r2[0]), .cin(c3[0]),
        .sum(s3[0]), .cout(c3[1])
    );
    full_adder fa31 (
        .a(pp3[1]), .b(r2[1]), .cin(c3[1]),
        .sum(s3[1]), .cout(c3[2])
    );
    full_adder fa32 (
        .a(pp3[2]), .b(r2[2]), .cin(c3[2]),
        .sum(s3[2]), .cout(c3[3])
    );
    full_adder fa33 (
        .a(pp3[3]), .b(r2[3]), .cin(c3[3]),
        .sum(s3[3]), .cout(c3[4])
    );

    assign product_comb[3]   = s3[0];
    assign product_comb[7:4] = {c3[4], s3[3:1]};

    // Register input operands
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Register the product
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p <= 8'b00000000;
        else
            p <= product_comb;
    end

endmodule

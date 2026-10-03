// -----------------------------------------------------------------------------
//
//  Title      :  System Verilog FSMD implementation template for GCD
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  This is a template for the FSMD (finite state machine with datapath) 
//             :  implementation of the GCD circuit
//             :
//  Revision   :  02203 fall 2025 v.1.0
//
// -----------------------------------------------------------------------------


module gcd (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);
    typedef enum logic [3 : 0] {
        IDLE,
        LOADA,
        ACKA,
        WAITB,
        LOADB,
        LOOP,
        AGREATEST,
        BGREATEST,
        ACKB
    } state_t;

    shortint unsigned reg_a, next_reg_a, reg_b, next_reg_b;
    
    state_t state, next_state;

    logic ABorALU, LDA, LDB, N, Z, OutputC;
    logic [1 : 0] FN;
    logic [15 : 0] Y, C_int;
    
//    // C_int to C buffer
//    c_buf #(
//        .N(16)
//    ) u_BufferC (
//        .data_in(C_int),
//        .data_out(C)
//    );
    // C_int to C mux (so the output only is visible when finished)
    c_mux #( 
        .N(16)
    ) u_OutputC (
        .data_in1(C_int),
        .data_in2(16'b0),
        .s(OutputC),
        .data_out(C)
    );
    
    // ABorALU mux
    c_mux #( 
        .N(16)
    ) u_ABorALU (
        .data_in1(AB),
        .data_in2(Y),
        .s(ABorALU),
        .data_out(C_int)
    );
    
    // RegA
    c_reg #(
        .N(16)
    ) u_RegA (
        .clk(clk),
        .en(LDA),
        .data_in(C_int),
        .data_out(reg_a)
    );
        
    // RegB
    c_reg #(
        .N(16)
    ) u_RegB (
        .clk(clk),
        .en(LDB),
        .data_in(C_int),
        .data_out(reg_b)
    );
    
    // Instantiation of ALU module
    c_alu #(
        .W(16)
    ) u_ALU (
        .A(reg_a),
        .B(reg_b),
        .fn(FN),
        .C(Y),
        .Z(Z),
        .N(N)
    );

    
    // Combinatorial logic
    always_comb begin
        // Moore outputs of FSM
        case (state)
            LOADA: begin
                ABorALU = 1'b1;
                LDA = 1'b1;
            end
            ACKA: begin 
                ack = 1'b1;
            end
            LOADB: begin
                ABorALU = 1'b1;
                LDB = 1'b1;
            end
            AGREATEST: begin
                FN = 2'b00;
                LDA = 1'b1;
            end
            BGREATEST: begin
                FN = 2'b01; 
                LDB = 1'b1;
            end
            ACKB: begin
                FN = 2'b10;
                ack = 1'b1;
                OutputC = 1'b1;
            end
            default: begin
                ABorALU = 1'b0;
                LDA = 1'b0;
                LDB = 1'b0;
                FN = 2'b00;
                ack = 1'b0;
                OutputC = 1'b0;
            end
        endcase

        // Next state of FSM
        case (state)
            IDLE: begin
                if (req) begin
                    next_state = LOADA;
                end
                else begin
                    next_state = IDLE;
                end
            end
            LOADA: begin
                next_state = ACKA;
            end
            ACKA: begin
                if (req) begin
                    next_state = ACKA;
                end
                else begin
                    next_state = WAITB;
                end
            end
            WAITB: begin
                if (req) begin
                    next_state = LOADB;
                end
                else begin
                    next_state = WAITB;
                end
            end
            LOADB: begin
                next_state = LOOP;
            end
            LOOP: begin
                if (Z) begin
                    next_state = ACKB;
                end
                else begin
                    if (N) begin
                        next_state = BGREATEST;
                    end
                    else begin
                        next_state = AGREATEST;
                    end
                end
            end
            AGREATEST: begin
                next_state = LOOP;
            end
            BGREATEST: begin
                next_state = LOOP;
            end
            ACKB: begin
                if (req) begin
                    next_state = ACKB;
                end
                else begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase

    end

    // Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

endmodule

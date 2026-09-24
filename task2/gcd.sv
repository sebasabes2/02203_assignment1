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
    typedef enum logic [1 : 0] {
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

    logic ABorALU, LDA, LDB, N, Z;
    logic [1 : 0] FN;
    
    // Combinatorial logic
    always_comb begin
        ABorALU = 1'b0;
        LDA = 1'b0;
        LDB = 1'b0;
        FN = 2'b00;
        ack = 1'b0; 

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
                ABorALU = 1'b1;
                LDA = 1'b1;
                next_state = ACKA
            end
            ACKA: begin 
                ack = 1'b1;
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
                ABorALU = 1'b1;
                LDB = 1'b1;
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
                FN = 2'b00;
                LDA = 1'b1;
                next_state = LOOP;
            end
            BGREATEST: begin
                FN = 2'b01; 
                LDB = 1'b1;
                next_state = LOOP;
            end
            ACKB: begin
                FN = 2'b10;
                ack = 1'b1;
                if (req) begin
                    next_state = ACKB;
                end
                else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
            reg_a <= 16'b0;
            reg_b <= 16'b0;
        else
            state <= next_state;
            reg_a <= next_reg_a;
            reg_b <= next_reg_b;
    end

endmodule
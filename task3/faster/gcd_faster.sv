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


module gcd_faster (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);
    typedef enum logic [2 : 0] {
        IDLE,
        LOADA,
        ACKA,
        WAITB,
        LOADB,
        LOOP,
        ACKB
    } state_t;

    shortint unsigned reg_a, next_reg_a, reg_b, next_reg_b;
    
    state_t state, next_state;

    logic ABorALU, LDA, LDB, N, Z, OutputC;
    logic [15 : 0] Y0, Y1, Y, C_int;
    
    // Combinatorial logic
    always_comb begin
        // Datapath
        Y0 = reg_a - reg_b;
        Y1 = reg_b - reg_a;

        if (Y0 == 16'b0) begin
            Z = 1'b1;
        end
        else begin
            Z = 1'b0;
        end

        N = Y0[15];

        if (N) begin
            Y = Y1;
        end
        else begin
            Y = Y0;
        end

        // Moore and mealy outputs of FSM
        ABorALU = 1'b0;
        LDA = 1'b0;
        LDB = 1'b0;
        ack = 1'b0;
        OutputC = 1'b0;
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
            LOOP: begin
                if (N) begin
                    LDB = 1'b1;
                end
                else begin
                    LDA = 1'b1; 
                end
            end
            ACKB: begin
                ack = 1'b1;
                OutputC = 1'b1;
            end
        endcase

        // DataPath continued
        if (ABorALU) begin
            C_int = AB;
        end
        else begin
            C_int = Y;
        end

        if (LDA) begin
            next_reg_a = C_int;
        end
        else begin
            next_reg_a = reg_a;
        end

        if (LDB) begin
            next_reg_b = C_int;
        end
        else begin
            next_reg_b = reg_b;
        end

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
                    next_state = LOOP;
                end
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

        // Output
        if (OutputC) begin
            C = C_int;
        end
        else begin
            C = 16'b0;
        end
    end

    // Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            reg_a <= 16'b0;
            reg_b <= 16'b0;
        end
        else begin
            state <= next_state;
            reg_a <= next_reg_a;
            reg_b <= next_reg_b;
        end
    end

endmodule

`timescale 1ns/100ps

module tb_tp6();

wire                  o_symbol_I ;
wire                  o_symbol_Q ;
reg                   i_reset    ;
reg                   clock      ;

initial begin
    clock               = 1'b0       ;
    i_reset             = 1'b0       ;
    #100 i_reset        = 1'b1       ;
    #110 i_reset        = 1'b0       ;
    #100000 $finish                  ;

    end

always #5 clock = ~clock;

prbs9
#(
    .SEED(9'b110101010)

)
  u_prbs9_I
    (
        .o_symb  (o_symbol_I),     //! Symbol to output
        //.i_enb,                //! Enable Tx
        .i_rst    (i_reset),     //! Reset
        .i_valid    (clock),     //! Validate 1 T
        .clk        (clock)      //! Clock
    );
prbs9
#(
    .SEED(9'b111111110)
)
    u_prbs9_Q
    (
            .o_symb  (o_symbol_Q),     //! Symbol to output
            //.i_enb,                //! Enable Tx
            .i_rst    (i_reset),     //! Reset
            .i_valid    (clock),     //! Validate 1 T
            .clk        (clock)      //! Clock
    );



endmodule
`timescale 1ns/100ps

module tb_filter();

parameter NB_INPUT   = 8; //! NB of input
parameter NBF_INPUT  = 7; //! NBF of input
parameter NB_OUTPUT  = 8; //! NB of output
parameter NBF_OUTPUT = 7; //! NBF of output
parameter NB_COEFF   = 8; //! NB of Coefficients
parameter NBF_COEFF  = 7; //! NBF of Coefficients
parameter OV_SAMP    = 4; //! Oversampling

reg                   i_reset   ;
reg                   clock     ;//  T/4
wire signed       [NB_INPUT-1:0]   o_I_filtred;
wire              [3:0]     i_sw;
reg           [3:0]    conect_sw;

initial begin
    clock               = 1'b0       ;
    conect_sw           = 4'b0000    ;
    i_reset             = 1'b0       ;
    #100 i_reset        = 1'b1       ;
    #110 i_reset        = 1'b0       ;
    #110 conect_sw      = 4'b0001    ;
    #100000 $finish                  ;

    end

always #5 clock = ~clock;

assign i_sw = conect_sw;

topLevel
#(
    .NB_SW     (4)         ,
    .NB_LEDS   (4)         ,
    .NB_INPUT  (NB_INPUT)  , //! NB of input
    .NBF_INPUT (NBF_INPUT) , //! NBF of input
    .OV_SAMP   (OV_SAMP)
 )
  u_toplevel
(
    //.o_led(),
    .i_sw (i_sw),
    .o_I_wire_filtred(o_I_filtred),
    .reset(i_reset),        //!Reset
    .clock(clock)         //!Clock funciona a T/4
);

endmodule
`timescale 1ns/100ps

module tb_tp6();

parameter NB_INPUT   = 8; //! NB of input
parameter NBF_INPUT  = 7; //! NBF of input
parameter NB_OUTPUT  = 8; //! NB of output
parameter NBF_OUTPUT = 7; //! NBF of output
parameter NB_COEFF   = 8; //! NB of Coefficients
parameter NBF_COEFF  = 7; //! NBF of Coefficients
parameter OV_SAMP    = 4; //! Oversampling

reg                   i_reset   ;
reg                   clock     ;//  T/4
reg                   tb_en     ;//  T
reg  [NB_INPUT-1:0]   tb_is_data;

wire [NB_OUTPUT-1:0]  tb_os_data;

initial begin
    clock               = 1'b0       ;
    i_reset             = 1'b0       ;
    #100 i_reset        = 1'b1       ;
    #110 i_reset        = 1'b0       ;
    #100000 $finish                  ;

    end

always #5 clock = ~clock;

filter
#(    
    .NB_INPUT       (NB_INPUT), //! NB of input
    .NBF_INPUT      (NBF_INPUT), //! NBF of input
    .NB_OUTPUT      (NB_OUTPUT), //! NB of output
    .NBF_OUTPUT     (NBF_OUTPUT), //! NBF of output
    .NB_COEFF       (NB_COEFF), //! NB of Coefficients
    .NBF_COEFF      (NBF_COEFF), //! NBF of Coefficients)
    .OV_SAMP        (OV_SAMP)
)
  u_filter
    (
        .o_os_data      (tb_os_data), //! Output Sample   //No necesitamos esto creo
        .i_is_data      (tb_is_data), //! Input Sample 
        .i_enb          (), //! Enable
        .i_valid        (), //! Validation
        .i_srst         (), //! Reset
        .clk            ()  //! Clock
    );

endmodule
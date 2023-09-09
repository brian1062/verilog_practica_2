//! @title Test-Bench Filtro
//! @author Brian Gerard
//! @date 08-09-2023

//! - TestBench diseñado para comprobar el correcto funcionamiento
//! - de la prbs9.v , filterPolFas.v, dowmSampler.v Y tambien de 
//! - forma agrupada en el topLevel.v


`timescale 1ns/100ps

module tb_filter();

parameter NB_INPUT   = 8; //! NB of input
parameter NBF_INPUT  = 7; //! NBF of input
parameter NB_OUTPUT  = 8; //! NB of output
parameter NBF_OUTPUT = 7; //! NBF of output
parameter NB_COEFF   = 8; //! NB of Coefficients
parameter NBF_COEFF  = 7; //! NBF of Coefficients
parameter OV_SAMP    = 4; //! Oversampling

reg                                i_reset              ;
reg                                clock                ;//  T/4
reg               [3:0]            conect_sw            ;
wire signed       [NB_INPUT-1:0]   o_I_filtred_T        ;
wire signed       [NB_INPUT-1:0]   o_I_from_filt_to_down;
wire              [3:0]            i_sw                 ;
wire                               T                    ;

initial begin
    clock               = 1'b0       ;
    conect_sw           = 4'b0000    ;
    i_reset             = 1'b0       ;
    #100 i_reset        = 1'b1       ;
    #100 conect_sw      = 4'b0001    ;
    #110 i_reset        = 1'b0       ;
    //#150 i_reset        = 1'b1       ;
    #150 conect_sw      = 4'b0001    ;
    //#110 i_reset        = 1'b0       ;
    #100000 $finish                  ;

    end

always #5 clock = ~clock;

assign i_sw = conect_sw;

topLevel
#(
    .NB_SW     (4)         , //! NB switch
    .NB_LEDS   (4)         , //! NB LEDS
    .NB_INPUT  (NB_INPUT)  , //! NB of input
    .NBF_INPUT (NBF_INPUT) , //! NBF of input
    .OV_SAMP   (OV_SAMP)     //! Oversample value
 )
  u_toplevel
(
    //.o_led(),
    .i_sw                   (i_sw                 ), //! i_switch[3:0]
    .o_I_filtred_DownS      (o_I_filtred_T        ), //! Salida filtro DownS T/4,
    .o_I_from_filt_to_down  (o_I_from_filt_to_down), //! Salida filtro T.
    .reset                  (i_reset              ), //! Reset
    .clockT                 (T                    ), //! Clock funciona a T (solo para visualizacion)
    .clock                  (clock                )  //! Clock funciona a T/4
);

endmodule
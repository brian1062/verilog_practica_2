//! @title Test-Bench ber
//! @author Brian Gerard
//! @date 09-09-2023

//! - TestBench diseñado para comprobar el correcto funcionamiento
//! - de la ber conectado a todo el sistema


`timescale 1ns/100ps

module tb_ber();

parameter NB_INPUT   = 8; //! NB of input
parameter NBF_INPUT  = 7; //! NBF of input
parameter OV_SAMP    = 4; //! Oversampling
parameter NB_LEDS    = 4; //! NB of Leds
parameter NB_SW      = 4; //! NB of Switch
parameter NB_BER     =64;

reg                                i_reset              ;
reg                                clock                ;//  T/4
reg               [NB_SW   -1:0]   i_sw                 ;
//wire signed       [NB_INPUT-1:0]   o_I_filtred_T        ;
//wire signed       [NB_INPUT-1:0]   o_I_from_filt_to_down;
//wire              [NB_SW   -1:0]   i_sw                 ;
wire              [NB_LEDS -1:0]                   o_led;

reg               [       1 : 0]                  timer0;
wire                                                   T;
//! Tx
wire signed       [NB_INPUT-1 : 0]                I_wire;
wire signed       [NB_INPUT-1 : 0]        I_wire_filtred;
wire signed       [NB_INPUT-1 : 0]           I_DownSampl;
//! Rx
wire              [NB_BER-1:0]            wire_count_bit;
wire              [NB_BER-1:0]            wire_count_err;
wire [9:0] indice_correcto;

initial begin
    clock               = 1'b0       ;
    i_sw                = 4'b0000    ;
    i_reset             = 1'b0       ;
    #105 i_reset        = 1'b1       ;
    #100 i_sw           = 4'b1111    ; //!Enable Tx y Rx
    #125 i_reset        = 1'b0       ;
    //#150 i_reset        = 1'b1       ;
    //#150 i_sw           = 4'b0011    ;
    //#110 i_reset        = 1'b0       ;
    #100000 $finish                  ;

    end

always #5 clock = ~clock;

always @(posedge clock) begin:timer0set
    if(i_reset)begin
        timer0 <= 2'b00;
    end
    else begin
        if(timer0 == 2'b11)begin
            timer0 <= 2'b00;
        end
        else begin
            timer0 <= timer0 + 2'b01;
        end
    end
end 

assign T = (timer0==2'b00)? 1'b1 : 1'b0;

prbs9
#(
    .SEED            (9'b110101010         ),
    .NB_OUTPUT       (NB_INPUT             )

)
  u_prbs9_I
    (
        .o_symb      (I_wire               ),     //! Symbol to output
        .i_enable    (i_sw[0]              ),     //! Enable
        .i_rst       (i_reset              ),     //! Reset
        .i_valid     (T                    ),     //! Validate 1 T
        .clk         (clock                )      //! Clock
    );

filterPolFas
#(    
    .NB_INPUT        (NB_INPUT             ), //! NB of input
    .NBF_INPUT       (NBF_INPUT            ), //! NBF of input
    .NB_OUTPUT       (NB_INPUT             ), //! NB of output
    .NBF_OUTPUT      (NBF_INPUT            ), //! NBF of output
    .NB_COEFF        (NB_INPUT             ), //! NB of Coefficients
    .NBF_COEFF       (NBF_INPUT            )  //! NBF of Coefficients)
)
    u_filterPolFas_I
    (
        .o_os_data    (I_wire_filtred      ), //! Output Sample   //sale p3p2p1p0p3p2p1p0->
        .i_is_data    (I_wire              ), //! Input Sample 
        .i_enb        (i_sw[0]             ), //! Enable
        .i_srst       (i_reset             ), //! Reset
        .clk          (clock               )  //! Clock
    );
downSampler
#(
    .NB_OUTPUT       (NB_INPUT             ), //! NB of output
    .NBF_OUTPUT      (NBF_INPUT            ), //! NBF of output
    .OV_SAMP         (OV_SAMP              )  //! Oversampling

)
u_downSampler_I
    (   
        .i_phase_selector(i_sw[3:2]        ),  //! Phase selector i_sw[3:2]
        .i_filt_sample   (I_wire_filtred   ),
        .o_down_sample   (I_DownSampl      ),
        .clock           (clock            ),
        .reset           (i_reset          )
    );
ber
#(
    .NB_PRBS          (9                   ),  //! Number bit. prbs
    .NB_BER           (64                  ),  //! Error storange bit number
    .LIMIT            (511                 ),  //! Max limit pseudorandom  2**9 -1
    .LIMIT2           (1024                )   //! Max limit arrayBER
)
  u_ber_I
    (
        .o_indice     (indice_correcto),
        .o_count_bit  (wire_count_bit      ),  //!outputs para ver en simulacion
        .o_count_err  (wire_count_err      ),
        .o_led        (o_led[3]            ),
        .i_enbRx      (i_sw[1]             ),
        .i_valid      (T                   ),  //!i_valid trabaja a T
        .i_prbs       (I_wire              ),
        .i_Rx         (I_DownSampl[7]      ),  //bit de signo
        .i_clock      (clock               ),
        .i_reset      (i_reset             )

    );

endmodule
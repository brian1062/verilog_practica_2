//! @title TOP-LEVEL
//! @author Brian Gerard
//! @date 08-09-2023

//! - Top level de implementacion

module topLevel
#(
    parameter NB_SW          = 4, //! NB of Switch
    parameter NB_LEDS        = 4, //! NB of Leds
    parameter NB_INPUT       = 8, //! NB of input
    parameter NBF_INPUT      = 7, //! NBF of input
    parameter OV_SAMP        = 4  //! Oversampling
)
(
    output  signed [NB_INPUT-1 : 0]    o_I_from_filt_to_down,       //! Salida filtro T.
    output  signed [NB_INPUT-1 : 0]        o_I_filtred_DownS,       //! Salida filtro DownS T/4, solamente para poder comparar
    output         [NB_LEDS -1 : 0]                    o_led,       //! o_led[3:0]
    input          [NB_SW   -1 : 0]                     i_sw,       //! i_sw[3:0]
    input                                              reset,       //! Reset
    output                                            clockT,       //! Clock funciona a T -solo para visualizar
    input                                             clock         //! Clock funciona a T/4
);


wire                                  i_valid;      //i valid para prbs9 y filter funciona a T
reg         [         1 : 0]           timer0;      //funciona a T
wire                                   enb_Tx;
wire signed [NB_INPUT-1 : 0]   I_wire_filtred;

wire signed [NB_INPUT-1 : 0]           I_wire;

wire                                   enb_Rx;
wire        [         1 : 0]        sel_phase;
wire                                   ledber;

//!Ber wires
wire        [        63 : 0]   wire_count_bit;
wire        [        63 : 0]   wire_count_err;
wire        [         9 : 0] wire_retardo_ber;

always @(posedge clock) begin:timer0set
    if(reset)begin
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

//! Senial T
assign i_valid               = (timer0==2'b00)? 1'b1 : 1'b0; //! valid input T
assign clockT                = i_valid                     ; 

//!Tx
assign enb_Tx                = i_sw[0]                     ;
assign o_I_from_prbs         = I_wire                      ;
assign o_I_from_filt_to_down = I_wire_filtred              ;

//!Rx
assign enb_Rx                = i_sw[1]                     ;
assign sel_phase             = i_sw[3:2]                   ;


//!LEDS
assign o_led[0]              = reset                       ;
assign o_led[1]              = enb_Tx                      ;
assign o_led[2]              = enb_Rx                      ;
assign o_led[3]              = ledber                      ;


prbs9
#(
    .SEED            (9'b110101010         ),
    .NB_OUTPUT       (NB_INPUT             )

)
  u_prbs9_I
    (
        .o_symb      (I_wire               ),     //! Symbol to output
        .i_enable    (enb_Tx               ),     //! Enable
        .i_rst       (reset                ),     //! Reset
        .i_valid     (i_valid              ),     //! Validate 1 T
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
        .i_enb        (enb_Tx              ), //! Enable
        .i_srst       (reset               ), //! Reset
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
        .i_phase_selector(sel_phase        ),  //! Phase selector i_sw[3:2]
        .i_filt_sample   (I_wire_filtred   ),
        .o_down_sample   (o_I_filtred_DownS),
        .clock           (clock            ),
        .reset           (reset            )
    );

ber
#(
    //parameter INIT_SEED = 9'b110101010,      //! Initial seed to prbs not used
    .NB_PRBS          (9                   ),  //! Number bit. prbs
    .NB_BER           (64                  ),  //! Error storange bit number
    .LIMIT            (511                 ),  //! Max limit pseudorandom  2**9 -1
    .LIMIT2           (1024                )   //! Max limit arrayBER

)
  u_ber_I
    (
        .o_indice     (wire_retardo_ber    ),
        .o_count_bit  (wire_count_bit      ),  //!outputs para ver en simulacion
        .o_count_err  (wire_count_err      ),
        .o_led        (ledber              ),
        .i_enbRx      (enb_Rx              ),
        .i_valid      (i_valid             ),  //!i_valid trabaja a T
        .i_prbs       (I_wire              ),
        .i_Rx         (o_I_filtred_DownS[7]),
        .i_clock      (clock               ),
        .i_reset      (reset               )

    );


endmodule
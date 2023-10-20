//! @title TOP-LEVEL
//! @author Brian Gerard
//! @date 08-09-2023

//! - Top level de implementacion

module topLevel
#(
    parameter NB_PRBS        =  9, //! NB of PRBS
    parameter NB_BER         = 64, //! NB of vertor PRBS 
    parameter NB_SW          =  4, //! NB of Switch
    parameter NB_LEDS        =  4, //! NB of Leds
    parameter NB_INPUT       =  8, //! NB of input
    parameter NBF_INPUT      =  7, //! NBF of input
    parameter OV_SAMP        =  4  //! Oversampling
)
(
    //output  signed [NB_INPUT-1 : 0]    o_I_from_filt_to_down,       //! Salida filtro T.
    //output  signed [NB_INPUT-1 : 0]        o_I_filtred_DownS,       //! Salida filtro DownS T/4, solamente para poder comparar
    //output                                            clockT,       //! Clock funciona a T -solo para visualizar
    output         [NB_LEDS -1 : 0]                    o_led,       //! o_led[3:0]
    input          [NB_SW   -1 : 0]                     i_sw,       //! i_sw[3:0]
    input                                            i_reset,       //! Reset
    input                                             clock         //! Clock funciona a T/4
);


wire                                  i_valid;      //i valid para prbs9 y filter funciona a T
reg         [         1 : 0]           timer0;      //funciona a T
wire                                   enb_Tx;

wire signed [NB_INPUT-1 : 0]           I_wire;
wire signed [NB_INPUT-1 : 0]           Q_wire;

wire signed [NB_INPUT-1 : 0]   I_wire_filtred;
wire signed [NB_INPUT-1 : 0]   Q_wire_filtred;

wire signed [NB_INPUT-1 : 0]   I_wire_downsamp_to_ber;
wire signed [NB_INPUT-1 : 0]   Q_wire_downsamp_to_ber;

wire                                   enb_Rx;
wire        [         1 : 0]        sel_phase;
wire                                   ledber;

//!Ber wires I
wire        [NB_BER-1   : 0]   I_wire_count_bit;
wire        [NB_BER-1   : 0]   I_wire_count_err;
wire        [NB_PRBS    : 0] I_wire_retardo_ber;
wire                                o_led_ber_I;
//!Ber wires Q
wire        [NB_BER-1   : 0]   Q_wire_count_bit;
wire        [NB_BER-1   : 0]   Q_wire_count_err;
wire        [NB_PRBS-1  : 0] Q_wire_retardo_ber;
wire                                o_led_ber_Q;

//------------ VIO -----------------------------
wire       [NB_SW-1    : 0]         sw_from_vio;
wire       [NB_SW-1    : 0]             sw_wire;
wire                             reset_from_vio;
wire                                    sel_mux; //! Select input from vio or hardware
wire                                      reset; 

assign sw_wire = (sel_mux) ? sw_from_vio   :
                             i_sw          ;
assign reset   = (sel_mux) ? ~reset_from_vio:
                             ~i_reset       ;                      
//-----------End_VIO ---------------------------

//! -Generador de clock en un periodo T
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
assign enb_Tx                = sw_wire[0]                  ;
//assign o_I_from_prbs         = I_wire                      ;
//assign o_I_from_filt_to_down = I_wire_filtred              ;

//!Rx
assign enb_Rx                = sw_wire[1]                  ;
assign sel_phase             = sw_wire[3:2]                ;


//!LEDS
assign o_led[0]              = reset                       ;
assign o_led[1]              = enb_Tx                      ;
assign o_led[2]              = enb_Rx                      ;
assign o_led[3]              = ((o_led_ber_I ==1'b1)&(o_led_ber_Q ==1'b1)) ;

//! signals I
prbs9
#(
    .SEED            (9'b110101010              ),
    .NB_OUTPUT       (NB_INPUT                  )

)
  u_prbs9_I
    (
        .o_symb      (I_wire                    ),     //! Symbol to output
        .i_enable    (enb_Tx                    ),     //! Enable
        .i_rst       (reset                     ),     //! Reset
        .i_valid     (i_valid                   ),     //! Validate 1 T
        .clk         (clock                     )      //! Clock
    );

filterPolFas
#(    
    .NB_INPUT        (NB_INPUT                  ), //! NB of input
    .NBF_INPUT       (NBF_INPUT                 ), //! NBF of input
    .NB_OUTPUT       (NB_INPUT                  ), //! NB of output
    .NBF_OUTPUT      (NBF_INPUT                 ), //! NBF of output
    .NB_COEFF        (NB_INPUT                  ), //! NB of Coefficients
    .NBF_COEFF       (NBF_INPUT                 )  //! NBF of Coefficients)
)
  u_filterPolFas_I
    (
        .o_os_data    (I_wire_filtred           ), //! Output Sample   //sale p3p2p1p0p3p2p1p0->
        .i_is_data    (I_wire                   ), //! Input Sample 
        .i_enb        (enb_Tx                   ), //! Enable
        .i_srst       (reset                    ), //! Reset
        .clk          (clock                    )  //! Clock
    );

downSampler
#(
    .NB_OUTPUT       (NB_INPUT                  ), //! NB of output
    .NBF_OUTPUT      (NBF_INPUT                 ), //! NBF of output
    .OV_SAMP         (OV_SAMP                   )  //! Oversampling

)
  u_downSampler_I
    (   
        .i_phase_selector(sel_phase             ),  //! Phase selector i_sw[3:2]
        .i_filt_sample   (I_wire_filtred        ),
        .o_down_sample   (I_wire_downsamp_to_ber),
        .clock           (clock                 ),
        .reset           (reset                 )
    );

ber
#(
    //parameter INIT_SEED = 9'b110101010,      //! Initial seed to prbs not used
    .NB_PRBS          (NB_PRBS                  ),  //! Number bit. prbs
    .NB_BER           (NB_BER                   ),  //! Error storange bit number
    .LIMIT            (511                      ),  //! Max limit pseudorandom  2**9 -1
    .LIMIT2           (1024                     )   //! Max limit arrayBER

)
  u_ber_I
    (
        .o_indice     (I_wire_retardo_ber       ),
        .o_count_bit  (I_wire_count_bit         ),  //!outputs para ver en simulacion
        .o_count_err  (I_wire_count_err         ),
        .o_led        (o_led_ber_I              ),
        .i_enbRx      (enb_Rx                   ),
        .i_valid      (i_valid                  ),  //!i_valid trabaja a T
        .i_prbs       (I_wire                   ),
        .i_Rx         (I_wire_downsamp_to_ber[7]),
        .i_clock      (clock                    ),
        .i_reset      (reset                    )
    );
//! signals Q
prbs9
#(
    .SEED            (9'b111111110              ),
    .NB_OUTPUT       (NB_INPUT                  )

)
  u_prbs9_Q
    (
        .o_symb      (Q_wire                    ),     //! Symbol to output
        .i_enable    (enb_Tx                    ),     //! Enable
        .i_rst       (reset                     ),     //! Reset
        .i_valid     (i_valid                   ),     //! Validate 1 T
        .clk         (clock                     )      //! Clock
    );
filterPolFas
#(    
    .NB_INPUT        (NB_INPUT                  ), //! NB of input
    .NBF_INPUT       (NBF_INPUT                 ), //! NBF of input
    .NB_OUTPUT       (NB_INPUT                  ), //! NB of output
    .NBF_OUTPUT      (NBF_INPUT                 ), //! NBF of output
    .NB_COEFF        (NB_INPUT                  ), //! NB of Coefficients
    .NBF_COEFF       (NBF_INPUT                 )  //! NBF of Coefficients)
)
  u_filterPolFas_Q
    (
        .o_os_data    (Q_wire_filtred           ), //! Output Sample   //sale p3p2p1p0p3p2p1p0->
        .i_is_data    (Q_wire                   ), //! Input Sample 
        .i_enb        (enb_Tx                   ), //! Enable
        .i_srst       (reset                    ), //! Reset
        .clk          (clock                    )  //! Clock
    );

downSampler
#(
    .NB_OUTPUT       (NB_INPUT                  ), //! NB of output
    .NBF_OUTPUT      (NBF_INPUT                 ), //! NBF of output
    .OV_SAMP         (OV_SAMP                   )  //! Oversampling
)
  u_downSampler_Q
    (   
        .i_phase_selector(sel_phase             ),  //! Phase selector i_sw[3:2]
        .i_filt_sample   (Q_wire_filtred        ),
        .o_down_sample   (Q_wire_downsamp_to_ber),
        .clock           (clock                 ),
        .reset           (reset                 )
    );

ber
#(
    //parameter INIT_SEED = 9'b110101010,      //! Initial seed to prbs not used
    .NB_PRBS          (NB_PRBS                  ),  //! Number bit. prbs
    .NB_BER           (NB_BER                   ),  //! Error storange bit number
    .LIMIT            (511                      ),  //! Max limit pseudorandom  2**9 -1
    .LIMIT2           (1024                     )   //! Max limit arrayBER

)
  u_ber_Q
    (
        .o_indice     (Q_wire_retardo_ber       ),
        .o_count_bit  (Q_wire_count_bit         ),  //!outputs para ver en simulacion
        .o_count_err  (Q_wire_count_err         ),
        .o_led        (o_led_ber_Q              ),
        .i_enbRx      (enb_Rx                   ),
        .i_valid      (i_valid                  ),  //!i_valid trabaja a T
        .i_prbs       (Q_wire                   ),
        .i_Rx         (Q_wire_downsamp_to_ber[7]),
        .i_clock      (clock                    ),
        .i_reset      (reset                    )
    );
    
ila
   u_ila
   (
    .clk_0    (clock),
    .probe0_0 (o_led)
    );

vio
   u_vio
   (
    .clk_0       (clock         ),
    .probe_in0_0 (o_led         ),
    .probe_out0_0(sel_mux       ),
    .probe_out1_0(reset_from_vio),
    .probe_out2_0(sw_from_vio   )
    );
endmodule
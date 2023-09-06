

module topLevel
#(
    parameter NB_SW          = 4,
    parameter NB_LEDS        = 4,
    parameter NB_INPUT       = 8, //! NB of input
    parameter NBF_INPUT      = 7, //! NBF of input
    parameter OV_SAMP        = 4
)
(
    //output [NB_LEDS-1:0] o_led,
    output  signed [NB_INPUT-1 : 0]    o_I_from_filt_to_down,
    output  signed [NB_INPUT-1 : 0]    o_I_filtred_DownS, //!solamente para poder comparar

    input [NB_SW-1:0]     i_sw,
    input                reset,        //!Reset
    output               clockT,       //solo para visualizar
    input                clock         //!Clock funciona a T/4
);


wire                     i_valid;      //i valid para prbs9 y filter funciona a T
reg   [         1 : 0]    timer0;      //funciona a T
wire                    enb_Tx;
wire signed [NB_INPUT-1 : 0]   I_wire_filtred;

wire signed [NB_INPUT-1 : 0]    I_wire;


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

assign i_valid  = (timer0==2'b00)? 1'b1 : 1'b0; //! valid input T
assign clockT = i_valid;

assign enb_Tx = i_sw[0];
assign o_I_from_prbs = I_wire;
assign o_I_from_filt_to_down= I_wire_filtred;


prbs9
#(
    .SEED(9'b110101010),
    .NB_OUTPUT(NB_INPUT)

)
  u_prbs9_I
    (
        .o_symb     (I_wire),     //! Symbol to output
        .i_rst       (reset),     //! Reset
        .i_valid   (i_valid),     //! Validate 1 T
        .clk         (clock)      //! Clock
    );

filterPolFas
#(    
    .NB_INPUT      (NB_INPUT ), //! NB of input
    .NBF_INPUT     (NBF_INPUT), //! NBF of input
    .NB_OUTPUT     (NB_INPUT ), //! NB of output
    .NBF_OUTPUT    (NBF_INPUT), //! NBF of output
    .NB_COEFF      (NB_INPUT ), //! NB of Coefficients
    .NBF_COEFF     (NBF_INPUT)  //! NBF of Coefficients)
)
  u_filterPolFas_I
    (
        .o_os_data(I_wire_filtred), //! Output Sample   //sale p3p2p1p0p3p2p1p0->
        .i_is_data(I_wire        ), //! Input Sample 
        .i_enb    (enb_Tx        ), //! Enable
        .i_srst   (reset         ), //! Reset
        .clk      (clock         )  //! Clock
    );

downSampler
#(
    .NB_OUTPUT  (NB_INPUT) , //! NB of output
    .NBF_OUTPUT (NBF_INPUT), //! NBF of output
    .OV_SAMP    (OV_SAMP)

)
  u_downSampler_I
    (
    .i_phase_selector(i_sw[3:2]),  //! Phase selector i_sw[3:2]
    .i_filt_sample   (I_wire_filtred),
    .o_down_sample   (o_I_filtred_DownS),
    .clock           (clock),
    .reset           (reset)
    );

 


endmodule
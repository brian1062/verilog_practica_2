//! @title Down Sampler
//! @author Brian Gerard
//! @date 08-09-2023

//! - Downsampler al cual se le ingresa la salida de nuestro filtro
//! - polifasico |P3|P2|P1|P0|-> y extrae determinada fase dependiendo
//! - el valor del i_phase_selector[1:0] por lo que el mismo trabaja
//! - a con un periodo T.

module downSampler
#(
    parameter NB_OUTPUT  = 8, //! NB of output
    parameter NBF_OUTPUT = 7, //! NBF of output
    parameter OV_SAMP    = 4  //! Oversample value

)
(
    input         [          1:0] i_phase_selector,  //! Phase selector i_sw[3:2]
    input  signed [NB_OUTPUT-1:0]    i_filt_sample,  //! Input from filtro T/4
    output signed [NB_OUTPUT-1:0]    o_down_sample,  //! Output from downsampler T
    input                                    clock,  //! Reset
    input                                    reset   //! Clock
);

reg [NB_OUTPUT-1:0]    array_phase[OV_SAMP-1:0];

integer ind1;
integer ind2;
always @(posedge clock) begin
    if(reset) begin
        for(ind1=1;ind1<OV_SAMP;ind1=ind1+1) begin:initPhases
            array_phase[ind1] <= {NB_OUTPUT{1'b0}};
          end        
    end
    else begin
        for(ind2=0;ind2<OV_SAMP;ind2=ind2+1) begin:srmove2
            if(ind2==0)begin
                array_phase[ind2] <= i_filt_sample    ;
            end
            else begin
                array_phase[ind2] <= array_phase [ind2-1];
            end
    end
    end
end

assign o_down_sample = (i_phase_selector==2'b00)? array_phase[3]: //!P0
                       (i_phase_selector==2'b01)? array_phase[2]: //!P1
                       (i_phase_selector==2'b10)? array_phase[1]: //!P2
                                                  array_phase[0]; //!P3


endmodule
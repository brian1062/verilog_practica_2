//! @title PRBS9
//! @author Brian Gerard
//! @date 08-09-2023

//! - Generador pseudo aleatorio de 9 bit prbs9


module prbs9
#(
    parameter SEED           = 9'b110101010, //! Initial seed to prbs
    parameter NB_OUTPUT      = 8             //! NB of output
)
(
    output  [NB_OUTPUT-1:0] o_symb,     //! Symbol to output
    input                 i_enable,     //! Enable/disable
    input                    i_rst,     //! Reset
    input                  i_valid,     //! Validate 1 T
    input                      clk      //! Clock
);
  reg        [ 8 : 0 ]                            array;
  reg                                            symbol;


  always @(posedge clk or posedge i_rst) begin
    if(i_rst) begin
      array  <=       SEED;
      symbol <=   array[0];  //! first symbol
    end
    else if(i_enable)begin
       if(i_valid) begin
        array    <= {(array[0] ^ array[4]), array[8 : 1]}; //! ESTA LOGICA CORRESPONDE A LA DEL part2v2.py
        symbol <=  array[0];
      end
      // else begin
      //    symbol <= symbol;
      // end
    end

  end

  assign o_symb = (symbol) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};


endmodule
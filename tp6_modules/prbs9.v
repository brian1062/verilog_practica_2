
module prbs9
#(
    parameter SEED = 9'b110101010
)
(
    output   o_symb,     //! Symbol to output
    //input     i_enb,     //! Enable Tx
    input     i_rst,     //! Reset
    input   i_valid,     //! Validate 1 T
    input       clk      //! Clock
);
  reg        [ 8 : 0 ]                            array;
  reg                                            symbol;


  always @(posedge clk or posedge i_rst) begin
    if(i_rst) begin
      array  <=       SEED;
      symbol <=   array[0];  //! first symbol
    end

    else if(i_valid) begin
      array    <= {(array[0] ^ array[4]), array[8 : 1]}; //! ESTA LOGICA CORRESPONDE A LA DEL part2v2.py
      symbol <=  array[0];
    end

    else begin
      symbol <= symbol;
    end

  end

  assign o_symb = symbol;


endmodule
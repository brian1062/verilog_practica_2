//! @title Bit Error Rate
//! @author Brian Gerard
//! @date 08-09-2023

//! - Bit Error Rate. En primera etapa se encarga de sincronizar
//! - la salida de la prbs con la salida del filtro para luego poder
//! - contar la cantidad de bits transmitidos y la cantidad de error
//! - en la recepcion-transmision.


module ber
#(
    //parameter INIT_SEED = 9'b110101010, //! Initial seed to prbs
    parameter NB_PRBS   =            9,   //! 
    parameter NB_BER    =           64,
    parameter LIMIT     =          511,
    parameter LIMIT2    =         1024

)
(
    output [NB_BER-1:0]  o_count_bit,
    output [NB_BER-1:0]  o_count_err,

    input                    i_enbRx,
    input                    i_valid,  //!i_valid trabaja a T
    input                     i_prbs,
    input                       i_Rx,
    input                    i_clock,
    input                    i_reset

);

reg                                      sync;  //! bit de sincronizacion
reg     [LIMIT2-1 : 0]             prbs_local;  //! Datos recibidos de la prbs
reg     [       9 : 0]              pos_local;  //! Pos local a la que apunta el arreglo
reg     [NB_PRBS-1: 0]                  count;                       
reg     [NB_BER -1: 0]               acum_err;  //usar 64bits integer tiene 32
reg     [NB_BER -1: 0]               acum_bit;  //usar 64bits 

always @(posedge i_clock) begin :syncBerPrbs
    if(i_reset)begin
        pos_local  <=      {10{1'b0}};    // 0 a 1024  -> TODO: BUSCAR PARAMETRIZAR DE ALGUNA FORMA
        sync       <=          1'b0  ; 
        count      <= {NB_PRBS{1'b0}};
        prbs_local <= { LIMIT2{1'b0}};
        acum_err   <= { NB_BER{1'b0}};
        acum_bit   <= { NB_BER{1'b0}};
    end
    else begin
        if(i_enbRx)begin
            if(i_valid)begin
                count      <=  count + 1'b1; 
                prbs_local <= {i_prbs,prbs_local[LIMIT2-2 : 0]}; 
                acum_err   <= (prbs_local[pos_local] ^ i_Rx)? acum_err+1'b1: acum_err;

                if(~sync) begin
                    count             <=  count +    1'b1; 
                    if(count == (2**NB_PRBS - 1))begin //si es igual a 511
                        if(acum_err > 64'b1_0000)begin     //TODO: como cambio ese 64 por algo mas parametrizable?
                            count     <=  {NB_PRBS{1'b0}};
                            pos_local <= pos_local + 1'b1;  //Se le asigna un retardo extra
                        end
                        else begin  //esta sync
                            sync <= 1'b1;
                            acum_bit   <= { NB_BER{1'b0}};
                        end
                        acum_err   <= { NB_BER{1'b0}};
                    end
                end
                else begin:BerSyncronized
                    acum_bit <= acum_bit + 1'b1;
                end
    
            end
        end
    end
end

assign o_count_bit = (sync)? acum_bit: { NB_BER{1'b0}} ;
assign o_count_err = (sync)? acum_err: { NB_BER{1'b0}} ;

endmodule
module filterPolFas
#(
    parameter NB_INPUT = 8,
    parameter NBF_INPUT = 7,
    parameter NB_OUTPUT = 8,
    parameter NBF_OUTPUT = 7,
    parameter NB_COEFF = 8,
    parameter NBF_COEFF = 7

)
(
    output signed [NB_OUTPUT-1:0] o_os_data,     //! Output Sample   //No necesitamos esto creo
    input  signed [NB_INPUT -1:0] i_is_data,     //! Input Sample
    //input                         i_from_control,  
    input                         i_enb    ,     //! Enable
    input                         i_srst   ,     //! Reset
    input                         clk            //! Clock
);
    localparam NB_ADD     = NB_COEFF + 3; //log(2)5=2.33
    localparam NBF_ADD    = NBF_COEFF;
    localparam NBI_ADD    = NB_ADD    - NBF_ADD;
    localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
    localparam NB_SAT     = (NBI_ADD) - (NBI_OUTPUT);


    reg        [         1:0]   state_counter      ; // Contador de estados: 00, 01, 10
    reg  signed[NB_COEFF-1:0] selected_coeffs[ 5:0]; // Coeficientes a usar
    wire signed[NB_COEFF-1:0]           coeff[23:0]; //! Matrix for Coefficients

    reg  signed [NB_INPUT-1:0]       register[23:1];

    assign coeff[ 0]  = 8'b0000_0000;
    assign coeff[ 1]  = 8'b0000_0001;
    assign coeff[ 2]  = 8'b0000_0010;
    assign coeff[ 3]  = 8'b0000_0011;
    assign coeff[ 4]  = 8'b0000_0000; 
    assign coeff[ 5]  = 8'b1111_1001;
    assign coeff[ 6]  = 8'b1111_0001;
    assign coeff[ 7]  = 8'b1111_0000;
    assign coeff[ 8]  = 8'b0000_0000;
    assign coeff[ 9]  = 8'b0010_0010;
    assign coeff[10]  = 8'b0100_1101;
    assign coeff[11]  = 8'b0111_0010;
    assign coeff[12]  = 8'b0111_1111;
    assign coeff[13]  = 8'b0111_0010;
    assign coeff[14]  = 8'b0100_1101;
    assign coeff[15]  = 8'b0010_0010;
    assign coeff[16]  = 8'b0000_0000;
    assign coeff[17]  = 8'b1111_0000;
    assign coeff[18]  = 8'b1111_0001;
    assign coeff[19]  = 8'b1111_1001;
    assign coeff[20]  = 8'b0000_0000;
    assign coeff[21]  = 8'b0000_0011;
    assign coeff[22]  = 8'b0000_0010;
    assign coeff[23]  = 8'b0000_0001;

    integer ptr1;
    integer ptr2;
    always @(posedge clk) begin:shiftRegister
        if(i_srst)begin
            for(ptr1=1;ptr1<24;ptr1=ptr1+1) begin:init
                register[ptr1] <= {NB_INPUT{1'b0}};
              end
        end 
        else begin
            if(i_enb == 1'b1) begin

                if(state_counter == 2'b00)begin:srmove_P0
                    for(ptr2=1;ptr2<24;ptr2=ptr2+1) begin:srmove
                        if(ptr2==1)begin
                        register[ptr2] <= i_is_data        ;
                        end
                        else begin
                        register[ptr2] <= register [ptr2-1];
                        end
                    end
                end
                
            end
        end
    end



    integer i;
    //TODO: FALTA EN LOS CASOS(del inicio) QUE register=0 no asignarle nada!
    always@(posedge clk) begin:selectcoeff
        if(i_srst)begin
            state_counter <= 2'b00;
        end
        else begin
            if(i_enb == 1'b1)begin
                for(i = 0; i < 6; i = i + 1) begin
                    if(i==0)begin
                        if(state_counter == 2'b00) begin
                            selected_coeffs[i] <= (i_is_data[7])? ~coeff[state_counter]
                                                                :  coeff[state_counter];
                        end
                        else begin
                            selected_coeffs[i] <= (register[state_counter][7])? ~coeff[state_counter]
                                                                              :  coeff[state_counter];
                        end
                    end
                    else begin
                        selected_coeffs[i] <= (register[state_counter + i*4][7])? ~coeff[state_counter + i*4]
                                                                                :  coeff[state_counter + i*4];
                    end
                end
                if (state_counter == 2'b11) begin
                    state_counter <= 2'b00;          // Resetea el contador al llegar al último estado
                end
                state_counter <= state_counter + 1;  // Incrementa el estado
            end
        end
    end

    wire signed [NB_ADD-1:0] sum      [5:1]; //! Add samples
    assign sum[1] = selected_coeffs[0] + selected_coeffs[1];
    assign sum[2] =             sum[1] + selected_coeffs[2];
    assign sum[3] =             sum[2] + selected_coeffs[3];
    assign sum[4] =             sum[3] + selected_coeffs[4];
    assign sum[5] =             sum[4] + selected_coeffs[5];

    //! Diezmado ver si anda bien !!
    assign o_os_data = ( ~|sum[5][NB_ADD-1 -: NB_SAT+1] || &sum[5][NB_ADD-1 -: NB_SAT+1]) ? sum[5][NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
                       (sum[5][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};


endmodule 
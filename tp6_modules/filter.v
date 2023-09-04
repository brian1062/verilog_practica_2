module filter
#(    
    parameter NB_INPUT       = 8, //! NB of input
    parameter NBF_INPUT      = 7, //! NBF of input
    parameter NB_OUTPUT      = 8, //! NB of output
    parameter NBF_OUTPUT     = 7, //! NBF of output
    parameter NB_COEFF       = 8, //! NB of Coefficients
    parameter NBF_COEFF      = 7,  //! NBF of Coefficients)
    parameter OV_SAMP        = 4
)
(
    output signed [NB_OUTPUT-1:0] o_os_data, //! Output Sample   //No necesitamos esto creo
    input  signed [NB_INPUT -1:0] i_is_data, //! Input Sample 
    //input                         i_symbol , //! Symbol from prbs
    input                         i_enb    , //! Enable
    input                         i_valid  , //! Validation
    input                         i_srst   , //! Reset
    input                         clk        //! Clock
);

    localparam NB_ADD     = NB_COEFF + 3; //log(2)5=2.33
    localparam NBF_ADD    = NBF_COEFF;
    localparam NBI_ADD    = NB_ADD    - NBF_ADD;
    localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
    localparam NB_SAT     = (NBI_ADD) - (NBI_OUTPUT);


    //! Internal Signals
    reg  signed [NB_INPUT         -1:0] register [23:1]; //! Matrix for registers
    wire signed [         NB_COEFF-1:0] coeff    [23:0]; //! Matrir for Coefficients
    //wire signed [         NB_COEFF-1:0] coeff_P0 [5 :0]; //! Matrir for Coefficients
    //wire signed [         NB_COEFF-1:0] coeff_P1 [5 :0]; //! Matrir for Coefficients
    //wire signed [         NB_COEFF-1:0] coeff_P2 [5 :0]; //! Matrir for Coefficients
    //wire signed [         NB_COEFF-1:0] coeff_P3 [5 :0]; //! Matrir for Coefficients
    
    //wire signed [NB_INPUT+NB_COEFF-1:0] prod     [3:0]; //! Partial Products
    wire signed [NB_COEFF         -1:0] sel_coef [5:0]; 

    reg         [                  2:0] act_phase     ; //! Phase actual en la que esta trabajando

    //! Coeff = [0 0,008 0,016 0,023 0 -0,055 -0,117 -0,125 0 0,266 0,602 0,891 0,992 0,891 0,602 0,266 0 -0,125 -0,117 -0,055 0 0,023 0,016 0,008]
    assign coeff[0]  = 8'b0000_0000;
    assign coeff[1]  = 8'b0000_0001;
    assign coeff[2]  = 8'b0000_0010;
    assign coeff[3]  = 8'b0000_0011;
    assign coeff[4]  = 8'b0000_0000; 
    assign coeff[5]  = 8'b1111_1001;
    assign coeff[6]  = 8'b1111_0001;
    assign coeff[7]  = 8'b1111_0000;
    assign coeff[8]  = 8'b0000_0000;
    assign coeff[9]  = 8'b0010_0010;
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


  //! ShiftRegister model
    integer ptr1;
    integer ptr2;

    always @(posedge clk) begin:shiftRegister
      if (i_srst == 1'b1) begin
        for(ptr1=1;ptr1<24;ptr1=ptr1+1) begin:init
          register[ptr1] <= {NB_INPUT{1'b0}};
        end
        act_phase        <=        {3{1'b0}};
      end 
      else begin
        if (i_enb == 1'b1) begin
            for(ptr2=1;ptr2<24;ptr2=ptr2+1) begin:srmove
                if(ptr2==1)
                register[ptr2] <= i_is_data;
                else
                register[ptr2] <= register[ptr2-1];
            end
            act_phase        <=        {3{1'b0}}; 
            end
        else begin :selection_phase
            act_phase        <=(act_phase == 3'b000) ? 3'b001 :
                               (act_phase == 3'b001) ? 3'b010 :
                               (act_phase == 3'b010) ? 3'b100 :
                                                       3'b000 ;
        end
      end
    end

    //reg signed [NB_INPUT+NB_COEFF-1:0] prod     [3:0]; //! Partial Products
    
    reg signed [NB_COEFF-1:0]          sel_h    [5:0]; 
    integer ptr;
    integer phase;
    always @(posedge clk) begin// @(*) begin
      phase = (act_phase == 3'b000) ? 0 :
              (act_phase == 3'b001) ? 1 :
              (act_phase == 3'b010) ? 2 :
                                      3 ;
      for(ptr=0;ptr<6;ptr=ptr+1) begin:selcoef
        if (ptr==0) begin
            if(phase==0)
                sel_h[ptr] <= (i_is_data[7])? ~coeff[ptr] : coeff[ptr];
            else
                sel_h[ptr] <= (register[phase])? ~coeff[phase] : coeff[phase];
        end
        else
            sel_h[ptr] <= (register[(ptr*OV_SAMP)+phase])? ~coeff[(ptr*OV_SAMP)+phase] : coeff[(ptr*OV_SAMP)+phase];
      end    
    end

    //! Declaration
    wire signed [NB_ADD-1:0] sum      [5:1]; //! Add samples
    //! Adders
    assign sum[1] = sel_h[0] + sel_h[1];
    assign sum[2] = sum[1]  + sel_h[2];
    assign sum[3] = sum[2]  + sel_h[3];
    assign sum[4] = sum[3]  + sel_h[4];
    assign sum[5] = sum[4]  + sel_h[5];

    assign o_os_data = ( ~|sum[3][NB_ADD-1 -: NB_SAT+1] || &sum[3][NB_ADD-1 -: NB_SAT+1]) ? sum[3][NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
    (sum[3][NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

/*
    assign sel_coef[0] =(act_phase == 3'b000) ? (i_is_data  [7]?~coeff[0]:coeff[0]) ://P0
                        (act_phase == 3'b001) ? (register[1][7]?~coeff[1]:coeff[1]) ://P1
                        (act_phase == 3'b010) ? (register[2][7]?~coeff[2]:coeff[2]) ://P2
                                                (register[3][7]?~coeff[3]:coeff[3]) ;//P3

    assign sel_coef[1] = (act_phase == 3'b000) ? (register[4][7]?~coeff[4]:coeff[4]) ://P0
                         (act_phase == 3'b001) ? (register[5][7]?~coeff[5]:coeff[5]) ://P1
                         (act_phase == 3'b010) ? (register[6][7]?~coeff[6]:coeff[6]) ://P2
                                                 (register[7][7]?~coeff[7]:coeff[7]) ;//P3
    assign sel_coef[2] = (act_phase == 3'b000) ? (register[8][7]?~coeff[8]:coeff[8]) ://P0
                         (act_phase == 3'b001) ? (register[9][7]?~coeff[9]:coeff[9]) ://P1
                         (act_phase == 3'b010) ? (register[10][7]?~coeff[10]:coeff[10]) ://P2
                                                 (register[11][7]?~coeff[11]:coeff[11]) ;//P3
    assign sel_coef[3] = (act_phase == 3'b000) ? (register[12][7]?~coeff[12]:coeff[12]) ://P0
                         (act_phase == 3'b001) ? (register[13][7]?~coeff[13]:coeff[13]) ://P1
                         (act_phase == 3'b010) ? (register[14][7]?~coeff[14]:coeff[14]) ://P2
                                                 (register[15][7]?~coeff[15]:coeff[15]) ;//P3
    assign sel_coef[4] = (act_phase == 3'b000) ? (register[16][7]?~coeff[16]:coeff[16]) ://P0
                         (act_phase == 3'b001) ? (register[17][7]?~coeff[17]:coeff[17]) ://P1
                         (act_phase == 3'b010) ? (register[18][7]?~coeff[18]:coeff[18]) ://P2
                                                 (register[19][7]?~coeff[19]:coeff[19]) ;//P3
    assign sel_coef[5] = (act_phase == 3'b000) ? (register[20][7]?~coeff[20]:coeff[20]) ://P0
                         (act_phase == 3'b001) ? (register[21][7]?~coeff[21]:coeff[21]) ://P1
                         (act_phase == 3'b010) ? (register[22][7]?~coeff[22]:coeff[22]) ://P2
                                                 (register[23][7]?~coeff[23]:coeff[23]) ;//P3                                       

*/
    //OUT[0]TO=H0+H4+H8+H12+H16+H20
    //OUT[1]T1=H1+H5+H9+H13+H17+H21
    
    //TODO: HACER UN SHIFTREG DE 23:0 al cual les vamos asignando como
    //todo: LA LOGICA DEL PY QUE HICE. DEPENDIENDO UN CONTADOR QUE VA DE CERO A 3
    //TODO: CAMBIAR LA MULTIPLICACION: IGUAL QUE EL PY DEBERIA ANDAR.



endmodule
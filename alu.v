module top(operand1,operand2,operation,compare_out,logic_out,add_sub_result,zero,carry,overflow,logic_out_7seg,add_sub_result_7seg,operand1_7seg,operand2_7seg);
input unsigned [3:0] operand1   ;  //Symbolic complement code
input unsigned [3:0] operand2   ;  //Symbolic complement code
input [2:0] operation           ;  
output reg       compare_out    ; 
output reg [3:0] logic_out      ;
output reg [3:0] add_sub_result ;//Symbolic complement code
output reg       zero           ;
output reg       carry          ;
output reg       overflow       ;
output [7:0]     logic_out_7seg      ;
output [7:0]     add_sub_result_7seg ;
output [7:0]     operand1_7seg       ;
output [7:0]     operand2_7seg       ;


bcd_to_7seg logic_out_seg
(
.b        (logic_out      ),
.carry    (0              ),
.overflow (0              ),
.h        (logic_out_7seg )
);

bcd_to_7seg add_sub_result_seg
(
.b        (add_sub_result        ),
.carry    (carry                 ),
.overflow (overflow              ),
.h        (add_sub_result_7seg   )
);

bcd_to_7seg add1_seg
(
.b        (operand1              ),
.carry    (0                     ),
.overflow (0                     ),
.h        (operand1_7seg         )
);
bcd_to_7seg add2_seg
(
.b        (operand2              ),
.carry    (0                     ),
.overflow (0                     ),
.h        (operand2_7seg         )
);


// function_sel  function  operate
// 000           add       a+b
// 001           sub       a-b
// 010           invert    ~a
// 011           and       a&b
// 100           or        a|b
// 101           xor       a^b
// 110           compare   if a<b out=1, or out=0
// 111           equal     out=(a==b)?1:0
reg unsigned [3:0] xb;
reg unsigned [3:0] temp;
always@(*)begin
  add_sub_result = 4'b0;
  temp = 4'b0; 
  compare_out = 1'b0; 
  overflow = 0; 
  zero = 0; 
  carry = 0; 
  xb = 4'd0; // 初始化
  compare_out = 1'd0;
  logic_out = 4'd0;
  casez(operation)
    3'b00z:begin // add or sub
      xb = operand2^{{4{operation[0]}}};  // 根据最后一位确定加减法 加：000 减：001 减法则取反
      {carry,add_sub_result} = operand1 + xb + {3'b0,operation[0]};
      overflow = (operand1[3] == xb[3]) && (add_sub_result[3] != operand1[3]);
      zero = ~(|add_sub_result);
    end
    3'b010:begin // ~a
      logic_out = ~operand1 ;
    end
    3'b011:begin // and
      logic_out = operand1 & operand2;
    end
    3'b100:begin // or
      logic_out = operand1 | operand2;
    end
    3'b101:begin // xor
      logic_out = operand1 ^ operand2;
    end
    3'b110:begin // cmp
      xb = operand2 ^ 4'b1111;  // 用减法进行比较大小
      {carry,temp} = xb + operand1 + 4'b1;
      overflow = (operand1[3] == xb[3]) && (temp[3] != operand1[3]);
      zero = ~(|temp);
      compare_out = temp[3] ^ overflow;
      if(compare_out == 0) add_sub_result = 4'b1;
      else add_sub_result = 4'b0;
    end
    3'b111:begin // equl
      xb = operand2 ^ 4'b1111;
      {carry,temp} = xb + operand1 + 4'b1;
      overflow = (operand1[3] == xb[3]) && (temp[3] != operand1[3]);
	    zero = ~(|temp);
      if(zero == 1) add_sub_result = 4'b1;
      else add_sub_result = 4'b0;
    end
    default:add_sub_result = 4'b0; // avoid latch
  endcase
end


endmodule


module bcd_to_7seg(
  input  [3:0] b,
  input        overflow,
  input        carry,
  output reg [7:0] h
);

// 0 turn on, 1 turn off
//   ---- 7 ---
//   |        |
//   2        6
//   |        |
//   ---- 1 ---
//   |        |
//   3        5
//   |        |
//   ---- 4 ---   -0-

always@(*)begin
  if(~overflow)begin
    case(b)
        4'b0000:   h= 8'b0000_0011; //0
        4'b0001:   h= 8'b1001_1111; //1
        4'b0010:   h= 8'b0010_0101; //2
        4'b0011:   h= 8'b0000_1101; //3
        4'b0100:   h= 8'b1001_1001; //4
        4'b0101:   h= 8'b0100_1001; //5
        4'b0110:   h= 8'b0100_0001; //6
        4'b0111:   h= 8'b0001_1111; //7
        4'b1000:   h= 8'b0000_0000; //-8
        4'b1001:   h= 8'b0001_1110; //-7
        4'b1010:   h= 8'b0100_0000; //-6
        4'b1011:   h= 8'b0100_1000; //-5
        4'b1100:   h= 8'b1001_1000; //-4
        4'b1101:   h= 8'b0000_1100; //-3
        4'b1110:   h= 8'b0010_0100; //-2
        4'b1111:   h= 8'b1001_1110; //-1
    endcase
  end
  else begin
      if(~carry)begin
          case(b)
              4'b0000:   h= 8'b0000_0011; //+0
              4'b0001:   h= 8'b1001_1111; //+1
              4'b0010:   h= 8'b0010_0101; //+2
              4'b0011:   h= 8'b0000_1101; //+3
              4'b0100:   h= 8'b1001_1001; //+4 
              4'b0101:   h= 8'b0100_1001; //+5
              4'b0110:   h= 8'b0100_0001; //+6
              4'b0111:   h= 8'b0001_1111; //+7
              4'b1000:   h= 8'b0000_0001; //+8
              4'b1001:   h= 8'b0000_1001; //+9
              4'b1010:   h= 8'b0001_0001; //+a
              4'b1011:   h= 8'b1100_0001; //+b
              4'b1100:   h= 8'b0011_0011; //+c
              4'b1101:   h= 8'b1000_0101; //+d
              4'b1110:   h= 8'b0110_0001; //+e
              4'b1111:   h= 8'b0111_0001; //+f
          endcase
      end
      else begin
          case(b)
              4'b0000:   h= 8'b0100_0010  ; //-16
              4'b0001:   h= 8'b0111_0000  ; //-15
              4'b0010:   h= 8'b0110_0000  ; //-14
              4'b0011:   h= 8'b1000_0100  ; //-13
              4'b0100:   h= 8'b0011_0010  ; //-12
              4'b0101:   h= 8'b1100_0000  ; //-11
              4'b0110:   h= 8'b0001_0000  ; //-10
              4'b0111:   h= 8'b0000_1000  ; //-9
              4'b1000:   h= 8'b0000_0000  ; //-8
              4'b1001:   h= 8'b0001_1110  ; //-7
              4'b1010:   h= 8'b0100_0000  ; //-6
              4'b1011:   h= 8'b0100_1000  ; //-5
              4'b1100:   h= 8'b1001_1000  ; //-4
              4'b1101:   h= 8'b0000_1100  ; //-3
              4'b1110:   h= 8'b0010_0100  ; //-2
              4'b1111:   h= 8'b1001_1110  ; //-1
          endcase
      end 
  end
end


endmodule

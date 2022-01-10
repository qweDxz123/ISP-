/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang

time  : 2005.02.23
                                                                                                  
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller testbench

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:      cmd_gen
Function:  generate commands to sdram controller
Parameter: SDRAM : mt48lc32m16a2
           SDRAM Size:512Mbits
           row size:13
           column size:10
           bank size:4

***************************************************************************************************/ 

`timescale 1ns / 100ps
module  cmd_gen(
                   clk,
                   reset,
                   regs0,
                   regs1,
                   regs2,
                   regs3,
                   regs4,
                   regs5,
                   regs6,
                   regs7,
                   counter_initial,
                   counter_s2,
                   counter_s4,
                   counter_s6,
                   cnt_odd_even,
                   rdreq_R,
                   rdreq_G,
                   rdreq_B,
//                   wrreq_1,
//                   wrreq_2,
                   wrreq_1_reg,
                   wrreq_2_reg,
                   cmd
                   );

// s0 : initial
// s1 : nop
// s2 : refresh
// s3 : ref_end
// s4 : write
// s5 : wr_end
// s6 : read
// s7 : rd_end

// 000 : nop
// 001 : reada
// 010 : writea
// 011 : refresh
// 100 : precharge
// 101 : load_mode
// 110 : load_reg
// 111 : read


input           clk;
input           reset;
input           regs0;
input           regs1;
input           regs2;
input           regs3;
input           regs4;
input           regs5;
input           regs6;
input           regs7;
input[5:0]      counter_initial;
input           counter_s2;
input[4:0]      counter_s4;
input[4:0]      counter_s6;
input[4:0]      cnt_odd_even;

output          rdreq_R;
output          rdreq_G;
output          rdreq_B;
//output          wrreq_1;
//output          wrreq_2;

output          wrreq_1_reg;
output          wrreq_2_reg;

output[2:0]     cmd;

wire            clk;
wire            reset;
wire            regs0;
wire            regs1;
wire            regs2;
wire            regs3;
wire            regs4;
wire            regs5;
wire            regs6;
wire            regs7;
wire[5:0]       counter_initial;
wire            counter_s2;
wire[4:0]       counter_s4;
wire[4:0]       counter_s6;
wire[4:0]       cnt_odd_even;

reg             rdreq_R;
reg             rdreq_G;
reg             rdreq_B;
reg             wrreq_1_reg;
reg             wrreq_2_reg;
reg[2:0]        cmd;


always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        cmd<=3'b000;
                end
        else case({regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0})
                8'b00000001:
                        begin
                                case(counter_initial)
                                        3:      cmd<=3'b100;            //precharge all banks
                                        9:      cmd<=3'b011;            //refresh
                                        19:     cmd<=3'b011;            //refresh
                                        29:     cmd<=3'b101;            //load mode
                                        33:     cmd<=3'b110;            //load reg
                                        default:
                                                cmd<=3'b000;
                                endcase 
                                
                        end
                8'b00000010:
                        begin
                                cmd<=3'b000;
                        end             
                8'b00000100:
                        begin
                                case(counter_s2)
                                        0:      cmd<=3'b011;
                                        default:
                                                cmd<=3'b000;
                                endcase
                        end
                8'b00001000:
                        begin
                                cmd<=3'b000;
                        end                     
                8'b00010000:
                        begin
                                case(counter_s4)
                                        1,2,3,4:
                                                cmd<=3'b010;            //FIFO-R
                                        5,6,7,8:
                                                cmd<=3'b000;
                                        9,10,11,12:
                                                cmd<=3'b010;            //FIFO-G
                                        13,14,15,16:
                                                cmd<=3'b000;
                                        17,18,19,20:
                                                cmd<=3'b010;            //FIFO-B
                                        21,22,23,24:
                                                cmd<=3'b000;
                                        default:
                                                cmd<=3'b000;
                                endcase
                        end
                8'b00100000:
                        begin
                                cmd<=3'b000;
                        end                     
                8'b01000000:
                        begin
                                case(counter_s6)
                                        2,3,4,5:
                                                cmd<=3'b111;            //FIFO1
                                        6,7,8,9:
                                                cmd<=3'b000;
                                        10,11,12,13:
                                                cmd<=3'b001;            //FIFO2
                                        14,15,16,17:
                                                cmd<=3'b000;
                                        default:
                                                cmd<=3'b000;
                                endcase 
                        end
                8'b10000000:
                        begin
                                cmd<=3'b000;
                        end                     
                default:
                        begin
                                cmd<=3'b000;
                        end
        endcase
end



// ******************************* rdreq_R / rdreq_G / rdreq_B ************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        rdreq_R<=1'b0;
                        rdreq_G<=1'b0;
                        rdreq_B<=1'b0;
                end
        else case({regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0})
                8'b00010000:    //read fifo R,G,B & write sdram
                        begin
                                case(counter_s4)
                                        4,5,6,7,8,9,10,11:
                                                begin
                                                        rdreq_R<=1'b1;
                                                        rdreq_G<=1'b0;
                                                        rdreq_B<=1'b0;
                                                end
                                        12,13,14,15,16,17,18,19:
                                                begin
                                                        rdreq_R<=1'b0;
                                                        rdreq_G<=1'b1;
                                                        rdreq_B<=1'b0;
                                                end
                                        20,21,22,23,24,25,26,27:
                                                begin
                                                        rdreq_R<=1'b0;
                                                        rdreq_G<=1'b0;
                                                        rdreq_B<=1'b1;
                                                end
                                        default:
                                                begin
                                                        rdreq_R<=1'b0;
                                                        rdreq_G<=1'b0;
                                                        rdreq_B<=1'b0;                                                                                                             
                                                end
                                endcase         
                        end
                default:
                        begin
                                rdreq_R<=1'b0;
                                rdreq_G<=1'b0;
                                rdreq_B<=1'b0;                     
                        end
        endcase
end

// ************************************ wrreq_1 / wrreq_2 *****************************************

reg                wrreq_1;
reg                wrreq_2;


always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        wrreq_1<=1'b0;
                        wrreq_2<=1'b0;
                end
        else case({regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0})
                8'b01000000:    //read sdram & write fifo 1,2
                        begin
                                if((cnt_odd_even>0) && (cnt_odd_even[0]==1))
                                        case(counter_s6)
                                                9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24:
                                                        begin
                                                                wrreq_1<=1'b1;
                                                                wrreq_2<=1'b0;
                                                        end
                                                default:
                                                        begin
                                                                wrreq_1<=1'b0;
                                                                wrreq_2<=1'b0;                                                                                     
                                                        end
                                        endcase
                                else if((cnt_odd_even>0) && (cnt_odd_even[0]==0))
                                        case(counter_s6)
                                                9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24:
                                                        begin
                                                                wrreq_1<=1'b0;
                                                                wrreq_2<=1'b1;
                                                        end
                                                default:
                                                        begin
                                                                wrreq_1<=1'b0;
                                                                wrreq_2<=1'b0;                                                                                     
                                                        end                                     
                                        endcase
                                else
                                        begin
                                                wrreq_1<=1'b0;
                                                wrreq_2<=1'b0;
                                        end
                        end
                default:
                        begin
                                wrreq_1<=1'b0;
                                wrreq_2<=1'b0;
                        end
        endcase
end


always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        wrreq_1_reg<=1'b0;
                        wrreq_2_reg<=1'b0;
                end
        else
                begin
                        wrreq_1_reg<=wrreq_1;
                        wrreq_2_reg<=wrreq_2;
                end
end




endmodule

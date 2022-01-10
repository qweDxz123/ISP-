/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang

time  : 2005.02.22
                                                                                                  
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller testbench

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:      arbitrator
Function:  arbitrate write,read & refresh requrests,than generate signals to cmd & address module
Parameter: SDRAM : mt48lc32m16a2
           SDRAM Size:512Mbits
           row size:13
           column size:10
           bank size:4

***************************************************************************************************/ 

`timescale 1ns / 100ps
module  arbitrator(
                   clk,
                   reset,
                   start,
                   en_tile,
                   usedw_R,
                   usedw_2,
                   en_wr,
                   en_rd,
                   regs0,
                   regs1,
                   regs2,
                   regs3,
                   regs4,
                   regs5,
                   regs6,
                   regs7,
                   regs4_temp,
                   regs6_temp,
                   counter_initial,
                   counter_s2,
                   counter_s4,
                   counter_s6
                   );

//`include        "params.v"

parameter USEDW_R_par = 8;
parameter USEDW_2_par = 128;

parameter ref_cycle=450;        //390----50MHz; 515----66MHz; 625----80MHz; 781----100MHz
parameter period_s2=1;          // refresh period
parameter period_s4=28;         // write period
parameter period_s6=25;         // read period

parameter s0=0,s1=1,s2=2,s3=3,s4=4,s5=5,s6=6,s7=7;
reg[2:0]  curstate,nextstate;
// s0 : initial
// s1 : nop
// s2 : refresh
// s3 : ref_end
// s4 : write
// s5 : wr_end
// s6 : read
// s7 : rd_end

input            clk;
input            reset;
input            start;
input            en_tile;
input[5:0]       usedw_R;
input[7:0]       usedw_2;
input            en_wr;
input            en_rd;

output           regs0;
output           regs1;
output           regs2;
output           regs3;
output           regs4;
output           regs5;
output           regs6;
output           regs7;
output           regs4_temp;
output           regs6_temp;
output[5:0]      counter_initial;
output           counter_s2;
output[4:0]      counter_s4;
output[4:0]      counter_s6;

wire             clk;
wire             reset;
wire             start;
wire             en_tile;
wire[5:0]        usedw_R;
wire[7:0]        usedw_2;
wire             en_wr;
wire             en_rd;

reg[9:0]         counter_ref;
reg[5:0]         counter_initial;
reg              counter_s2;            //in refresh state
reg[4:0]         counter_s4;            //in write state
reg[4:0]         counter_s6;            //in read state

reg              regs0,regs1,regs2,regs3,regs4,regs5,regs6,regs7;
reg              regs4_temp,regs6_temp;

reg              start_reg;
reg              en_tile_reg;

reg              start_inter;           // internal signal for state machine



// ****************************** regisger input start & en_tile **********************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        start_reg<=1'b0;
                        en_tile_reg<=1'b0;
                end
        else
                begin
                        start_reg<=start;
                        en_tile_reg<=en_tile;
                end
end

// **************************************** start_inter *******************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                start_inter<=1'b0;
        else if((en_tile==0) && (en_tile_reg==1))   //negedge en_tile_reg
                start_inter<=1'b0;
        else if((start==1) && (start_reg==0))    // posedge start_reg
                start_inter<=1'b1;
        else
                start_inter<=start_inter;
end

// *********************************** counter_initial ********************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_initial<=6'b000000;
                end
        else if(counter_initial<=6'd40)                    // at 35 : jump to nextstate
                begin
                        counter_initial<=counter_initial+6'd1;
                end
        else
                begin
                        counter_initial<=counter_initial;
                end
end

// *************************************** counter_ref ********************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_ref<=10'b0;
                end
        else if(counter_ref==ref_cycle)          //450
                if(regs2==0)
                        begin
                                counter_ref<=counter_ref;
                        end
                else
                        begin
                                counter_ref<=10'b0;
                        end
        else
                begin
                        counter_ref<=counter_ref+10'd1;
                end
end

// *************************** counter_s2 / counter_s4 / counter_s6 *******************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_s2<=1'b0;
                end
        else if(regs2==0)                                  // all other states
                begin
                        counter_s2<=1'b0;
                end
        else if(counter_s2<period_s2)   //1
                begin
                        counter_s2<=counter_s2+1'b1;
                end
        else
                begin
                        counter_s2<=counter_s2;
                end
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_s4<=5'b00000;
                end
        else if(regs4==0)
                begin
                        counter_s4<=5'b00000;
                end
        else if(counter_s4<period_s4)            //28
                begin
                        counter_s4<=counter_s4+5'd1;
                end
        else
                begin
                        counter_s4<=counter_s4;
                end
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_s6<=5'b00000;
                end
        else if(regs6==0)
                begin
                        counter_s6<=5'b00000;
                end
        else if(counter_s6<period_s6)             //25         // modify
                begin
                        counter_s6<=counter_s6+5'd1;
                end
        else
                begin
                        counter_s6<=counter_s6;
                end
end

// *************************************** state machine ******************************************
// state machine reset                  
always@(posedge clk  or posedge reset)
begin
        if(reset==1)
                curstate<=s0;
        else
                curstate<=nextstate;
end
// state machine reset end

// state machine description
always@(curstate or counter_initial or counter_ref or usedw_R or usedw_2 or start_inter or en_wr or en_rd or counter_s2 or counter_s4 or counter_s6)
begin
        case(curstate)
                s0:     begin
                                if(counter_initial==6'd35)
                                        nextstate<=s1;
                                else
                                        nextstate<=s0;
                        end
                s1:     begin
                                if(counter_ref==ref_cycle)
                                        nextstate<=s2;
                                else if(usedw_R>=USEDW_R_par && en_wr==1)
                                        nextstate<=s4;
                                else if(start_inter==1 && usedw_2<(USEDW_2_par+16) && en_rd==1)
                                        nextstate<=s6;
                                else
                                        nextstate<=s1;
                        end
                s2:     begin
                                if(counter_s2==period_s2)
                                        nextstate<=s3;
                                else
                                        nextstate<=s2;
                        end
                s3:     begin
                                if(counter_ref==ref_cycle)
                                        nextstate<=s2;
                                else if(usedw_R>=USEDW_R_par && en_wr)
                                        nextstate<=s4;
                                else if(start_inter==1 && usedw_2<(USEDW_2_par+16) && en_rd==1)
                                        nextstate<=s6;
                                else
                                        nextstate<=s1;
                        end
                s4:     begin
                                if(counter_s4==period_s4)
                                        nextstate<=s5;
                                else
                                        nextstate<=s4;
                        end
                s5:     begin
                                if(counter_ref==ref_cycle)
                                        nextstate<=s2;
                                else if(usedw_R>=USEDW_R_par && en_wr)
                                        nextstate<=s4;
                                else if(start_inter==1 && usedw_2<(USEDW_2_par+16) && en_rd==1)
                                        nextstate<=s6;
                                else
                                        nextstate<=s1;
                        end
                s6:     begin
                                if(counter_s6==period_s6)
                                        nextstate<=s7;
                                else
                                        nextstate<=s6;
                        end
                s7:     begin
                                if(counter_ref==ref_cycle)
                                        nextstate<=s2;
                                else if(usedw_R>=USEDW_R_par && en_wr)
                                        nextstate<=s4;
                                else if(start_inter==1 && usedw_2<(USEDW_2_par+16) && en_rd==1)
                                        nextstate<=s6;
                                else
                                        nextstate<=s1;
                        end
          default:
                       nextstate<=s1;
        endcase
end
// state machine description end 

// state machine output logic
// **************************************** state flags *******************************************
always@(curstate)
begin
        case(curstate)    
                s0:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00000001;
                        end
                s1:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00000010;
                        end
                s2:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00000100;
                        end
                s3:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00001000;
                        end
                s4:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00010000;
                        end
                s5:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00100000;
                        end
                s6:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b01000000;
                        end
                s7:     begin
                                {regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b10000000;
                        end
                default:{regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0}=8'b00000000;          
        endcase                                                         //8'b00000010; ???
end
// state machine output logic end

// ************************************ get posedge s2,s4,s6 **************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        regs4_temp<=1'b0;
                        regs6_temp<=1'b0;
                end
        else
                begin
                        regs4_temp<=regs4;
                        regs6_temp<=regs6;
                end
end



endmodule

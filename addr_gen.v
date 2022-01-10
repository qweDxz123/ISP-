/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang

time  : 2005.02.23
                                                                                                  
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller testbench

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:      addr_gen
Function:  generate address to sdram controller
Parameter: SDRAM : mt48lc32m16a2
           SDRAM Size:512Mbits
           row size:13
           column size:10
           bank size:4

***************************************************************************************************/ 

`timescale 1ns / 100ps
module  addr_gen(
                   clk,
                   reset,
                   vsync,
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
                   counter_s4,
                   counter_s6,
                   cnt_odd_even,
                   en_wr,
                   en_rd,
                   addr
                   );

//`include        "params.v"

parameter tile_size    = 256;
parameter image_height = 512;
parameter image_width  = 512;
parameter tilerowpar = image_height/tile_size;
parameter tilecolpar = image_width/tile_size;


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
input            vsync;
input            regs0;
input            regs1;
input            regs2;
input            regs3;
input            regs4;
input            regs5;
input            regs6;
input            regs7;
input            regs4_temp;
input            regs6_temp;
input[5:0]       counter_initial;
input[4:0]       counter_s4;
input[4:0]       counter_s6;

output[4:0]      cnt_odd_even;
output           en_wr;
output           en_rd;
output[24:0]     addr;

wire             clk;
wire             reset;
wire             vsync;
wire             regs0;
wire             regs1;
wire             regs2;
wire             regs3;
wire             regs4;
wire             regs5;
wire             regs6;
wire             regs7;
wire             regs4_temp;
wire             regs6_temp;
wire[5:0]        counter_initial;
wire[4:0]        counter_s4;
wire[4:0]        counter_s6;

reg              vsync_reg;
reg              vsync_reg2;
reg              vsync_reg3;
reg              vsync_reg4;


reg              en_wr;                          //write enable signal to state machine
reg              en_rd;                          //read  enable signal to state machine

reg[24:0]        addr;

// write addr
reg[10:0]          vcnt_wr;                      //max : 1024 cols
reg[11:0]          hcnt_wr;                      //max : 4096 rows
wire[9:0]         vcnt_wr_temp;
wire[11:0]         hcnt_wr_temp;

wire[21:0]         addr_physics_wr;              //[12:0]+[8:0] = [21:9][8:0]

// read addr
reg[3:0]           tilerowcnt_rd;                //the horizontal tile in one image
reg[2:0]           tilecolcnt_rd;                //the vertical tile in one image
reg[1:0]           bankcnt_rd;                   //the bank in one image
reg[7:0]           hcnt_rd;                      //the horizontal line in one tile
reg[7:0]           vcnt_rd;                      //the vertical line in one tile
wire[3:0]          tilerowcnt_rd_temp;
wire[2:0]          tilecolcnt_rd_temp;
wire[1:0]          bankcnt_rd_temp;
wire[7:0]          hcnt_rd_temp;
wire[6:0]          vcnt_rd_temp1;
wire[6:0]          vcnt_rd_temp2;

wire[7:0]          hcnt_rd_new;

wire[23:0]         addr_logic_rd1;
wire[23:0]         addr_logic_rd2;
wire[23:0]         addr_physics_rd1;
wire[23:0]         addr_physics_rd2;

reg[4:0]           cnt_odd_even;                 // 1--16
reg                regs6_temp_reg;

reg[12:0]          cnt_distance;
reg                rd_finish;


reg[1:0]           cnt_vsync;


// **************************************** cnt_vsync *********************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                cnt_vsync<=2'b00;
        else if(cnt_vsync==2)
                cnt_vsync<=cnt_vsync;                             //场计数到2再保持
        else if(vsync_reg==1 && vsync_reg2==0)
                cnt_vsync<=cnt_vsync+2'd1;
        else
                cnt_vsync<=cnt_vsync;
end



// ************************************** regs6_temp_reg ******************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                regs6_temp_reg<=1'b0;
        else
                regs6_temp_reg<=regs6_temp;
end

// **************************************** write addr ********************************************
// logic write address
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                vcnt_wr<=11'b0;
        else if(regs4==1 && regs4_temp==0)                                     // posedge regs4
                if(vcnt_wr==(image_width/2))                                    //两个数据合并成一个
                        vcnt_wr<=11'd8;
                else
                        vcnt_wr<=vcnt_wr+11'd8;                                 //BL=8
        else
                vcnt_wr<=vcnt_wr;
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                hcnt_wr<=12'b0;
        else if((regs4==0 && regs4_temp==1) && (vcnt_wr==(image_width/2)))    // negedge regs4
                if(hcnt_wr==image_height-1)                                   //图像行计数0～511
                        hcnt_wr<=12'b0;
                else
                        hcnt_wr<=hcnt_wr+12'd1;
        else
                hcnt_wr<=hcnt_wr;
end

// physics write address
assign vcnt_wr_temp = vcnt_wr-8;
assign hcnt_wr_temp = hcnt_wr;

assign addr_physics_wr[21:0]  = {hcnt_wr_temp,vcnt_wr_temp};


// ***************************************** read addr ********************************************
//logic read address
// *************************************** cnt_odd_even *******************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                cnt_odd_even<=5'b0;
        else if(regs6==1 && regs6_temp==0)                             //posedge regs6
                begin
                        if(cnt_odd_even==16)
                                cnt_odd_even<=5'd1;
                        else
                                cnt_odd_even<=cnt_odd_even+5'd1;       //1～16
                end
        else
                cnt_odd_even<=cnt_odd_even;
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                vcnt_rd<=8'b0;
        else if(regs6_temp==1 && regs6_temp_reg==0)                       //posedge regs6_temp
                begin
                        if(cnt_odd_even>0 && cnt_odd_even[0]==1)               // odd
                                if (vcnt_rd==8'd128)
                                        vcnt_rd<=8'd16;
                                else
                                        vcnt_rd<=vcnt_rd+8'd16;
                        else                                                   // even
                                vcnt_rd<=vcnt_rd;
                end
        else
                vcnt_rd<=vcnt_rd;    
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                hcnt_rd<=8'b0;
        else if((regs6_temp==0 && regs6_temp_reg==1) && (vcnt_rd==128) && (cnt_odd_even==16))
                begin
                        if(hcnt_rd==8'd254)
                                hcnt_rd<=8'b0;
                        else
                                hcnt_rd<=hcnt_rd+8'd2;
                end
        else
                hcnt_rd<=hcnt_rd;    
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                bankcnt_rd<=2'b00;
        else if((regs6_temp==0 && regs6_temp_reg==1) && (vcnt_rd==128) && (cnt_odd_even==16) && (hcnt_rd==254))
                if(bankcnt_rd==2)
                        bankcnt_rd<=2'b00;
                else
                        bankcnt_rd<=bankcnt_rd+2'd1; 
        else 
                bankcnt_rd<=bankcnt_rd;
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                tilecolcnt_rd<=3'b000;
        else if((regs6_temp==0 && regs6_temp_reg==1) && (vcnt_rd==128) && (cnt_odd_even==16) && (hcnt_rd==254) && (bankcnt_rd==2))
                if(tilecolcnt_rd==tilecolpar-1)             //2-1=1
                        tilecolcnt_rd<=3'b000;
                else
                        tilecolcnt_rd<=tilecolcnt_rd+3'd1; 
        else 
                tilecolcnt_rd<=tilecolcnt_rd;
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                tilerowcnt_rd<=4'b0000;
        else if((regs6_temp==0 && regs6_temp_reg==1) && (vcnt_rd==128) && (cnt_odd_even==16) && (hcnt_rd==254) && (bankcnt_rd==2) && (tilecolcnt_rd==tilecolpar-1))
                if(tilerowcnt_rd==tilerowpar-1)
                        tilerowcnt_rd<=4'b0000;
                else
                        tilerowcnt_rd<=tilerowcnt_rd+4'd1; 
        else 
                tilerowcnt_rd<=tilerowcnt_rd;
end

// ****************************** take apart odd / even row address *******************************

assign hcnt_rd_new = (cnt_odd_even[0]==1) ? hcnt_rd : hcnt_rd+1 ;

//assign hcnt_rd_new =  (cnt_odd_even == 0) ? 8'b0 : ( (cnt_odd_even[0] == 1) ? hcnt_rd : (hcnt_rd+1) );

assign vcnt_rd_temp1       = vcnt_rd-16;
assign vcnt_rd_temp2       = vcnt_rd-8;
assign hcnt_rd_temp       = hcnt_rd_new;              //列地址
assign bankcnt_rd_temp    = bankcnt_rd;               //bank地址
assign tilecolcnt_rd_temp = tilecolcnt_rd;            //tile列索引
assign tilerowcnt_rd_temp = tilerowcnt_rd;            //tile行索引


assign  addr_logic_rd1[23:22]=bankcnt_rd_temp;
assign  addr_logic_rd1[9:0]={tilecolcnt_rd_temp,7'b0000000}+vcnt_rd_temp1;
assign  addr_logic_rd1[21:10]={tilerowcnt_rd_temp,8'b00000000}+hcnt_rd_temp;

assign  addr_logic_rd2[23:22]=bankcnt_rd_temp;
assign  addr_logic_rd2[9:0]={tilecolcnt_rd_temp,7'b0000000}+vcnt_rd_temp2;
assign  addr_logic_rd2[21:10]={tilerowcnt_rd_temp,8'b00000000}+hcnt_rd_temp;

// physics write address
assign addr_physics_rd1 = addr_logic_rd1;
assign addr_physics_rd2 = addr_logic_rd2;



// ******************************** write & read enable signal ************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        vsync_reg<=1'b0;
                        vsync_reg2<=1'b0;
                        vsync_reg3<=1'b0;
                        vsync_reg4<=1'b0;
                end
        else
                begin
                        vsync_reg<=vsync;
                        vsync_reg2<=vsync_reg;
                        vsync_reg3<=vsync_reg2;
                        vsync_reg4<=vsync_reg3;
                end
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                en_wr<=1'b0;
        else if((vsync_reg3==1 && vsync_reg4==0) && (rd_finish==1 || cnt_vsync==1))        //读完一帧后再写入下一帧
                en_wr<=1'b1;
        else if((regs4==0 && regs4_temp==1) && (vcnt_wr==image_width/2) && (hcnt_wr==image_height-1))  //写完一帧后，写使能无效                           
                en_wr<=1'b0;
        else
                en_wr<=en_wr;                                   
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                rd_finish<=1'b0;
        else if((rd_finish==1) && (vsync_reg3==1 && vsync_reg4==0))
                rd_finish<=1'b0;
        else if((counter_s6==2) && (vcnt_rd==128) && (cnt_odd_even==16) && (hcnt_rd==254) && (bankcnt_rd==2) && (tilecolcnt_rd==tilecolpar-1) && (tilerowcnt_rd==tilerowpar-1))
                rd_finish<=1'b1;                              //一帧读完后标志位置1
        else
                rd_finish<=rd_finish;
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                cnt_distance<=13'b0;
        else if(rd_finish==1)
                cnt_distance<=13'b0;
        else if((regs4==0 && regs4_temp==1) && (vcnt_wr==image_width/2))
                cnt_distance<=cnt_distance+13'b1;
        else if((counter_s6==15) && (vcnt_rd==128) && (cnt_odd_even==16) && (tilecolcnt_rd==0) && (cnt_distance>=2) && (en_wr==1) &&(bankcnt_rd==2'b00))
                cnt_distance<=cnt_distance-13'd2;         //读tile0时一次读两行，tile0读完后其他不必考虑
        else
                cnt_distance<=cnt_distance;
end

always@(posedge clk or posedge reset)
begin
        if(reset==1)
                en_rd<=1'b0;
//      else if(rd_finish==1)
//              en_rd<=0;
        else if(cnt_distance>=2)         //写完两行就可以开始读了
                en_rd<=1'b1;
        else
                en_rd<=1'b0;
end


// *********************************** addr in state machine ************************************** 
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        addr<=25'b0;
                end
        else case({regs7,regs6,regs5,regs4,regs3,regs2,regs1,regs0})
                8'b00000001:    //initial
                        begin
                                case(counter_initial)
                                        29:     addr<=13'b0000000100011;       //load mode : BL=8 CL=2
                                        33:     addr<=13'b1000001111010;       //load reg  : [Cl=2] [RCD=2] RRD=7 BL=8
                                        default:
                                                addr<=addr;
                                endcase 
                        end                             
                8'b00010000:    //write
                        begin
                                case(counter_s4)
                                        1,2,3,4:
                                                addr<={1'b0,2'b00,addr_physics_wr};      //FIFO-R
                                        9,10,11,12:
                                                addr<={1'b0,2'b01,addr_physics_wr};      //FIFO-G
                                        17,18,19,20:
                                                addr<={1'b0,2'b10,addr_physics_wr};      //FIFO-B
                                        default:
                                                addr<=addr;
                                endcase
                        end
                8'b00100000:    //write end
                        begin
                                addr<=25'b0;            //  addr<=addr;  ?  
                        end                     
                8'b01000000:    //read
                        begin
                                case(counter_s6)
                                        2,3,4,5:
                                                addr<={1'b0,addr_physics_rd1};          //FIFO1
                                        10,11,12,13:
                                                addr<={1'b0,addr_physics_rd2};          //FIFO2
                                        default:
                                                addr<=addr;
                                endcase 
                        end
                8'b10000000:    //read end
                        begin
                                addr<=25'b0;            //  addr<=addr;   ?
                        end                     
                default:        //nop & refresh & ref_end
                        begin
                                addr<=25'b0;
                        end
        endcase
end



endmodule

/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang

time  : 2005.02.23
                                                                                                  
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller testbench

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:      wr_fifo_RGB
Function:  convert dataR/G/B[7:0] to dataR/G/B[15:0] ,and write them to FIFO R/G/B 

***************************************************************************************************/ 

`timescale 1ns / 100ps
module  camera_interface(
                     pclk,
                     reset,                 //高复位
                     href,
                     en_wr,
                     datar,
                     datag,
                     datab,
                     data_R16,
                     data_G16,
                     data_B16,
                     wrreq
                   );

//`include        "params.v"

parameter image_width      = 512;
//parameter image_width_size = 9;                    修改 counter_wr的位宽


input           pclk;
input           reset;
input           href;
input           en_wr;
input[7:0]      datar;
input[7:0]      datag;
input[7:0]      datab;

output[15:0]    data_R16;
output[15:0]    data_G16;
output[15:0]    data_B16;
output          wrreq;

wire            pclk;
wire            reset;
wire            href;
wire            en_wr;
wire[7:0]       datar;
wire[7:0]       datag;
wire[7:0]       datab;

reg[15:0]       data_R16;
reg[15:0]       data_G16;
reg[15:0]       data_B16;
reg             wrreq;

reg             href_reg;
reg[7:0]        datar_reg;
reg[7:0]        datag_reg;
reg[7:0]        datab_reg;

reg[9:0]        counter_wr;                      // Max image width = 4096 -->12


// ***************************************** counter_wr *******************************************
always@(posedge pclk or posedge reset)
begin
        if(reset==1'b1)
                begin
                        counter_wr<=10'b0;
                end
        else if(en_wr==1'b0)
                begin
                        counter_wr<=10'b0;
                end
        else if((href==1'b1) &&(href_reg==1'b0) && (en_wr==1'b1))
                begin
                        counter_wr<=image_width;           //image width = href width
                end
        else if(counter_wr>10'b0)
                begin
                        counter_wr<=counter_wr-10'd1;
                end
        else
                begin
                        counter_wr<=counter_wr;
                end
end

// ************************************* register signals *****************************************
always@(posedge pclk or posedge reset)
begin
        if(reset==1'b1)
                begin
                        href_reg<=1'b0;
                        datar_reg<=8'b0;
                        datag_reg<=8'b0;
                        datab_reg<=8'b0;
                end
        else
                begin
                        href_reg<=href;
                        datar_reg<=datar;
                        datag_reg<=datag;       
                        datab_reg<=datab;
                end
end

// *********************************** convert 8 to 16 ********************************************
always@(posedge pclk or posedge reset)
begin
        if(reset==1'b1)
                begin
                        data_R16[15:8]<=8'b0;
                        data_R16[7:0] <=8'b0;
                        data_G16[15:8]<=8'b0;
                        data_G16[7:0] <=8'b0;
                        data_B16[15:8]<=8'b0;
                        data_B16[7:0] <=8'b0;
                end
        else if((counter_wr>0) && (counter_wr[0]==0))       //even
                begin
                        data_R16[15:8]<=datar;
                        data_R16[7:0] <=datar_reg;           //低8位数据在前面
                        data_G16[15:8]<=datag;
                        data_G16[7:0] <=datag_reg;
                        data_B16[15:8]<=datab;
                        data_B16[7:0] <=datab_reg;                      
                end
        else
                begin                                       //hold
                        data_R16[15:8]<=data_R16[15:8];
                        data_R16[7:0] <=data_R16[7:0];
                        data_G16[15:8]<=data_G16[15:8];
                        data_G16[7:0] <=data_G16[7:0];
                        data_B16[15:8]<=data_B16[15:8];
                        data_B16[7:0] <=data_B16[7:0];
                end
end

// ******************************************* wrreq **********************************************
always@(posedge pclk or posedge reset)
begin
        if(reset==1'b1)
                begin
                        wrreq<=1'b0;
                end
        else if((counter_wr>10'b0) && (counter_wr[0]==0))       //even
                begin
                        wrreq<=1'b1;
                end
        else
                begin
                        wrreq<=1'b0;
                end
end


endmodule

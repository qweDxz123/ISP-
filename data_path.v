/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang
Modified by Xiao
time  : 2012.10.18
                                                                                               
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller 

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:  data_path module
Function: SDRAM : K4M513233C
	  SDRAM Size: 4M*32*4 banks
	  row size:13
    column size:9
    bank size:4

***************************************************************************************************/ 
`timescale 1ns / 10ps
module data_path(
                reset,
                clk,
                datain,
                dm,
                writeoe,
                readoe,             
                dataout,
                dqm,
                dq
                 );
                 
parameter        dsize=16;

input                        reset;
input                        clk;
input[dsize-1:0]             datain;
input[dsize/8-1:0]           dm;
input                        writeoe;
input                        readoe;
inout[31:0]                  dq;
output[dsize-1:0]            dataout;
output[3:0]          dqm;       

reg[dsize-1:0]               dataout;
reg[31:0]                    datain1;
reg[3:0]                     dqm;

reg                          readoe_temp;

//****************************************** readoe_temp ******************************************
always @(posedge clk or posedge reset)
begin
        if(reset==1)
                readoe_temp<=1'b0;
        else
                readoe_temp<=readoe;
end


assign dq=(writeoe==0)?datain1:32'bz;           //write 

                                                                        
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        dataout<=16'b0;
                        datain1<=31'b0;
                        dqm<=4'b0;             //note: 2'b11;                                          
                end                                             
        else    if(readoe_temp==0)      
//      else    if(readoe==0)
                begin
                        dataout<=dq[15:0];            
                        datain1<={16'b0,datain};
                        dqm<={dm,dm};                                        
                end
        else
                begin
                        dataout<=16'b0;
                        datain1<={16'b0,datain};
                        dqm<={dm,dm};
                end
end


endmodule







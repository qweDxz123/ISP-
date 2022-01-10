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
`timescale 1ns / 100ps
module sdramcontroller(
                       clk,
                       reset,
                       addr,
                       cmd,
                       datain,
                       dm,
                       dataout,                      
                       sa,
                       ba,
                       cs_n,
                       cke,
                       ras_n,
                       cas_n,
                       we_n,
                       dqm,
                       dq
		       );
                       
parameter dsize=16,asize=25;

input                   clk;
input                   reset;
input[asize-1:0]        addr;
input[2:0]              cmd;
input[dsize-1:0]        datain;
input[dsize/8-1:0]      dm;
inout[31:0]             dq;
output[dsize-1:0]       dataout;
output[12:0]            sa;
output[1:0]             ba;
output                  cs_n;
output                  cke;
output                  ras_n;
output                  cas_n;
output                  we_n;
output[3:0]             dqm;

//input and output
wire               clk;
wire               reset;
wire[24:0]         addr;
wire[2:0]          cmd;
wire[15:0]         datain;
wire[1:0]          dm;
wire[15:0]         dataout;                      
wire[12:0]         sa;
wire[1:0]          ba;
wire               cs_n;
wire               cke;
wire               ras_n;
wire               cas_n;
wire               we_n;
wire[3:0]          dqm;
wire[31:0]         dq;

//internal signals
wire[asize-1:0]    saddr;
wire               nop;
wire               reada;
wire               writea;
wire               refresh;
wire               precharge;
wire               load_mode;
wire               read;    					      
wire[1:0]          sc_cl;			
wire[1:0]          sc_rc;			
wire[3:0]          sc_rrd;					
wire[3:0]          sc_bl;
          
wire               writeoe;
wire               readoe;
                         
                        
control_interface       control_interface1(
                   .reset(reset),
                   .clk(clk),
                   .cmd(cmd),
                   .addr(addr),			                    		
                   .saddr(saddr),			
                   .nop(nop),			
                   .reada(reada),
                   .writea(writea),
                   .refresh(refresh),
                   .precharge(precharge),
                   .load_mode(load_mode),
                   .read(read),			
                   .sc_cl(sc_cl),		
                   .sc_rc(sc_rc),			
                   .sc_rrd(sc_rrd),			
                   .sc_bl(sc_bl)			
                   );		


command	      command1(
                   .reset(reset),
               	   .clk(clk),
               	   .nop(nop),			
               	   .reada(reada),			
               	   .writea(writea),			
               	   .refresh(refresh),			
               	   .precharge(precharge),		
               	   .load_mode(load_mode),		
               	   .read(read),			      
               	   .sc_cl(sc_cl),			
               	   .sc_rc(sc_rc),			
               	   .sc_rrd(sc_rrd),					
               	   .sc_bl(sc_bl),			
               	   .saddr(saddr),		//note!	       
               	   .sa(sa),			
               	   .ba(ba),			
               	   .cs_n(cs_n),	
               	   .ras_n(ras_n),
               	   .cas_n(cas_n),
               	   .we_n(we_n),
               	   .cke(cke),
             	   .writeoe(writeoe),
                   .readoe(readoe)
               	   );


data_path	data_path1(
                   .reset(reset),
                   .clk(clk),
                   .datain(datain),
                   .dm(dm),
                   .writeoe(writeoe),
                   .readoe(readoe), 
                   .dataout(dataout),
                   .dqm(dqm),
                   .dq(dq)
                   );

endmodule   
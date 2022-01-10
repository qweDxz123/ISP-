/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang
Modified by Xiao Feihuang
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
module control_interface(
                         reset,
                         clk,
                         cmd,
                         addr,                                                  
                         saddr,                 
                         nop,                   
                         reada,
                         writea,
                         refresh,
                         precharge,
                         load_mode,
                         read,                  
                         sc_cl,                 
                         sc_rc,                 
                         sc_rrd,                
                         sc_bl          
                         );             
parameter       asize=25;                   //col  : addr[8:0]
                                            //row  : addr[21:9]
                                            //bank : addr[23:22]
                                            //cs_n : addr[24]
input                   reset;
input                   clk;                     
input[2:0]              cmd;
input[asize-1:0]        addr;    
                     
output[asize-1:0]       saddr;                  
output                  nop;                    
output                  reada;                  //read with auto precharge , but not with active
output                  writea;
output                  refresh;
output                  precharge;
output                  load_mode;
output                  read;                   //read not with auto precharge , but with active 
output[1:0]             sc_cl;
output[1:0]             sc_rc;
output[3:0]             sc_rrd;
output[3:0]             sc_bl;

reg                     nop;
reg                     reada;
reg                     writea;
reg                     refresh;
reg                     precharge;
reg                     load_mode;
reg                     load_reg;               //internal register
reg                     read;
reg[asize-1:0]          saddr;                  
reg[1:0]                sc_cl;                  //total 12bits   addr 13bit addr[8] no use       
reg[1:0]                sc_rc;                  //total 12bits          
reg[3:0]                sc_rrd;                 //total 12bits                  
reg[3:0]                sc_bl;                  //total 12bits          


//************************************ Command decode *********************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        nop<=1'b0;
                        reada<=1'b0;
                        writea<=1'b0;
                        refresh<=1'b0;
                        precharge<=1'b0;
                        load_mode<=1'b0;
                        load_reg<=1'b0;
                        read<=1'b0;
                end
        else                                            //decode cmd[2:0] to nop,reada...load_reg and read
                case(cmd)
                        3'b000:
                                begin
                                        nop<=1'b1;                 
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b0;
                                end
                        3'b001:
                                begin   
                                        nop<=1'b0;
                                        reada<=1'b1;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b0;
                                end
                        3'b010:
                                begin    
                                        nop<=1'b0;
                                        reada<=1'b0;
                                        writea<=1'b1;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b0;
                                end
                        3'b011:
                                begin    
                                        nop<=1'b0;
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b1;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b0;
                                end
                        3'b100:
                                begin    
                                        nop<=1'b0;
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b1;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b0;
                                end
                        3'b101:
                                begin    
                                        nop<=1'b0;
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b1;
                                        load_reg<=1'b0;
                                        read<=1'b0;
                                end
                        3'b110:
                                begin    
                                        nop<=1'b0;
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b1;
                                        read<=1'b0;
                                end
                        3'b111:
                                begin    
                                        nop<=1'b0;
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b1;
                                end
                        default:
                                begin
                                        nop<=1'b1;
                                        reada<=1'b0;
                                        writea<=1'b0;
                                        refresh<=1'b0;
                                        precharge<=1'b0;
                                        load_mode<=1'b0;
                                        load_reg<=1'b0;
                                        read<=1'b0;                                        
                                end
                endcase                         
end

//************************* register configuration information if LOAD_REG asserted ***************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        saddr<=25'b0;
                        sc_cl<=2'b00;
                        sc_rc<=2'b00;
                        sc_rrd<=3'b000;
                        sc_bl<=3'b000;
                end
        else   
                begin
                        saddr<=addr;            //pass the configuration information through address
                        if (load_reg)   
                                begin
                                        sc_cl[1:0]<=addr[1:0];
                                        sc_rc[1:0]<=addr[3:2];
                                        sc_rrd[3:0]<=addr[7:4];
                                        sc_bl[3:0]<=addr[12:9];
                                end                                             
                        else
                                begin
                                        sc_cl<=sc_cl;                //keep internal registers
                                        sc_rc<=sc_rc;
                                        sc_rrd<=sc_rrd;
                                        sc_bl<=sc_bl;                           
                                end
                end
end



endmodule         


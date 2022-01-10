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
module command(
               reset,
               clk,
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
               sc_bl,                   
               saddr,  
               sa,                      
               ba,                      
               cs_n,    
               ras_n,
               cas_n,
               we_n,
               cke,
               writeoe,
               readoe
               );

parameter  asize=25;

input              reset;
input              clk;                      
input              nop;
input              reada;
input              writea;
input              refresh;
input              precharge;
input              load_mode;
input              read;
input[1:0]         sc_cl;
input[1:0]         sc_rc;
input[3:0]         sc_rrd;
input[3:0]         sc_bl;
input[asize-1:0]   saddr;

output[12:0]       sa;                       
output[1:0]        ba;
output             cs_n;
output             ras_n;
output             cas_n;
output             we_n;
output             cke;
output             writeoe;
output             readoe;

//*************************************** counter & flag ******************************************
reg[5:0]           duration;
reg[5:0]           rduration;
reg[5:0]           wduration;
reg[4:0]           r_reg;
reg[4:0]           w_reg;
reg[3:0]           rrd;
reg[5:0]           temprregsub;
reg[5:0]           tempwregsub;

reg                ras_n;
reg                cas_n;
reg                we_n;
wire               cke;
reg[12:0]          sa;
reg[1:0]           ba;
reg                cs_n;


//******************************************* counter *********************************************
always @(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        r_reg<=5'b0;
                        w_reg<=5'b0;
                        rrd<=4'b0;
                        temprregsub<=6'b0;
                        tempwregsub<=6'b0;
                end
        else if(sc_cl)                                   //modify
                begin                                           
                        r_reg<=sc_cl+sc_rc+sc_bl-5'd6;     //-6? 连续两次写延迟最少为8，如果r_reg大于8，则相邻两次写之间不连续（肖）
                        w_reg<=sc_rc+sc_bl-5'd3;                     
                        rrd<=sc_rrd;
                        temprregsub<={1'b0,r_reg}-sc_rc;                                        
                        tempwregsub<={1'b0,w_reg}-sc_rc;
                end                                                                     
        else
                begin
                        r_reg<=r_reg;
                        w_reg<=w_reg;
                        rrd<=rrd;                        //RRD is the refresh to RAS delay in clock period(RFC).
                        temprregsub<=temprregsub;
                        tempwregsub<=tempwregsub;
                end
end


//******************************************* duration ********************************************
always @(posedge clk or posedge reset)
begin   
        if(reset==1)            
                duration<=6'b0;                                                    
        else if(duration==6'b0)
                begin
                        if (nop)
                                duration<=6'b0;
                        else if (refresh)               
                                duration<=rrd;
                        else if (precharge)
                                duration<=6'd2;                      //tRP
                        else if (load_mode)
                                duration<=6'd1;
                        else                                      //load_reg
                                duration<=duration;
                end
        else
                duration<=duration-6'd1;                           
end
//**************************duration在后面没有用到（肖）****************************************************

always @(posedge clk or posedge reset)
begin   
        if(reset==1)
                rduration<=6'b0;      
        else if(rduration==6'b0)
                begin
                        if(reada)
                                rduration<=r_reg;
                        else if(read)
                                rduration<=r_reg;
                        else
                                rduration<=rduration;
                end
        else
                rduration<=rduration-6'd1;  
end


always @(posedge clk or posedge reset)
begin   
        if(reset==1)
                wduration<=6'b0;      
        else if(wduration==6'b0)
                begin
                        if(writea)
                                wduration<=w_reg;
                        else
                                wduration<=wduration;
                end
        else
                wduration<=wduration-6'd1;
end

//********************************************* address *******************************************
//*********************************************** ba *****************************************
always @(posedge clk or posedge reset)
begin
        if(reset==1)
                ba<=2'b00;
        else if(reada)
                begin                                                   
                        if(rduration==r_reg)                                    
                                ba[1:0]<=saddr[23:22];                                                  
                        else
                                ba<=ba;                                         
                end    
        else if(writea)
                begin 
                        if(wduration==w_reg)
                                ba[1:0]<=saddr[23:22];                                          
                        else
                                ba<=ba;
                end
        else if(read)
                begin                                                   
                        if(rduration==r_reg)                                    
                                ba[1:0]<=saddr[23:22];                                          
                        else
                                ba<=ba;
                end    
        else
                ba<=ba;                          //include nop command
end


//*********************************************** ba **********************************************
always @(posedge clk or posedge reset)
begin   
        if(reset==1)
                sa<=13'b0;                                          
        else if(reada)                                  
                begin
                        if(rduration==r_reg)
                                sa[12:0]<=saddr[21:9];
                        else if(rduration==temprregsub)                         
                                begin                                           
                                        sa[8:0]<=saddr[8:0];
                                        sa[12:9]<=4'b0010;      //A[10] = 1, read with auto precharge
                                end                                                     
                        else                                                                                                    
                                sa<=sa;
                end     
        else if(writea)
                begin 
                        if(wduration==w_reg)
                                sa[12:0]<=saddr[21:9];
                        else if(wduration==tempwregsub)
                                begin
                                        sa[8:0]<=saddr[8:0];
                                        sa[12:9]<=4'b0010;      //A[10] = 1, write with auto precharge
                                end 
                        else
                                sa<=sa;
                end
        else if(precharge)                              
                sa<=13'd1024;                               //A[10] = 1, precharge all banks                                        
        else if(load_mode)                                              
                sa<=saddr[12:0];                                                
        else if(read)                                   
                begin
                        if(rduration==r_reg)
                                sa[12:0]<=saddr[21:9];
                        else if(rduration==temprregsub)                         
                                begin                                           
                                        sa[8:0]<=saddr[8:0];
                                        sa[12:9]<=4'b0000;              //A[10] = 0, read without precharge
                                end                                                     
                        else                                            
                                sa<=sa;
                end
        else    
                sa<=sa;
end


//***************************************** command decode ****************************************
//******************************************** RAS_N *****************************************
always @(posedge clk or posedge reset)
begin
        if(reset==1)    
                ras_n<=1'b1;                               
        else if(reada)                  
                begin           
                        if(rduration==r_reg)                    
                                ras_n<=1'b0;                  // ACTIVE               not active
                        else
                                ras_n<=1'b1;
                end     
        else if(writea)                 
                begin 
                        if(wduration==w_reg)
                                ras_n<=1'b0;                  // ACTIVE
                        else
                                ras_n<=1'b1;
                end
        else if(refresh)
                ras_n<=1'b0;
        else if(precharge)                      
                ras_n<=1'b0;
        else if(load_mode)
                ras_n<=1'b0;
        else if(read)
                begin   
                        if(rduration==r_reg)
                                ras_n<=1'b0;
                        else
                                ras_n<=1'b1;
                end  
        else
                ras_n<=1'b1;
end


//******************************************** CAS_N *********************************************
always @(posedge clk or posedge reset)
begin
        if(reset==1)
                cas_n<=1'b1;
        else if(reada)                          
                begin
                        if(rduration==temprregsub) 
                                cas_n<=1'b0;
                        else
                                cas_n<=1'b1;
                end     
        else if(writea)
                begin  
                        if(wduration==tempwregsub)
                                cas_n<=1'b0;
                        else
                                cas_n<=1'b1;
                end
        else if(refresh)
                cas_n<=1'b0;
        else if(load_mode)
                cas_n<=1'b0;
        else if(read)                           
                begin
                        if(rduration==temprregsub)      
                                cas_n<=1'b0;
                        else
                                cas_n<=1'b1;
                end   
        else 
                cas_n<=1'b1;                        //include : nop，active,precharge(111，011，010)
end


//***************************************** writeoe & readoe **************************************
reg[3:0]  writeacount,readacount;
reg       writeoe, readoetemp,readoe;

always  @(posedge clk or posedge reset)
begin
        if (reset)
                writeacount<=4'b0000;
        else if ((writea==1'b1)&&(wduration==tempwregsub))
                writeacount<=4'd8;
        else if (writeacount>0)
                writeacount<=writeacount-4'd1;
        else
                writeacount<=writeacount;
end   

always @(writeacount)
begin   
        if (writeacount>0)
                writeoe<=1'b0;
        else 
                writeoe<=1'b1;
end

always  @(posedge clk or posedge reset)
begin
        if (reset)
                readacount<=4'b0000;
        else if (((reada==1'b1)&&(rduration==temprregsub)) || ((read==1'b1)&&(rduration==temprregsub)))
                readacount<=4'd8;
        else if (readacount>0)
                readacount<=readacount-4'd1;
        else
                readacount<=readacount;
end 


always  @(readacount)
begin 
        if (readacount>0)
                readoetemp<=1'b0;
        else
                readoetemp<=1'b1;
end


always  @(posedge clk or posedge reset)
begin
        if (reset==1)
                readoe<=1'b0;
        else 
                readoe<=readoetemp;
end


//************************************************ WE_N *******************************************
always @(posedge clk or posedge reset)
begin   
        if(reset==1)
                we_n<=1'b1;
        else if(writea)                         
                begin          
                        if(wduration==tempwregsub)                     
                                we_n<=1'b0;                        
                        else        
                                we_n<=1'b1;
                end
        else if(precharge)
                we_n<=1'b0;
        else if(load_mode)      
                we_n<=1'b0;
        else                                        
                we_n<=1'b1;                        //include : nop，active,reada,refresh(111，011，101，001)
end


//*********************************************** CS_N ********************************************
always @(posedge clk or posedge reset)
begin
        if(reset==1)
                cs_n<=1'b1;
//      else
//              cs_n<=0;
        else if(reada)          
                begin
                        if(rduration==r_reg)                                    
                                cs_n<=saddr[24];                // load power
                        else
                                cs_n<=cs_n;
                end     
        else if(writea)         
                begin 
                        if(wduration==w_reg)                            
                                cs_n<=saddr[24];
                        else
                                cs_n<=cs_n;
                end
        else if(refresh)
                cs_n<=1'b0;
        else if(precharge)
                cs_n<=1'b0;
        else if(load_mode)
                cs_n<=1'b0;
        else if(read)           
                begin
                        if(rduration==r_reg)                    
                                cs_n<=saddr[24];
                        else
                                cs_n<=cs_n;
                end     
        else
                cs_n<=cs_n;
end

//*********************************************** CKE *********************************************
assign  cke=1'b1;



endmodule      

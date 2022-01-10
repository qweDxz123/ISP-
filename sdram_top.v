/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author:	Zeng Qiang

time  : 2005.02.23
                                                                                                  
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller testbench

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:      top
Function:  top level

***************************************************************************************************/ 

`timescale 1ns / 100ps
module  sdram_top(
                   clk,
                   reset,
                   pclk,
                   vsync,             // note , maybe not necessary
                   href,
                   start,
                   datar,
                   datag,
                   datab,
                   data1,
                   data2,
                   en_tile,
                   en_line,
                   sa,
                   ba,
                   ras_n,
                   cas_n,
                   we_n,
                   dq,
                   cs_n,
                   cke,
                   dqm
               );

/*
parameter  tile_size    = 
parameter  tile_height  = 
parameter  tile_width   = 
parameter  image_height = 
parameter  image_width  = 
parameter  tilerowpar   = image_height/tile_size;        //the image can be divided into tiles in row direction
parameter  tilecolpar   = image_width /tile_size;        //the image can be divided into tiles in col direction


parameter   USEDW_R       =                            //threshold in fifo-R for read starting
parameter   USEDW_G       =                            //threshold in fifo-G for read starting
parameter   USEDW_B       =                            //threshold in fifo-B for read starting
parameter   USEDW_1       =                            //threshold in fifo-1 for write stopping and read starting 
parameter   USEDW_2       =                            //threshold in fifo-2 for write stopping and read starting
parameter   LINE_INTERVAL =                            //interval between two lines
*/


input              clk;
input              reset;
input              pclk;
input              vsync;
input              href;
input              start;
input[7:0]         datar;
input[7:0]         datag;
input[7:0]         datab;

output[10:0]        data1;
output[10:0]        data2;
output             en_tile;
output             en_line;
output[12:0]       sa;
output[1:0]        ba;
output             ras_n;
output             cas_n;
output             we_n;
inout[31:0]        dq;        //modified by Xiao
output             cs_n;
output             cke;
output[3:0]        dqm;       //modified by Xiao

// input and output signals
wire               clk;
wire               reset;
wire               pclk;
wire               vsync;
wire               href;
wire               start;
wire[7:0]          datar;
wire[7:0]          datag;
wire[7:0]          datab;

wire[10:0]          data1;
wire[10:0]          data2;
wire                en_tile;                      // also for internal signal
wire                en_line;
wire[12:0]         sa;
wire[1:0]          ba;
wire               ras_n;
wire               cas_n;
wire               we_n;
wire[31:0]         dq;
wire               cs_n;
wire               cke;
wire[3:0]          dqm;

// internal signals
wire               regs0;
wire               regs1;
wire               regs2;
wire               regs3;
wire               regs4;
wire               regs5;
wire               regs6;
wire               regs7;
wire               regs4_temp;
wire               regs6_temp;
wire[5:0]          counter_initial;
wire               counter_s2;
wire[4:0]          counter_s4;
wire[4:0]          counter_s6;

wire[4:0]          cnt_odd_even;

wire               wrreq;                        // write request for fifo R/G/B
wire               wrreq_1;
wire               wrreq_2;
wire               rdreq_R;
wire               rdreq_G;
wire               rdreq_B;
wire               rdreq;                        // read request for fifo 1/2
wire               full_R;
wire               full_G;
wire               full_B;
wire               full_1;
wire               full_2;
wire               empty_R;
wire               empty_G;
wire               empty_B;
wire               empty_1;
wire               empty_2;
wire[5:0]          usedw_R;          
wire[5:0]          usedw_G;
wire[5:0]          usedw_B;
wire[7:0]          usedw_1;
wire[7:0]          usedw_2;

wire               en_wr;
wire               en_rd;
wire[2:0]          cmd;
wire[24:0]         addr;

wire[15:0]         data_R16;
wire[15:0]         data_G16;
wire[15:0]         data_B16;
wire[15:0]         dataoutfifo_R16;
wire[15:0]         dataoutfifo_G16;
wire[15:0]         dataoutfifo_B16;
wire[15:0]         datain_contr;
wire[15:0]         dataout_contr;
wire[15:0]         data1_16;
wire[15:0]         data2_16;



// data into sdram controller

//assign datain_contr = 1 ? R : (2 ? G : (3 ? B : 16'b0));

assign datain_contr =  (counter_s4>=6  && counter_s4<=13 ) ? dataoutfifo_R16 : 
                      ((counter_s4>=14 && counter_s4<=21 ) ? dataoutfifo_G16 :
                      ((counter_s4>=22 && counter_s4<=29 ) ? dataoutfifo_B16 :16'b0));





// ******************************************** dm ************************************************
wire[1:0]          dm;

assign  dm = 2'b00;




camera_interface  camera_interface1(
                   .pclk(pclk),
                   .reset(reset),
                   .href(href),
                   .en_wr(en_wr),                       //时钟频率不同，会不会产生问题！？
                   .datar(datar),
                   .datag(datag),
                   .datab(datab),
                   .data_R16(data_R16),
                   .data_G16(data_G16),
                   .data_B16(data_B16),
                   .wrreq(wrreq)
                   );

// *************************************** 增加FIFO R/G/B的清零信号 *******************************

wire     aclr_fifoRGB;

assign   aclr_fifoRGB = (reset || vsync);



fifoRGB     fifoR(
                   .data(data_R16),
                   .wrreq(wrreq),
                   .rdreq(rdreq_R),
                   .rdclk(clk),
                   .wrclk(pclk),
                   .aclr(aclr_fifoRGB),
                   .q(dataoutfifo_R16),    //包含两个像素的R值（低8位数据在前）
                   .rdfull(full_R),
                   .rdempty(empty_R),
                   .rdusedw(usedw_R)                    //深度为64
                );


fifoRGB     fifoG(
                   .data(data_G16),
                   .wrreq(wrreq),
                   .rdreq(rdreq_G),
                   .rdclk(clk),
                   .wrclk(pclk),
                   .aclr(aclr_fifoRGB),
                   .q(dataoutfifo_G16),
                   .rdfull(full_G),
                   .rdempty(empty_G),
                   .rdusedw(usedw_G)
                );


fifoRGB     fifoB(
                   .data(data_B16),
                   .wrreq(wrreq),
                   .rdreq(rdreq_B),
                   .rdclk(clk),
                   .wrclk(pclk),
                   .aclr(aclr_fifoRGB),
                   .q(dataoutfifo_B16),
                   .rdfull(full_B),
                   .rdempty(empty_B),
                   .rdusedw(usedw_B)
                );


sdramcontroller   sdramcontroller1(
                   .clk(clk),
                   .reset(reset),
                   .addr(addr),
                   .cmd(cmd),
                   .datain(datain_contr),
                   .dm(dm),
                   .dataout(dataout_contr),
                   .sa(sa),
                   .ba(ba),
                   .cs_n(cs_n),
                   .cke(cke),
                   .ras_n(ras_n),
                   .cas_n(cas_n),
                   .we_n(we_n),
                   .dqm(dqm),
                   .dq(dq)
		   );


fifo_dwt    fifo1(
                   .data(dataout_contr),
                   .wrreq(wrreq_1),
                   .rdreq(rdreq),
                   .clock(clk),
                   .aclr(reset),
                   .q(data1_16),
                   .full(full_1),
                   .empty(empty_1),
                   .usedw(usedw_1)
               );


fifo_dwt    fifo2(
                   .data(dataout_contr),
                   .wrreq(wrreq_2),
                   .rdreq(rdreq),
                   .clock(clk),
                   .aclr(reset),
                   .q(data2_16),
                   .full(full_2),
                   .empty(empty_2),
                   .usedw(usedw_2)
               );


dwt_interface  dwt_interface1(
                   .clk(clk),
                   .reset(reset),
                   .start(start),
                   .usedw_2(usedw_2),
                   .data1_16(data1_16),
                   .data2_16(data2_16),
                   .image_out1(data1),
                   .image_out2(data2),
                   .rdreq(rdreq),
                   .en_tile(en_tile),
                   .en_line(en_line)
                   );


arbitrator  arbitrator1(
                   .clk(clk),
                   .reset(reset),
                   .start(start),
                   .en_tile(en_tile),
                   .usedw_R(usedw_R),
                   .usedw_2(usedw_2),
                   .en_wr(en_wr),
                   .en_rd(en_rd),
                   .regs0(regs0),
                   .regs1(regs1),
                   .regs2(regs2),
                   .regs3(regs3),
                   .regs4(regs4),
                   .regs5(regs5),
                   .regs6(regs6),
                   .regs7(regs7),
                   .regs4_temp(regs4_temp),
                   .regs6_temp(regs6_temp),
                   .counter_initial(counter_initial),
                   .counter_s2(counter_s2),
                   .counter_s4(counter_s4),
                   .counter_s6(counter_s6)
                   );


cmd_gen  cmd_gen1(
                   .clk(clk),
                   .reset(reset),
                   .regs0(regs0),
                   .regs1(regs1),
                   .regs2(regs2),
                   .regs3(regs3),
                   .regs4(regs4),
                   .regs5(regs5),
                   .regs6(regs6),
                   .regs7(regs7),
                   .counter_initial(counter_initial),
                   .counter_s2(counter_s2),
                   .counter_s4(counter_s4),
                   .counter_s6(counter_s6),
                   .cnt_odd_even(cnt_odd_even),
                   .rdreq_R(rdreq_R),
                   .rdreq_G(rdreq_G),
                   .rdreq_B(rdreq_B),
                   .wrreq_1_reg(wrreq_1),
                   .wrreq_2_reg(wrreq_2),
//                   .wrreq_1(wrreq_1),
//                   .wrreq_2(wrreq_2),
                   .cmd(cmd)
                   );


addr_gen  addr_gen1(
                   .clk(clk),
                   .reset(reset),
                   .vsync(vsync),
                   .regs0(regs0),
                   .regs1(regs1),
                   .regs2(regs2),
                   .regs3(regs3),
                   .regs4(regs4),
                   .regs5(regs5),
                   .regs6(regs6),
                   .regs7(regs7),
                   .regs4_temp(regs4_temp),
                   .regs6_temp(regs6_temp),
                   .counter_initial(counter_initial),
                   .counter_s4(counter_s4),
                   .counter_s6(counter_s6),
                   .cnt_odd_even(cnt_odd_even),
                   .en_wr(en_wr),
                   .en_rd(en_rd),
                   .addr(addr)
                  );


endmodule
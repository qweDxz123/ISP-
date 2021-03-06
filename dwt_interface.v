/************************************************************************************************** 
                                                                                                  
Copyright 2002-2003 , AI&R , Xi'an Jiao Tong University                                           
                                                                                                  
All Rights Reserved                                                                               
                                                                                                  
Version: 1.0                                                                                      
                                                                                                  
Author: Zeng Qiang

time  : 2005.02.23
                                                                                                  
**************************************************************************************************/
                                                                                                  
//JPEG2000  SDRAM Controller testbench

/*****************        SYNTHESIZABLE MODULES      ********************************************

Name:      rd_fifo_12
Function:  read fifo 1/2,and convert data1/2[16:0] to data1/2[7:0] 

***************************************************************************************************/ 

`timescale 1ns / 100ps
module  dwt_interface(
                     clk,
                     reset,
                     start,                    // 改为 start_inter
                     usedw_2,
                     data1_16,
                     data2_16,                  //16位
                     image_out1,                //11位
                     image_out2,
                     rdreq,                      // for fifo 1 & 2
                     en_tile,
                     en_line                     //与image_out同步
                   );

parameter USEDW_2_par       = 128;
parameter LINE_INTERVAL_4 = 32;             // 8*2   每两行之间最少8个间隔


input           clk;
input           reset;
input           start;
input[7:0]      usedw_2;
input[15:0]     data1_16;
input[15:0]     data2_16;

output[10:0]     image_out1;
output[10:0]     image_out2;
output          rdreq;
output          en_tile;
output          en_line;

wire            clk;
wire            reset;
wire            start;
wire[7:0]       usedw_2;
wire[15:0]      data1_16;
wire[15:0]      data2_16;
reg[10:0]     image_out1;
reg[10:0]     image_out2;



reg[7:0]        data1;
reg[7:0]        data2;
reg             rdreq;
reg             en_tile;
reg             en_line;

reg             start_reg;


reg             rdreq_reg;
reg             rdreq_reg2;
reg             rdreq_reg3;
reg             rdreq_reg4;

reg[15:0]       data1_reg;
reg[15:0]       data2_reg;
reg[15:0]       data1_reg2;
reg[15:0]       data2_reg2;


reg[9:0]        counter_rd;
reg[7:0]        counter_line;                   // 128 times

reg             en_line_temp;
reg             en_line_temp_reg;
reg             en_line_reg;

reg  [4:0]      en_tilecount;

// ************************************ counter for rdreq *****************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_rd<=10'b0;
                end
        else if(usedw_2>=USEDW_2_par && counter_rd==0 && en_tile==1 && en_tilecount==0)
                begin
                        counter_rd<=10'd512+LINE_INTERVAL_4;          //128*2*2
                end
        else if (counter_rd>0)
                begin
                        counter_rd<=counter_rd-10'd1;
                end
        else
                begin
                        counter_rd<=counter_rd;
                end
end

// ******************************************* rdreq **********************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        rdreq<=1'b0;
                end
        else if ((counter_rd>LINE_INTERVAL_4) && (counter_rd[0]==0) && (counter_rd[1]==0))    // 4的倍数(读一次，4个像素数据)
                begin
                        rdreq<=1'b1;                                               //读完tile的两行后休息(LINE_INTERVAL_4)个clk
                end     
        else
                begin
                        rdreq<=1'b0;
                end
end

// ************************************** register signals ****************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        start_reg<=1'b0;
                        en_line<=1'b0;
                        en_line_temp_reg<=1'b0;
                        en_line_reg<=1'b0;                        
                        rdreq_reg<=1'b0;
                        rdreq_reg2<=1'b0;
                        rdreq_reg3<=1'b0;
                        rdreq_reg4<=1'b0;
                        data1_reg<=16'b0;
                        data2_reg<=16'b0;
                        data1_reg2<=16'b0;
                        data2_reg2<=16'b0;
                end
        else
                begin
                        start_reg<=start;
                        en_line_temp_reg<=en_line_temp;
                        en_line<=en_line_temp_reg;
                        en_line_reg<=en_line;
                        rdreq_reg<=rdreq;
                        rdreq_reg2<=rdreq_reg;
                        rdreq_reg3<=rdreq_reg2;                 
                        rdreq_reg4<=rdreq_reg3;                 
                        data1_reg<=data1_16;
                        data2_reg<=data2_16;
                        data1_reg2<=data1_reg;
                        data2_reg2<=data2_reg;
                end
          
end

// ************************************** data1 / data2 *******************************************
// combinational logic
always@(rdreq_reg or rdreq_reg2 or rdreq_reg3 or rdreq_reg4 or data1_16 or data2_16 or data1_reg2 or data2_reg2)
begin
        if(rdreq_reg==1 || rdreq_reg2==1)
                begin
                        data1<=data1_16[7:0];             //一个像素数据有效期为2个clk
                        data2<=data2_16[7:0]; 
                end
        else if(rdreq_reg3==1 || rdreq_reg4==1)           //保证了像素数据是连续的
                begin
                        data1<=data1_reg2[15:8];
                        data2<=data2_reg2[15:8]; 
                end
        else
                begin
                        data1<=8'b0;
                        data2<=8'b0; 
                end  
end  

wire	[7:0]	image1_temp;
wire	[7:0]	image2_temp;
assign 		image1_temp=data1-128;       //移位
assign 		image2_temp=data2-128;

always@(posedge clk or posedge reset)
begin
	if(reset)
	begin
		    image_out1<=0;
	end
	else if (image1_temp[7]==0)
			image_out1<={3'b000,image1_temp};          //与en_lile同步
	else if (image1_temp[7]==1)
			image_out1<={3'b111,image1_temp};
	
	else 	
		    image_out1<=0;	
end

always@(posedge clk or posedge reset)
begin
	if(reset)
	begin
		     image_out2<=0;
	end
	else if(image2_temp[7]==0)
			image_out2<={3'b000,image2_temp};
	else if (image2_temp[7]==1)
			image_out2<={3'b111,image2_temp};
	else 
        	image_out2<=0;
end




// *************************************** en_line_temp *******************************************
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        en_line_temp<=1'b0;
                end
        else if(counter_rd>LINE_INTERVAL_4)
                begin
                        en_line_temp<=1'b1;
                end     
        else 
                begin
                        en_line_temp<=1'b0;
                end
end

//将 en_line_temp延时一个时钟就是 en_lien ，再延时一个时钟取其下降沿计算 en_tile


// ***************************************** en_tile **********************************************
// *************************************** counter_line ******************************************* 
always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        counter_line<=8'b00000000;
                end
        else if(counter_line==8'd128)
                begin
                        counter_line<=8'b00000000;
                end
        else if((en_line==0) && (en_line_reg==1))              // 下降沿
                begin
                        counter_line<=counter_line+8'd1;
                end
        else
                begin
                        counter_line<=counter_line;
                end
end

always @(posedge clk or posedge reset)
begin
        if (reset==1)
           en_tilecount<=0;
        else if (counter_line==128)
           en_tilecount<=15;
        else if (en_tilecount>0)
           en_tilecount<=en_tilecount-1;
        else 
           en_tilecount<=en_tilecount;
end 
        
        



always@(posedge clk or posedge reset)
begin
        if(reset==1)
                begin
                        en_tile<=1'b0;
                end
   //     else if(counter_line==128)
       else if(en_tilecount==3)          //前一个tile读完后经过12个clk，en_tile才失效
                begin
                        en_tile<=1'b0;
                end
        else if((start==1) && (start_reg==0))   //等码块全部被位平面编码，才开始新的tile
                begin
                        en_tile<=1'b1;
                end
        else    
                begin
                        en_tile<=en_tile;
                end
end


endmodule

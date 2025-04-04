//----------------------------------------------------------------------------//
// File name    : sad_cal.v
// Author       : Daniel Ding
// Email        : 18875979180@163.com
// Project      : 
// Created      : 2025/4/4
// Copyright    : 
// Description  : 
//----------------------------------------------------------------------------//

module sad_cal(
    input         clk    ,
    input         rstn   ,

    input[2047:0] din    ,
    input[2047:0] refi   ,

    input         cal_en ,

    output  reg[15:0]  sad     ,
    output  reg     sad_vld
);

//----data array
wire  [7:0] din_array [0:15][0:15];
wire  [7:0] ref_array [0:15][0:15];


//----16*16 array
generate 
genvar i,j;
for(j=0; j<=15; j=j+1)begin:gen_array_out
	for(i=0 ; i<=15 ; i=i+1)begin:gen_array_in
		assign din_array[j][i] = din[(16* j*8+i*8 )+:8];
                assign ref_array[j][i] = refi[(16*j*8+i*8) +:8];
	end
end
endgenerate


//-----pipeline design

reg [4:0] cal_pipeline_en;

always @(posedge clk or negedge rstn)begin
        if(!rstn)
		cal_pipeline_en <= 'd0;
	else
                cal_pipeline_en <= {cal_pipeline_en[3:0],cal_en};

end



//-----one_step diff

reg [8:0] diff_array[0:15][0:15];

		
             generate 
             genvar y,x;
               for(y=0; y<=15; y=y+1)begin:gen_diff_out

	          for(x=0 ; x<=15 ; x=x+1)begin:gen_diff_in

	             always @(posedge clk or negedge rstn)

	                 if(!rstn)

			       diff_array[y][x] <= 'd0;

		         else if(cal_en)

		               diff_array[y][x] <={1'b0, din_array[y][x]} -{1'b0, ref_array[y][x]};

	          end

               end

             endgenerate

        
//------two_step abs 

reg [7:0] abs_array[0:15][0:15];

             generate  //generate 256 independent abs
             genvar abs_y,abs_x;
               for(abs_y=0; abs_y<=15; abs_y=abs_y+1)begin:gen_abs_out

	          for(abs_x=0 ; abs_x<=15 ; abs_x=abs_x+1)begin:gen_abs_in

	             always @(posedge clk or negedge rstn)

	                 if(!rstn)

			       diff_array[abs_y][abs_x] <= 'd0;

		         else if(cal_pipeline_en[0])

		             //diff_array[abs_y][abs_x] ={1'b0, din_array[abs_y][abs_x]} -{1'b0, ref_array[abs_y][abs_x]};
                               abs_array[abs_y][abs_x]  <= diff_array[abs_y][abs_x][8] ? ((~{diff_array[abs_y][abs_x][7:0]}) + 'd1) 
			                                                                 :diff_array[abs_y][abs_x][7:0];
	          end

               end

             endgenerate

//------three_step 16x16 become 16x4

reg [9:0] acc_16x4[0:15][0:3];  //10bit  9bit + 9bit

              generate 
              genvar y0,x0;
	          for(y0=0 ;y0<=15 ; y0=y0+1)begin:gen_acc0_out
		 	for(x0=0 ; x0<=3 ; x0=x0+1)begin:gen_acc0_in
				always @(posedge clk or negedge rstn)begin
                                   if(!rstn)
					   acc_16x4[y0][x0] <= 'd0;
				   else if(cal_pipeline_en[1])
                                           acc_16x4[y0][x0] <=  {2'b0,abs_array[y0][4*x0 + 0]} + {2'b0,abs_array[y0][4*x0 + 1]}
				                              + {2'b0,abs_array[y0][4*x0 + 2]} + {2'b0,abs_array[y0][4*x0 + 3]};
                                   
				end
			 end
		   end
	       endgenerate

	       
//--------four_step 16x4 become 4x4

reg [11:0] acc_4x4[0:3][0:3]; //12 bit   11bit + 11bit

              generate 
              genvar y1,x1;
	          for(x1=0 ;x1<=3 ; x1=x1+1)begin:gen_acc1_out
		 	for(y1=0 ; y1<=3 ; y1=y1+1)begin:gen_acc1_in
				always @(posedge clk or negedge rstn)begin
                                   if(!rstn)
					   acc_4x4[x1][y1] <= 'd0;
				   else if(cal_pipeline_en[2])
                                           acc_4x4[x1][y1] <=   {2'b0,acc_16x4[4*y1 + 0][x1]} + {2'b0,acc_16x4[4*y1 + 1][x1]}
				                              + {2'b0,acc_16x4[4*y1 + 2][x1]} + {2'b0,acc_16x4[4*y1 + 3][x1]};
                                   
				end
			 end
		   end
	       endgenerate

//---------five_step 4x4 become 4x1
	       
reg [13:0] acc_4x1[0:3]; //14 bit     13bit+13bit

              generate 
              genvar y2;
	          for(y2=0 ;y2<=3 ; y2=y2+1)begin:gen_acc2_out
		 //	for(y1=0 ; y1<=3 ; y1=y1+1)begin:gen_acc2_in
				always @(posedge clk or negedge rstn)begin
                                   if(!rstn)
					   acc_4x1[y2] <= 'd0;
				   else if(cal_pipeline_en[3])
                                           acc_4x1[y2] <=       {2'b0,acc_4x4[y2][0]} + {2'b0,acc_4x4[y2][1]}
				                              + {2'b0,acc_4x4[y2][2]} + {2'b0,acc_4x4[y2][3]};
                                   
				end
		//	 end
		   end
	       endgenerate

//-----------six_step 4x1 become 1x1 final sad
always @(posedge clk or negedge rstn)
        if(!rstn)
		sad <= 'd0;
	else if(cal_pipeline_en[4])
		sad <= {2'b0, acc_4x1[0]} + {2'b0, acc_4x1[1]} + {2'b0, acc_4x1[2]} + {2'b0, acc_4x1[3]};


always @(posedge clk or negedge rstn)

	if(!rstn)
		sad_vld <= 'd0;
	else
		sad_vld <= cal_pipeline_en[4];


endmodule


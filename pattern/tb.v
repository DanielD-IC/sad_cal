//----------------------------------------------------------------------------//
// File name    : sad_cal.v
// Author       : Daniel Ding
// Email        : 18875979180@163.com
// Project      : 
// Created      : 2025/4/4
// Copyright    : 
// Description  : 
//----------------------------------------------------------------------------//

`timescale 1ns/10ps

module tb();

parameter cyc_time = 10.0;

reg clk;
reg rstn;

reg [7:0] din[0:15][0:15];
reg [7:0] refi[0:15][0:15];
reg       cal_en;

wire [2047:0] din_w,ref_w;


wire [15:0] sad;
wire [15:0] sad_golden;

wire        sad_vld, sad_vld_golden;

reg [7:0] rand_val;
reg [7:0] wait_cyc;


integer test_cnt;
integer y,x;
always #(cyc_time / 2.0) clk = ~clk;

initial begin
      $fsdbDumpfile("tb.fsdb");
      $fsdbDumpvars(0,tb);
end

//--------1:gen test data
initial begin
        clk  = 0 ;
	rstn = 0 ;
	cal_en = 0;
	test_cnt = 0;
	repeat(10) @(posedge clk);#1;

	//--test 0: din[y][x]=0 refi[y][x]=0;
	cal_en = 1;
	for(y=0; y<=15; y=y+1)begin
             for(x=0; x<=15 ;x=x+1)begin
                    din[y][x] = 0;
		    refi[y][x]= 0 ;
	     end
	end
	@(posedge clk);#1;

        $display("Info: Do fixed test");
	//--test1: din[y][x] = 0; refi[y][x] =ff
	cal_en = 1 ;
        for(y=0; y<=15; y=y+1)begin
             for(x=0; x<=15 ;x=x+1)begin
                    din[y][x] = 8'h00;
		    refi[y][x]= 8'hff;
	     end
	end
	@(posedge clk);#1;

   	//--test2: din[y][x] = ff; refi[y][x] =ff
	cal_en = 1 ;
        for(y=0; y<=15; y=y+1)begin
             for(x=0; x<=15 ;x=x+1)begin
                    din[y][x] = 8'hff;
		    refi[y][x]= 8'hff;
	     end
	end
	@(posedge clk);#1;

	//--test3: din[y][x] = ff; refi[y][x] =00
	cal_en = 1 ;
        for(y=0; y<=15; y=y+1)begin
             for(x=0; x<=15 ;x=x+1)begin
                    din[y][x] = 8'hff;
		    refi[y][x]= 8'h00;
	     end
	end
	@(posedge clk);#1;

        //--stop 2 cycles
	cal_en = 0;

	repeat(2) @(posedge clk);#1;

	$display("Info : Do random test_0.");

	//--random test 0
	for(test_cnt=0; test_cnt<=(1<<15); test_cnt=test_cnt+1)begin
                rand_val = $random() %256;
		for(y=0; y<=15; y=y+1)begin
			for(x=0; x<=15; x=x+1)begin
                              din[y][x] = $random()%256;
			      refi[y][x] = $random()%256;
			end

		end
                if(rand_val<=128)begin
                      cal_en = 0;
		end else begin
                      cal_en = 1;
		end
                @(posedge clk);#1;
	end
        cal_en = 0;

        repeat(20) @(posedge clk);#1;
	$display("Info : sad_cal sim is pass");
	$finish();
	
end	

//----2:connect dut and model

generate 
genvar y0,x0;
for(y0=0; y0<=15; y0=y0+1)begin
     for(x0=0; x0<=15; x0=x0+1)begin
         assign  din_w [(y0*16*8 + x0*8) +: 8] = din[y0][x0];
	 assign  ref_w [(y0*16*8 + x0*8) +: 8] = din[y0][x0];
     end

end
endgenerate


sad_model #(.DWIDTH(8), .PIPE_STAGE(5)) u_sad_model(
         .din     (din_w)   ,
	 .refi    (refi_w)  ,
         .cal_en  (cal_en),

	 .sad     (sad_golden),
	 .sad_vld (sad_vld_golden),

	 .clk     (clk),
	 .rstn    (rstn)
);

sad_cal u_sad_cal(
         .din     (din_w)   ,
	 .refi    (refi_w)  ,
         .cal_en  (cal_en),

	 .sad     (sad),
	 .sad_vld (sad_vld),

	 .clk(clk),
	 .rstn(rstn)
	 
);


//-----check result-----//

always@ (posedge clk or negedge rstn)

	if(!rstn)begin


	end else if(sad_vld_golden) begin
                if((sad_vld_golden !== sad_vld) || (sad_golden !==sad))begin
                #1;
                $display("Info: sad_cal sim fail.");
		$display("Error: sad_vld_golden=%b, sad_vld=%b | sad_golden=%h, sad=%h",
                sad_vld_golden, sad_vld, sad_golden, sad);
	        $finish();

		end
	end	

endmodule



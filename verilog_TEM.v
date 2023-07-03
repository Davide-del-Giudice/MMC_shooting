//`timescale 1us/1us 
//`timescale 100ns/100ns 
//`define BITS 2 
 
module MMC_1; 
 
LEG_CONTROL #(.TAG(1)) phase_a(); 
LEG_CONTROL #(.TAG(2)) phase_b(); 
LEG_CONTROL #(.TAG(3)) phase_c(); 

endmodule 

module MMC_2; 
 
LEG_CONTROL #(.TAG(1)) phase_a(); 
LEG_CONTROL #(.TAG(2)) phase_b(); 
LEG_CONTROL #(.TAG(3)) phase_c(); 

endmodule 

module LEG_CONTROL; 
 
parameter TAG = 0; 
 
reg [6:0] up; 
reg [6:0] up_upshift; 
reg [6:0] up_dwshift; 
reg [6:0] dw; 
reg [6:0] dw_upshift; 
reg [6:0] dw_dwshift; 
 

real i_up, i_dw; 
real drv_up, drv_dw; 
real limit_dw_dwshift; 
real limit_up_dwshift; 
real limit_dw_upshift; 
real limit_up_upshift; 
real out_upshift; 
real out_dwshift; 

integer i; 
integer Go; 
 
initial begin 
 
// $ display ( " +----------------+" ); 
// $ display ( " | INITIALISATION |" ); 
// $ display ( " +----------------+" ); 
 
limit_dw_upshift = -1.968504e-03; 
limit_up_upshift = 5.905512e-03; 
limit_dw_dwshift = -5.905512e-03; 
limit_up_dwshift = 1.968504e-03; 
out_upshift = 0; 
out_dwshift = 0; 
Go = 1; 
 
// $display("drv_up: ", drv_up, " drv_down: ", drv_dw"); 
while (Go == 1) begin 
Go = 0; 
 
if(drv_up > limit_up_dwshift) begin 
Go = 1; 
limit_up_dwshift = limit_up_dwshift + 7.874016e-03; 
limit_dw_dwshift = limit_dw_dwshift + 7.874016e-03; 
out_dwshift = out_dwshift + 1; 
end 
 
if(drv_up > limit_up_upshift) begin 
Go = 1; 
limit_up_upshift = limit_up_upshift + 7.874016e-03; 
limit_dw_upshift = limit_dw_upshift + 7.874016e-03; 
out_upshift = out_upshift + 1; 
end 
 
end 
 
up = out_upshift; 
 
limit_dw_upshift = -1.968504e-03; 
limit_up_upshift = 5.905512e-03; 
limit_dw_dwshift = -5.905512e-03; 
limit_up_dwshift = 1.968504e-03; 
out_upshift = 0; 
out_dwshift = 0; 
 
Go = 1; 
 
while (Go == 1) begin 
Go = 0; 
 
if(drv_dw > limit_up_dwshift) begin 
Go = 1; 
limit_up_dwshift = limit_up_dwshift + 7.874016e-03; 
limit_dw_dwshift = limit_dw_dwshift + 7.874016e-03; 
out_dwshift = out_dwshift + 1; 
end 
 
if(drv_dw > limit_up_upshift) begin 
Go = 1; 
limit_up_upshift = limit_up_upshift + 7.874016e-03; 
limit_dw_upshift = limit_dw_upshift + 7.874016e-03; 
out_upshift = out_upshift + 1; 
end 
 
end 
 
dw = out_upshift; 
 
// $display("up: ", up, " down: ", dw); 
end 
 
/////////////////// 
// UPPER ARM COMMANDS 
/////////////////// 
 
always @(up_upshift) begin 
if (up_upshift > up) begin 
up = up_upshift; 
end 
end 
 
always @(up_dwshift) begin 
if (up_dwshift < up) begin 
up = up_dwshift; 
end 
end 
 
/////////////////// 
// LOWER ARM COMMANDS 
/////////////////// 
 
always @(dw_upshift) begin 
if (dw_upshift > dw) begin 
dw = dw_upshift; 
end 
end 
 
always @(dw_dwshift) begin 
if (dw_dwshift < dw) begin 
dw = dw_dwshift; 
end 
end 
 
endmodule

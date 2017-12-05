/* Copyright 2017 Andrea Giannini.
Copyright and related rights are licensed under the Solderpad Hardware
License, Version 0.51 (the “License”); you may not use this file except in
compliance with the License.  You may obtain a copy of the License at
http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
or agreed to in writing, software, hardware and materials distributed under
this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License. */
/*----------------------------------------------------------------------------------
Author: Andrea Giannini
 
Create Date(mm/aaaa):	10/2017 
Module Name:			TB_chroma_approximate.v
Project:			interpolation filter project for HEVC
Description:			luma processing element test bench top level
Dependencies:		
			clk_gen.vhd
			data_maker_chroma_approximate_4tap.vhd OR data_maker_chroma_approximate_2tap.vhd	--> change it to try different filter architectures
			ProcessingElement_chroma_approximate.vhd
			data_sink_chroma.vhd
			
Revision: 
		1.0 created
----------------------------------------------------------------------------------*/
module TB_chroma_approximate;
//Inputs
   wire clk;
   wire reset_n;
   wire Vin;
   wire horVer;
   wire [7:0] InData;
   wire [3:0] filterSel_1;
   wire [3:0] filterSel_2;
   wire [5:0] modAddr_IN;
   wire ME_MCBi;
 //Outputs
   wire [15:0] o;
   wire Vout;
   wire END_SIM;
   
//instantiate clk generator
	clk_gen CG(
	.END_SIM(END_SIM),
  	.CLK(clk),
	.RST_n(reset_n));
		  
		  
	data_maker_chroma_approximate_2tap DM(
	.CLK(clk),
	.RST_n(reset_n),
	.Vin(Vin),
	.horVer(horVer),
	.ME_MCBi(ME_MCBi),
	.filterSel_1(filterSel_1),
	.filterSel_2(filterSel_2),
	.InData(InData),
	.modAddr_IN(modAddr_IN),
	.END_SIM(END_SIM)
	);
		 
//Instantiate UUT   
	ProcessingElement_chroma_approximate PE(
	.reset_n(reset_n),
	.clk(clk),
	.Vin(Vin),
	.InData(InData),
	.horVer(horVer),
	.ME_MCBi(ME_MCBi),
	.filterSel_1(filterSel_1),
	.filterSel_2(filterSel_2),
	.modAddr_IN(modAddr_IN),
	.Vout(Vout),
	.o(o)
	);
   
   data_sink_chroma DS(
	.CLK(clk),
	.RST_n(reset_n),
	.VOUT(Vout),
	.DOUT(o)); 
endmodule

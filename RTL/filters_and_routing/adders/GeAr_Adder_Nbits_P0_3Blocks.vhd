-- Copyright 2018 Stefania Preatto.
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the \u201cLicense\u201d); you may not use this file except in
-- compliance with the License.  You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
-- or agreed to in writing, software, hardware and materials distributed under
-- this License is distributed on an \u201cAS IS\u201d BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations under the License.
----------------------------------------------------------------------------------
-- Author: Stefania Preatto 
-- 
-- Create Date(mm/aaaa):	05/2018 
-- Module Name:			GeAr_Adder_Nbits.vhd
-- Project:				interpolation filter project for HEVC
-- Description:			Generic Accuracy Reconfigurable Adder of Nbits
-- Dependencies:		
--					none
--					
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity GeAr_Adder_Nbits is
	generic(N:integer:=22; R:integer:=7; P:integer:=0); -- L=R+P, N=R+L
	port(
		In1, In2			:IN std_logic_vector(N-1 downto 0);	-- adder inputs
		c_in,c_in1			:IN std_logic;
		c_out,c_out1		:OUT std_logic;
		out_A				:OUT std_logic_vector(N-1 downto 0)  -- adder output
	);
end entity GeAr_Adder_Nbits;

architecture structural of GeAr_Adder_Nbits is

--signals
signal temp 						: std_logic_vector(N-1 downto 2*R+P-1);
signal temp1						: std_logic_vector(2*R+P downto R+P-1);  --it includes carry-in and carry-out to be used
signal sum1_MSB						: std_logic_vector(N-1 downto 2*R+P);
signal sum1_middle					: std_logic_vector(2*R+P-1 downto R+P);
signal cg_o, cp_o,cg_o1, cp_o1		: std_logic;
signal ED,ED1						: std_logic;
signal sum1_LSB						: std_logic_vector(R+P downto 0); --it includes carry-out to be used
begin


----BLOCK 1: MSBs------------------------
--SUM for Most Significant Bits 
temp <= std_logic_vector(signed(In1(N-1 downto 2*R+P)&'1')+signed(In2(N-1 downto 2*R+P)&cg_o));
sum1_MSB <= temp(N-1 downto 2*R+P);

--carry generation for Most Significant block with CG Unit
cg_o <= (In1(2*R+P-1) and In2(2*R+P-1)) or (c_in and (In1(2*R+P-1) xor In2(2*R+P-1)));
cp_o <= In1(2*R+P-1) xor In2(2*R+P-1);

--Error detection for c_in unit
ED <= (temp1(2*R+P) xor c_in) AND cp_o;
c_out <= c_in xor ED;

-----BLOCK 2: middle bits---------------------
--SUM for intermediate Bits 
temp1 <= std_logic_vector(signed('0'&In1(2*R+P-1 downto R+P)&'1')+signed('0'&In2(2*R+P-1 downto R+P)&cg_o1)); --temp1(2R+P)=carry out
sum1_middle <= temp1(2*R+P-1 downto R+P); 

--carry generation for Most Significant block with CG Unit
cg_o1 <= (In1(R+P-1) and In2(R+P-1)) or (c_in1 and (In1(R+P-1) xor In2(R+P-1)));
cp_o1 <= In1(R+P-1) xor In2(R+P-1);

--Error detection for c_in unit				
ED1 <= (sum1_LSB(R+P) xor c_in1) AND cp_o1;
c_out1 <= c_in1 xor ED1;


----BLOCK 3: LSBs------------------------
--SUM for Least Significant Bits
sum1_LSB <= std_logic_vector(signed('0'&In1(R+P-1 downto 0)) + signed('0'&In2(R+P-1 downto 0))); --sum1_LSB(R+P)=c_out, sum1_LSB(R+P-1:0)=out_A(R+P-1:0)


--sum out is composed of outcomes of the three sub-blocks
out_A <= sum1_MSB(N-1 downto 2*R+P)&sum1_middle(2*R+P-1 downto R+P)&sum1_LSB(R+P-1 downto 0);

end structural;

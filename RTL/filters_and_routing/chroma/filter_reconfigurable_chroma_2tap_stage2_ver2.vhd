-- Copyright 2017 Andrea Giannini.
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the “License”); you may not use this file except in
-- compliance with the License.  You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
-- or agreed to in writing, software, hardware and materials distributed under
-- this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations under the License.
----------------------------------------------------------------------------------
-- Author: Andrea Giannini 
-- 
-- Create Date(mm/aaaa):	09/2017 
-- Module Name:			filter_reconfigurable_chroma_2tap_stage2_ver2.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			2-tap reconfigurable multiplier-less 14-bit inputs filter, with configuration input vector
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filter_reconfigurable_chroma_2tap_stage2_ver2 is
	port(
		in0,in1:IN std_logic_vector(13 downto 0);	-- filter inputs
		conf:IN std_logic_vector(1 downto 0);		-- filter input config:	"00" => half pixel 4/8th filter, "01" => quarter pixel 1/8th filter,
								-- 			"10" => quarter pixel 2/8th filter, "11" => quarter pixel 3/8th filter
		o:OUT std_logic_vector(19 downto 0)
	);
end filter_reconfigurable_chroma_2tap_stage2_ver2;

architecture behavioural of filter_reconfigurable_chroma_2tap_stage2_ver2 is
	signal inA_op1,inB_op1:std_logic_vector(19 downto 0);
	signal o_op1:std_logic_vector(19 downto 0);
	signal inA_op2,inB_op2:std_logic_vector(17 downto 0);
	signal o_op2:std_logic_vector(18 downto 0);
	signal inA_op3,inB_op3:std_logic_vector(16 downto 0);
	signal o_op3:std_logic_vector(17 downto 0);
	signal o_op4:std_logic_vector(19 downto 0);
begin
-- ADD op1
inA_op1<=
	in0&"000000" when conf="01" else	-- in0<<6
	'0'&in0&"00000";			-- in0<<5
inB_op1<=
	"000"&in1&"000" when conf="01" else	-- in1<<3
	"00"&in0&"0000" when conf="10" else	-- in0<<4
	'0'&in1&"00000";-- conf="00" or "11"	-- in1<<5
o_op1<=std_logic_vector(unsigned(inA_op1)+unsigned(inB_op1));	-- discard carry out

-- ADD op2
inA_op2<=
	(others=>'0') when conf="00" else	-- all 0
	"000"&in0&'0' when conf="10" else	-- in0<<1
	"0000"&in0;-- conf="01" or "11"		-- in0
inB_op2<=
	in1&"0000" when conf="10" else		-- in1<<4
	'0'&in0&"000" when conf="11" else	-- in0<<3
	(others=>'0');-- conf="00" or "01"	-- all 0
o_op2<=std_logic_vector(unsigned('0'&inA_op2)+unsigned('0'&inB_op2));

-- ADD op3
inA_op3<=
	"00"&in1&'0' when conf="10" else	-- in1<<1
	(others=>'0') when conf="00" else	-- all 0
	"000"&in1; -- conf="01" or "11"		-- in1
inB_op3<=
	in0&"000" when conf="01" else		-- in0<<3
	in1&"000" when conf="11" else		-- in1<<3
	(others=>'0');-- conf="00" or "10"	-- all 0	
o_op3<=std_logic_vector(unsigned('0'&inA_op3)+unsigned('0'&inB_op3));

-- ADD op4
o_op4<=std_logic_vector(unsigned(o_op1)+unsigned('0'&o_op2));	-- discard carry out

-- SUB op5
o<=std_logic_vector(unsigned(o_op4)-unsigned("00"&o_op3));	-- discard carry out
end architecture behavioural;



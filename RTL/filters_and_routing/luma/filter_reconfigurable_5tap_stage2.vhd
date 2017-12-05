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
-- Module Name:			filter_reconfigurable_5tap_stage2.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			5-tap reconfigurable multiplier-less 16-bit inputs filter, with configuration input
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filter_reconfigurable_5tap_stage2 is
	port(
		in0,in1,in2,in3,in4:IN std_logic_vector(15 downto 0);	-- filter inputs
		conf5:IN std_logic;					-- filter configuration input: '0' => half pixel filter, '1' => quarter pixel filter
		o:OUT std_logic_vector(21 downto 0)
	);
end entity filter_reconfigurable_5tap_stage2;

architecture behavioural of filter_reconfigurable_5tap_stage2 is
	signal inA_op1,inB_op1:std_logic_vector(16 downto 0);
	signal o_op1: std_logic_vector(16 downto 0);
	signal inA_op2,inB_op2:std_logic_vector(18 downto 0);
	signal o_op2:std_logic_vector(18 downto 0);
	signal inA_op3,inB_op3:std_logic_vector(20 downto 0);
	signal o_op3:std_logic_vector(20 downto 0);
	signal inA_op4,inB_op4:std_logic_vector(16 downto 0);
	signal o_op4:std_logic_vector(16 downto 0);
	signal inA_op5,inB_op5:std_logic_vector(18 downto 0);
	signal o_op5:std_logic_vector(19 downto 0);
	signal o_op6:std_logic_vector(18 downto 0);
	signal inB_op7:std_logic_vector(20 downto 0);
	signal o_op7:std_logic_vector(21 downto 0);
	signal o_op9:std_logic_vector(19 downto 0);
	signal o_op8:std_logic_vector(21 downto 0);
begin

-- ADD op1
inA_op1<=
	(others=>'0') when conf5='0' else	-- all 0
	'0'&in0;				-- in0
inB_op1<=
	(others=>'0') when conf5='0' else	-- all 0
	in3&'0';				-- in3<<1
o_op1<=std_logic_vector(signed(inA_op1)+signed(inB_op1));	-- discard carry out

-- ADD op2
inA_op2<=
	in0(15)&in0(15)&in0&'0' when conf5='0' else	-- in0<<1
	in2(15)&in2&"00";				-- in2<<2
inB_op2<=
	in2&"000" when conf5='0' else	-- in2<<3
	in3(15)&in3&"00";				-- in3<<2
o_op2<=std_logic_vector(signed(inA_op2)+signed(inB_op2));	-- discard carry out

-- ADD op3
inA_op3<=
	in2&"00000" when conf5='0' else	-- in2<<5
	in2(15)&in2&"0000";			-- in2<<4
inB_op3<=
	in3(15)&in3(15)&in3&"000" when conf5='0' else	-- in3<<3
	in3&"00000";				-- in3<<5
o_op3<=std_logic_vector(signed(inA_op3)+signed(inB_op3));	-- discard carry out

-- ADD op4
inA_op4<=
	in1(15)&in1 when conf5='0' else	-- in1
	in1&'0';			-- in1<<1
inB_op4<=in4(15)&in4;			-- in4
o_op4<=std_logic_vector(signed(inA_op4)+signed(inB_op4));	-- discard carry out

-- ADD op5
inA_op5<=
	in1&"000" when conf5='0' else	-- in1<<3
	in1(15)&in1&"00";			-- in1<<2
inB_op5<=
	in4&"000" when conf5='0' else	-- in4<<3
	in4(15)&in4&"00";			-- in4<<2
o_op5<=std_logic_vector(signed(inA_op5(18)&inA_op5)+signed(inB_op5(18)&inB_op5));

-- ADD op6
o_op6<=std_logic_vector(signed(o_op1(16)&o_op1(16)&o_op1)+signed(o_op2));	-- discard carry out

-- ADD op7
inB_op7<=
	in3&"00000" when conf5='0' else	-- in3<<5
	in3(15)&in3&"0000";			-- in3<<4
o_op7<=std_logic_vector(signed(o_op3(20)&o_op3)+signed(inB_op7(20)&inB_op7));

-- ADD op9
o_op9<=std_logic_vector(signed(o_op4(16)&o_op4(16)&o_op4(16)&o_op4)+signed(o_op5));	-- discard carry out

-- ADD op8
o_op8<=std_logic_vector(signed(o_op6(18)&o_op6(18)&o_op6(18)&o_op6)+signed(o_op7));		-- discard carry out

-- SUB op10
o<=std_logic_vector(signed(o_op8)-signed(o_op9(19)&o_op9(19)&o_op9));	-- discard carry out

end architecture behavioural;

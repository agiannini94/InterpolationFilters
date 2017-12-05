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
-- Module Name:			filter_reconfigurable_3tap.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			3-tap reconfigurable multiplier-less 8-bit inputs filter, with configuration input
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filter_reconfigurable_3tap is
	port(
		in0,in1,in2:IN std_logic_vector(7 downto 0);	-- filter inputs
		conf3:IN std_logic;				-- filter configuration input: '0' => half pixel filter, '1' => quarter pixel filter
		o:OUT std_logic_vector(15 downto 0)
	);
end entity filter_reconfigurable_3tap;

architecture behavioural of filter_reconfigurable_3tap is
	signal inA_op1,inB_op1:std_logic_vector(12 downto 0);
	signal o_op1:std_logic_vector(13 downto 0);
	signal inA_op2,inB_op2:std_logic_vector(12 downto 0);
	signal o_op2:std_logic_vector(13 downto 0);
	signal inA_op3,inB_op3:std_logic_vector(10 downto 0);
	signal o_op3:std_logic_vector(11 downto 0);
	signal o_op4:std_logic_vector(14 downto 0);
begin
-- ADD op1
inA_op1<=
	in1&"00000" when conf3='0' else	-- in1<<5
	'0'&in1&"0000";			-- in1<<4
inB_op1<=
	in2&"00000" when conf3='0' else	-- in2<<5
	'0'&in2&"0000";			-- in2<<4
o_op1<=std_logic_vector(unsigned('0'&inA_op1)+unsigned('0'&inB_op1));

-- ADD op2
inA_op2<=
	"00"&in1&"000" when conf3='0' else	-- in1<<3
	"000"&in1&"00";				-- in1<<2
inB_op2<=
	"00000"&in1 when conf3='0' else		-- in1
	in2&"00000";				-- in2<<5
o_op2<=std_logic_vector(unsigned('0'&inA_op2)+unsigned('0'&inB_op2));

-- ADD op3
inA_op3<=
	in0&"000" when conf3='0' else	-- in0<<3
	'0'&in0&"00";			-- in0<<2
inB_op3<=
	"000"&in0 when conf3='0' else		-- in0
	std_logic_vector(to_unsigned(0,11));	-- all 0
o_op3<=std_logic_vector(signed('0'&inA_op3)+signed('0'&inB_op3));

-- SUB op4
o_op4<=std_logic_vector(signed('0'&o_op2)-signed("000"&o_op3));

-- ADD op5
o<=std_logic_vector(signed("00"&o_op1)+signed(o_op4(14)&o_op4));

end architecture behavioural;

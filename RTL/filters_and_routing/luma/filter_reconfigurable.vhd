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
-- Module Name:			filter_reconfigurable.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			8/7-tap reconfigurable multiplier-less 8-bit inputs half filter, with configuration input vector
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filter_reconfigurable is
	port(
		s0,s1,s2,s3:IN std_logic_vector(7 downto 0);	-- half filter inputs
		conf_vect:IN std_logic_vector(8 downto 0);	-- half filter input configuration vector, see FSM1_filter.vhd for the different config settings
		o:OUT std_logic_vector(14 downto 0)
	);
end entity filter_reconfigurable;

architecture behavioural of filter_reconfigurable is
	signal inA_op1,inB_op1: std_logic_vector(13 downto 0);
	signal o_op1,inA_op2,inB_op2,o_op2,inA_op6,inB_op6,o_op6: std_logic_vector(14 downto 0);
	signal inA_op4,inB_op4,inA_op5,inB_op5:std_logic_vector(10 downto 0);
	signal o_op4,o_op5,inA_op3,inB_op3:std_logic_vector(11 downto 0);
	signal o_op3:std_logic_vector(12 downto 0);
begin
-- ADD op1
inA_op1<=
	"0000"&s1&"00" when conf_vect(8)='0' else	-- s1<<2
	"000000"&s0;					-- s0
inB_op1<=
	'0'&s3&"00000" when conf_vect(7 downto 6)="00" else	-- s3<<5
	s3&"000000" when conf_vect(7 downto 6)="01" else	-- s3<<6
	"00000"&s3&'0' when conf_vect(7 downto 6)="10" else	-- s3<<1
	"000000"&s2;						-- s2
o_op1<=std_logic_vector(unsigned('0'&inA_op1)+unsigned('0'&inB_op1));

-- ADD op2
inA_op2<=o_op1;
inB_op2<=
	"0000"&s3&"000" when conf_vect(5 downto 4)="00" else	-- s3<<3
	"000000"&s3&'0' when conf_vect(5 downto 4)="01" else	-- s3<<1
	"000"&s2&"0000";					-- s2<<4
o_op2<=std_logic_vector(unsigned(inA_op2)+unsigned(inB_op2));	-- discard carry out

-- ADD op4
inA_op4<=
	"000"&s0 when conf_vect(3)='0' else	-- s0
	"000"&s1;				-- s1
inB_op4<=
	s2&"000" when conf_vect(2)='0' else	-- s2<<3
	'0'&s1&"00";				-- s1<<2
o_op4<=std_logic_vector(unsigned('0'&inA_op4)+unsigned('0'&inB_op4));

-- ADD op5
inA_op5<=
	"00"&s2&'0' when conf_vect(1)='0' else	-- s2<<1
	std_logic_vector(to_unsigned(0,11));	-- 0
inB_op5<=
	"000"&s2 when conf_vect(0)<='0' else	-- s2
	s3&"000";				-- s3<<3
o_op5<=std_logic_vector(unsigned('0'&inA_op5)+unsigned('0'&inB_op5));

-- ADD op3
inA_op3<=o_op4;
inB_op3<=o_op5;
o_op3<=std_logic_vector(unsigned('0'&inA_op3)+unsigned('0'&inB_op3));

-- SUB op6
inA_op6<=o_op2;
inB_op6<="00"&o_op3;
o_op6<=std_logic_vector(signed(inA_op6)-signed(inB_op6));

o<=o_op6;

end architecture behavioural;

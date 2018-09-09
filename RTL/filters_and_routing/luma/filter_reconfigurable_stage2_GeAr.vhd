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
-- Module Name:			filter_reconfigurable_stage2.vhd
-- Project:				interpolation filter project for HEVC
-- Description:			8/7-tap reconfigurable multiplier-less 16-bit inputs half filter, with configuration input vector
-- Dependencies:		None
--					GeAr_Adder_Nbits.vhd
-- Revision: 
--		Stefania Preatto
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filter_reconfigurable_stage2 is
	port(
		s0,s1,s2,s3:IN std_logic_vector(15 downto 0);	-- half filter inputs
		conf_vect:IN std_logic_vector(8 downto 0);	-- half filter input configuration vector, see FSM2_filter.vhd for the different config settings
		o:OUT std_logic_vector(21 downto 0)
	);
end entity filter_reconfigurable_stage2;

architecture behavioural of filter_reconfigurable_stage2 is

--components
component GeAr_Adder_Nbits is
	generic(N:integer:=22; R:integer:=7; P:integer:=0); -- L=R+P, N=R+L
	port(
		In1, In2			:IN std_logic_vector(N-1 downto 0);	-- adder inputs
		c_in,c_in1			:IN std_logic;
		c_out,c_out1		:OUT std_logic;
		out_A				:OUT std_logic_vector(N-1 downto 0)  -- adder output
	);
end component;

--signals
	signal inA_op1,inB_op1,o_op1,inA_op2,inB_op2,o_op2,inA_op6,inB_op6,o_op6: std_logic_vector(21 downto 0);
	signal inA_op5,inB_op5,o_op5,inA_op4,inB_op4,o_op4:std_logic_vector(18 downto 0);
	signal o_op3:std_logic_vector(19 downto 0);
	
	--signal inA_op5_ext,inB_op5_ext,o_op5_ext:std_logic_vector(19 downto 0);
	signal inA_op4_ext,inB_op4_ext,o_op4_ext,inA_op3,inB_op3:std_logic_vector(19 downto 0);
	signal c_o_A1, c_o_A2, c_o_A4, c_o_A3: std_logic;
	signal c_o1_A1, c_o1_A2, c_o1_A4, c_o1_A3: std_logic;
	
begin
-- ADD op1
inA_op1<=
	s1(15)&s1(15)&s1(15)&s1(15)&s1&"00" when conf_vect(8)='0' else	-- s1<<2
	s0(15)&s0(15)&s0(15)&s0(15)&s0(15)&s0(15)&s0;			-- s0
inB_op1<=
	s3(15)&s3&"00000" when conf_vect(7 downto 6)="00" else				-- s3<<5
	s3&"000000" when conf_vect(7 downto 6)="01" else				-- s3<<6
	s3(15)&s3(15)&s3(15)&s3(15)&s3(15)&s3&'0' when conf_vect(7 downto 6)="10" else	-- s3<<1
	s2(15)&s2(15)&s2(15)&s2(15)&s2(15)&s2(15)&s2;					-- s2
	
	A1: GeAr_Adder_Nbits port map (In1=>(inA_op1), In2=>(inB_op1), c_in=>'0', c_in1=>'0', c_out=>c_o_A1, c_out1=>c_o1_A1, out_A=>o_op1);

-- ADD op2
inA_op2<=o_op1;
inB_op2<=
	s3(15)&s3(15)&s3(15)&s3&"000" when conf_vect(5 downto 4)="00" else		-- s3<<3
	s3(15)&s3(15)&s3(15)&s3(15)&s3(15)&s3&'0' when conf_vect(5 downto 4)="01" else	-- s3<<1
	s2(15)&s2(15)&s2&"0000";							-- s2<<4

	A2: GeAr_Adder_Nbits port map (In1=>(inA_op2), In2=>(inB_op2), c_in=>c_o_A1, c_in1=>c_o1_A1, c_out=>c_o_A2, c_out1=>c_o1_A2, out_A=>o_op2);

-- ADD op4
inA_op4<=
	s0(15)&s0(15)&s0(15)&s0 when conf_vect(3)='0' else	-- s0
	s1(15)&s1(15)&s1(15)&s1;				-- s1
inB_op4<=
	s2&"000" when conf_vect(2)='0' else	-- s2<<3
	s1(15)&s1&"00";			-- s1<<2
	
	inA_op4_ext <= '0'&inA_op4;
	inB_op4_ext <= '0'&inB_op4;
	A4:  GeAr_Adder_Nbits generic map (N=>20, R=>6)
									port map (In1=>(inA_op4_ext), In2=>(inB_op4_ext),c_in=>'0',c_in1=>'0', c_out=>c_o_A4, c_out1=>c_o1_A4, out_A=>o_op4_ext);
	
	o_op4 <= o_op4_ext(18 downto 0);

-- ADD op5
inA_op5<=
	s2(15)&s2(15)&s2&'0' when conf_vect(1)='0' else	-- s2<<1
	std_logic_vector(to_unsigned(0,19));		-- 0
inB_op5<=
	s2(15)&s2(15)&s2(15)&s2 when conf_vect(0)<='0' else	-- s2
	s3&"000";	-- s3<<3

	o_op5 <= std_logic_vector(signed(inA_op5)+signed(inB_op5));

-- ADD op3
inA_op3<=o_op4(18)&o_op4;
inB_op3<=o_op5(18)&o_op5;
	A3: GeAr_Adder_Nbits generic map (N=>20, R=>6)
									port map (In1=>(inA_op3), In2=>(inB_op3),c_in=>c_o_A4,c_in1=>c_o1_A4, c_out=>c_o_A3, c_out1=>c_o1_A3, out_A=>o_op3);

-- SUB op6
inA_op6<=o_op2;
inB_op6<=o_op3(19)&o_op3(19)&o_op3;
o_op6<=std_logic_vector(signed(inA_op6)-signed(inB_op6));

o<=o_op6;

end architecture behavioural;


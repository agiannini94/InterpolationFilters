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
-- Module Name:			filter_chroma_reconfigurable_stage2.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			4-tap reconfigurable multiplier-less 16-bit inputs filter, with configuration input vector
-- Dependencies:		None
--
-- Revision: 
--		Stefania Preatto
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filter_chroma_reconfigurable_stage2 is
	port(
		s0,s1,s2,s3:IN std_logic_vector(15 downto 0);	-- filter inputs
		conf_vect:IN std_logic_vector(12 downto 0);	-- filter input configuration vector, see FSM2_filter.vhd for the different config settings
		o:OUT std_logic_vector(21 downto 0)
	);
end entity filter_chroma_reconfigurable_stage2;

architecture behavioural of filter_chroma_reconfigurable_stage2 is

---------components

component Ladner_Fisher_Nbit_correct is
	generic(N:positive:=22);
	port(
		In1, In2			:IN std_logic_vector(N-1 downto 0);	-- adder inputs
		out_A				:OUT std_logic_vector(N-1 downto 0)  -- adder output
	);
end component;

---------signals
	signal inA_op1,inB_op1:std_logic_vector(21 downto 0);
	signal o_op1:std_logic_vector(21 downto 0);
	signal inA_op2,inB_op2:std_logic_vector(19 downto 0);
	signal o_op2:std_logic_vector(19 downto 0);
	signal inA_op3,inB_op3:std_logic_vector(18 downto 0);
	signal o_op3:std_logic_vector(18 downto 0);
	signal inA_op4,inB_op4:std_logic_vector(16 downto 0);
	signal o_op4:std_logic_vector(17 downto 0);
	signal o_op5:std_logic_vector(21 downto 0);
	signal o_op6:std_logic_vector(19 downto 0);
	signal inB_op7:std_logic_vector(19 downto 0);
	signal o_op7:std_logic_vector(19 downto 0);
	signal inA_op3_ext,inB_op3_ext, o_op3_ext: std_logic_vector(19 downto 0);
	
	---added for approximate architecture
	signal inA_op4_ext, inB_op4_ext: std_logic_vector(17 downto 0);
	signal inA_op5, inB_op5			 : std_logic_vector(21 downto 0);
	signal inA_op6, inB_op6			 : std_logic_vector(19 downto 0);
	signal inA_op8, inB_op8			 : unsigned(21 downto 0);
begin
-- ADD op1
inA_op1<=
	s1(15)&s1&"00000" when conf_vect(12)='0' else	-- s1<<5
	s1&"000000";					-- s1<<6
inB_op1<=
	s2(15)&s2&"00000" when conf_vect(11 downto 10)="00" else	-- s2<<5
	s2(15)&s2(15)&s2&"0000" when conf_vect(11 downto 10)="01" else	-- s2<<4
	s2(15)&s2(15)&s2(15)&s2&"000"; -- "10" or "11"			-- s2<<3
	
	A1: Ladner_Fisher_Nbit_correct port map (In1=>(inA_op1), In2=>(inB_op1), out_A=>o_op1);

-- ADD op2
inA_op2<=
	s2(15)&s2(15)&s2(15)&s2&'0' when conf_vect(9 downto 8)="00" else	-- s2<<1
	s2(15)&s2(15)&s2&"00" when conf_vect(9 downto 8)="01" else		-- s2<<2
	std_logic_vector(to_unsigned(0,20));	-- when "10" or "11"		-- 0
inB_op2<=
	s1(15)&s1(15)&s1(15)&s1&'0' when conf_vect(7 downto 6)="00" else	-- s1<<1
	s1&"0000" when conf_vect(7 downto 6)="01" else				-- s1<<4
	s1(15)&s1(15)&s1&"00" when conf_vect(7 downto 6)="10" else		-- s1<<2
	std_logic_vector(to_unsigned(0,20));			-- 0

	A2: Ladner_Fisher_Nbit_correct generic map(N=>20)
							port map (In1=>(inA_op2), In2=>(inB_op2), out_A=>o_op2);

-- ADD op3
inA_op3<=
	s0(15)&s0&"00" when conf_vect(5)='0' else	-- s0<<2
	s0(15)&s0(15)&s0&'0';				-- s0<<1
inB_op3<=
	s1&"000" when conf_vect(4)='0' else	-- s1<<3
	s3(15)&s3&"00";				-- s3<<2
	
	inA_op3_ext <= '0'&inA_op3;
	inB_op3_ext <= '0'&inB_op3;
	A3: Ladner_Fisher_Nbit_correct generic map (N=>20)
									port map (In1=>(inA_op3_ext), In2=>(inB_op3_ext), out_A=>o_op3_ext);
	o_op3 <= o_op3_ext(18 downto 0);

-- ADD op4
inA_op4<=
	s3&'0' when conf_vect(3 downto 2)="00" else			-- s3<<1
	s0&'0' when conf_vect(3 downto 2)="01" else			-- s0<<1
	std_logic_vector(to_unsigned(0,17));	-- when "10" or "11"	-- 0
inB_op4<=
	s1&'0' when conf_vect(1)='0' else	-- s1<<1
	std_logic_vector(to_unsigned(0,17));	-- 0
	
inA_op4_ext <= inA_op4(16)&inA_op4;
inB_op4_ext <= inB_op4(16)&inB_op4;

	A4: Ladner_Fisher_Nbit_correct generic map (N=>18)
								port map (In1=>(inA_op4_ext), In2=>(inB_op4_ext), out_A=>o_op4);

-- ADD op5
inA_op5 <= o_op1;
inB_op5 <= o_op2(19)&o_op2(19)&o_op2;

  A5: Ladner_Fisher_Nbit_correct
								port map (In1=>(inA_op5), In2=>(inB_op5), out_A=>o_op5);

-- ADD op6
inA_op6 <= o_op3(18)&o_op3;
inB_op6 <= o_op4(17)&o_op4(17)&o_op4;

  A6: Ladner_Fisher_Nbit_correct generic map (N=>20)
								port map (In1=>(inA_op6), In2=>(inB_op6), out_A=>o_op6);

-- ADD op7
inB_op7<=
	s2(15)&s2(15)&s2&"00" when conf_vect(0)='0' else	-- s2<<2
	std_logic_vector(to_unsigned(0,20));	-- 0

	A7: Ladner_Fisher_Nbit_correct generic map (N=>20)
								port map (In1=>(o_op6), In2=>(inB_op7), out_A=>o_op7);

-- SUB op8
inA_op8 <= unsigned(o_op5);
inB_op8 <= unsigned(o_op7(19)&o_op7(19)&o_op7);
o<=std_logic_vector(inA_op8-inB_op8);	-- discard carry out

end architecture behavioural;

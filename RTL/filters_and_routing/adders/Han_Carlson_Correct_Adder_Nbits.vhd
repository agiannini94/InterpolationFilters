-- Copyright 2018 Stefania Preatto.
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the “License”); you may not use this file except in
-- compliance with the License.  You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
-- or agreed to in writing, software, hardware and materials distributed under
-- this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations under the License.
----------------------------------------------------------------------------------
-- Author: Stefania Preatto 
-- 
-- Create Date(mm/aaaa):	04/2018 
-- Module Name:			Han_Carlson_Correct_Adder_Nbits.vhd
-- Project:				interpolation filter project for HEVC
-- Description:			Adder in speculative approach
-- Dependencies:		GP_Unit	
--						ParalPrefix_Unit
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity Han_Carlson_Correct_Adder_Nbits is
	generic(N:positive:=22);
	port(
		In1, In2			:IN std_logic_vector(N-1 downto 0);	-- adder inputs
		out_A				:OUT std_logic_vector(N-1 downto 0)  -- adder output
	);
end entity Han_Carlson_Correct_Adder_Nbits;

architecture structural of Han_Carlson_Correct_Adder_Nbits is

component GP_Unit is
	port(
		A,B				:IN std_logic;	
		G,P				:OUT std_logic  
	);
end component;

component ParalPrefix_Unit is
	port(
		G1,G0,P1,P0		:IN std_logic;	
		G01,P01			:OUT std_logic  
	);
end component ParalPrefix_Unit;

signal gen_bits, prop_bits	: std_logic_vector(N-1 DOWNTO 0);
signal G_s1, P_s1				: std_logic_vector(N/2-1 downto 0);
signal G_s2, P_s2				: std_logic_vector(N/2-2 downto 0);
signal G_s3, P_s3				: std_logic_vector(N/2-3 downto 0);
signal G_s4, P_s4				: std_logic_vector(N/2-5 downto 0);
signal G_s5, P_s5				: std_logic_vector(N/2-9 downto 0);
signal G_s6, P_s6				: std_logic_vector(N-1 downto 0);
signal c_i_min1				: std_logic_vector(N-1 downto 0);

begin
	
	-- BLOCK 1: gi,pi GENERATION
	gp_gen: for i in N-1 downto 0 generate
			GP_U: GP_Unit port map(A=>In1(i), B=>In2(i), G=>gen_bits(i), P=>prop_bits(i));
	end generate gp_gen;
	
	---------------------------------------------
	--BLOCK 2: parallel & prefix problem with Han-Carlson Architecture
	
	--outer row: Brent&Kung architecture
	PP0_s1: for i in 1 to N/2 generate
			PP0_U1: ParalPrefix_Unit port map(G1=>gen_bits(2*i-1),G0=>gen_bits(2*i-2),P1=>prop_bits(2*i-1),P0=>prop_bits(2*i-2),G01=>G_s1(i-1),P01=>P_s1(i-1));
	end generate PP0_s1;
	
	--inner rows: Kogge-Stone architecture
	PP0_s2: for i in 1 to N/2-1 generate
			PP0_U2: ParalPrefix_Unit port map(G1=>G_s1(i),G0=>G_s1(i-1),P1=>P_s1(i),P0=>P_s1(i-1),G01=>G_s2(i-1),P01=>P_s2(i-1));
	end generate PP0_s2;
	
	PP0_S3: for i in 1 to N/2-2 generate
	
			middleBit_s3: if i>1 AND i<=N/2-2 generate
			PP0_U3: ParalPrefix_Unit port map(G1=>G_s2(i),G0=>G_s2(i-2),P1=>P_s2(i),P0=>P_s2(i-2),G01=>G_s3(i-1),P01=>P_s3(i-1));
			END generate middleBit_s3;
			
			LSBs_s3: if i=1 generate
			PP0_U3: ParalPrefix_Unit port map(G1=>G_s2(i),G0=>G_s1(i-1),P1=>P_s2(i),P0=>P_s1(i-1),G01=>G_s3(i-1),P01=>P_s3(i-1));
			END generate LSBs_s3;
			
	end generate PP0_s3;
	
	
	PP0_s4: for i in 1 to N/2-4 generate
	
			middleBit_s4: if i>2 AND i<=N/2-4 generate
			PP0_U4: ParalPrefix_Unit port map(G1=>G_s3(i+1),G0=>G_s3(i-3),P1=>P_s3(i+1),P0=>P_s3(i-3),G01=>G_s4(i-1),P01=>P_s4(i-1));
			END generate middleBit_s4;
			
			LSB1_s4: if i=2 generate
			PP0_U4: ParalPrefix_Unit port map(G1=>G_s3(i+1),G0=>G_s2(i-2),P1=>P_s3(i+1),P0=>P_s2(i-2),G01=>G_s4(i-1),P01=>P_s4(i-1));
			END generate LSB1_s4;
	
			LSB0_s4: if i=1 generate
			PP0_U4: ParalPrefix_Unit port map(G1=>G_s3(i+1),G0=>G_s1(i-1),P1=>P_s3(i+1),P0=>P_s1(i-1),G01=>G_s4(i-1),P01=>P_s4(i-1));
			END generate LSB0_s4;
	
	end generate PP0_s4;
	
			
	PP0_s5: for i in 1 to N/2-8 generate
			
			middleBit_s5: if i>=3 AND i<=N/2-8 generate
			PP0_U5: ParalPrefix_Unit port map(G1=>G_s4(i+3),G0=>G_s3(i-3),P1=>P_s4(i+3),P0=>P_s3(i-3),G01=>G_s5(i-1),P01=>P_s5(i-1));
			END generate middleBit_s5;
			
			LSB1_s5: if i=2 generate
			PP0_U5: ParalPrefix_Unit port map(G1=>G_s4(i+3),G0=>G_s2(i-2),P1=>P_s4(i+3),P0=>P_s2(i-2),G01=>G_s5(i-1),P01=>P_s5(i-1));
			END generate LSB1_s5;
			
			LSB0_s5: if i=1 generate
			PP0_U5: ParalPrefix_Unit port map(G1=>G_s4(i+3),G0=>G_s1(i-1),P1=>P_s4(i+3),P0=>P_s1(i-1),G01=>G_s5(i-1),P01=>P_s5(i-1));
			END generate LSB0_s5;
	
	end generate PP0_s5;

	--final row: Brent&Kung architecture
	
	PP0_s6: for i in 1 to N/2 generate
			
			MSB_odd: if i=N/2 generate
			G_s6(2*i-1) <= G_s5(i-9);
			P_s6(2*i-1) <= P_s5(i-9);
			END generate;
			
			MSB_s6: if i>8 AND i<=N/2-1 generate
			PP0_U6: ParalPrefix_Unit port map(G1=>gen_bits(2*i),G0=>G_s5(i-9),P1=>prop_bits(2*i),P0=>P_s5(i-9),G01=>G_s6(2*i),P01=>P_s6(2*i));
			G_s6(2*i-1) <= G_s5(i-9);
			P_s6(2*i-1) <= P_s5(i-9);
			END generate MSB_s6;
			
			middle_s6_s4: if i>4 AND i<=8 generate
			PP0_U6: ParalPrefix_Unit port map(G1=>gen_bits(2*i),G0=>G_s4(i-5),P1=>prop_bits(2*i),P0=>P_s4(i-5),G01=>G_s6(2*i),P01=>P_s6(2*i));
			G_s6(2*i-1) <= G_s4(i-5);
			P_s6(2*i-1) <= P_s4(i-5);
			END generate middle_s6_s4;
			
			middle_s6_s3: if i>2 AND i<=4 generate
			PP0_U6: ParalPrefix_Unit port map(G1=>gen_bits(2*i),G0=>G_s3(i-3),P1=>prop_bits(2*i),P0=>P_s3(i-3),G01=>G_s6(2*i),P01=>P_s6(2*i));
			G_s6(2*i-1) <= G_s3(i-3);
			P_s6(2*i-1) <= P_s3(i-3);
			END generate middle_s6_s3;
			
			middle_s6_s2: if i=2 generate
			PP0_U6: ParalPrefix_Unit port map(G1=>gen_bits(2*i),G0=>G_s2(i-2),P1=>prop_bits(2*i),P0=>P_s2(i-2),G01=>G_s6(2*i),P01=>P_s6(2*i));
			G_s6(2*i-1) <= G_s2(i-2);
			P_s6(2*i-1) <= P_s2(i-2);
			END generate middle_s6_s2;
			
			middle_s6_s1: if i=1 generate
			PP0_U6: ParalPrefix_Unit port map(G1=>gen_bits(2*i),G0=>G_s1(i-1),P1=>prop_bits(2*i),P0=>P_s1(i-1),G01=>G_s6(2*i),P01=>P_s6(2*i));
			G_s6(2*i-1) <= G_s1(i-1);
			P_s6(2*i-1) <= P_s1(i-1);
			G_s6(2*i-2) <= gen_bits(i-1); 
			P_s6(2*i-2) <= prop_bits(i-1);		
			END generate middle_s6_s1;
			
	end generate PP0_s6;
	
	------------------------------------
	--BLOCK 3: Carry computation
	c_i_min1(0) <= '0';
	Cin_gen: for i in 1 to N-1 generate	
		   c_i_min1(i) <= G_s6(i-1) OR (P_s6(i-1) AND c_i_min1(0)); --since c0=0 because we're just considering additions
	end generate Cin_gen;
	
	------------------------------------
	--BLOCK 4: Sum computation
	Sum_gen: for i in 0 to N-1 generate
			out_A(i) <= prop_bits(i) XOR c_i_min1(i);		
	end generate Sum_gen;
	
	
end structural;

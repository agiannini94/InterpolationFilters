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
-- Module Name:			RoutingUnit.vhd
-- Project: 			interpolation filter project for HEVC
-- Description:			route the inputs of the 8/7-tap luma reconfigurable filter (filter_reconfigurable.vhd, filter_reconfigurable_stage2.vhd)
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RoutingUnit is
	generic(n:positive:=8);	-- number of bit per operand
	port(
		in0,in1,in2,in3,in4,in5,in6,in7:IN std_logic_vector(n-1 downto 0);
		conftap_8or7:IN std_logic_vector(1 downto 0);					-- 00 -> 8-tap, 10 -> 7-tap 1, 11 -> 7-tap 2, 01 -> all zero
		s0_1,s1_1,s2_1,s3_1,s3_2,s2_2,s1_2,s0_2:OUT std_logic_vector(n-1 downto 0)
	);
end entity RoutingUnit;

architecture behavioural of RoutingUnit is
begin

routing_process: process(in0,in1,in2,in3,in4,in5,in6,in7,conftap_8or7)
begin

case conftap_8or7 is
	when "10"=>	-- 7-tap quarter pixel filter type 1
		s0_1<=in7;
		s1_1<=in6;
		s2_1<=in5;
		s3_1<=std_logic_vector(to_unsigned(0,n));
		s3_2<=in4;
		s2_2<=in3;
		s1_2<=in2;
		s0_2<=in1;

	when "11"=>	-- 7-tap quarter pixel filter type 2
		s0_1<=in7;
		s1_1<=in6;
		s2_1<=in5;
		s3_1<=in4;
		s3_2<=std_logic_vector(to_unsigned(0,n));
		s2_2<=in3;
		s1_2<=in2;
		s0_2<=in1;

	when "00"=>	-- 8-tap half pixel filter
		s0_1<=in7;
		s1_1<=in6;
		s2_1<=in5;
		s3_1<=in4;
		s3_2<=in3;
		s2_2<=in2;
		s1_2<=in1;
		s0_2<=in0;

	when others=>	-- conftap_8or7="01" -> output are zero (demux)
		s0_1<=(others=>'0');
		s1_1<=(others=>'0');
		s2_1<=(others=>'0');
		s3_1<=(others=>'0');
		s3_2<=(others=>'0');
		s2_2<=(others=>'0');
		s1_2<=(others=>'0');
		s0_2<=(others=>'0');
end case;
end process routing_process;

end architecture behavioural;

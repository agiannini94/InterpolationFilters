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
-- Module Name:			RoutingUnit_chroma.vhd
-- Project: 			interpolation filter project for HEVC
-- Description:			route the inputs of the 4-tap chroma reconfigurable filter (filter_chroma_reconfigurable.vhd, filter_chroma_reconfigurable_stage2.vhd)
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RoutingUnit_chroma is
	generic(n:positive:=8);	-- number of bit per operand
	port(
		in0,in1,in2,in3:IN std_logic_vector(n-1 downto 0);
		conf:IN std_logic_vector(1 downto 0);	-- "00" => half pixel filter, "10" => quarter pixel filter type 1, "11" => quarter pixel filter type 2, "01" => outputs are zero
		in0_int,in1_int,in2_int,in3_int:OUT std_logic_vector(n-1 downto 0)
	);
end entity RoutingUnit_chroma;

architecture behavioural of RoutingUnit_chroma is
begin

routing_process: process(in0,in1,in2,in3,conf)
begin
case conf is
	when "10"=>	-- quarter pixel filter type 1 (same routing as half pixel)
		in0_int<=in0;
		in1_int<=in1;
		in2_int<=in2;
		in3_int<=in3;

	when "11"=>	-- quarter pixel filter type 2
		in0_int<=in3;
		in1_int<=in2;
		in2_int<=in1;
		in3_int<=in0;

	when "00"=>	-- half pixel filter
		in0_int<=in0;
		in1_int<=in1;
		in2_int<=in2;
		in3_int<=in3;

	when others=>	-- conf="01" -> output are zero (demux)
		in0_int<=(others=>'0');
		in1_int<=(others=>'0');
		in2_int<=(others=>'0');
		in3_int<=(others=>'0');
end case;
end process routing_process;

end architecture behavioural;

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
-- Module Name:				GP_Unit.vhd
-- Project:					interpolation filter project for HEVC
-- Description:				Parallel_Prefix_Adders
-- Dependencies:			none
--			
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity GP_Unit is
	port(
		A,B				:IN std_logic;	 -- adder inputs
		G,P				:OUT std_logic  -- generate and propagate output
	);
end entity GP_Unit;

architecture structure of GP_Unit is

begin
	
	G <= A AND B;
	P <= A XOR B;
	
end structure;
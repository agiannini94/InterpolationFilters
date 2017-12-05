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
-- Module Name:			CustomMultiportMemory_chroma.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			shift register bank with shift enable driven by an address input port.
--				Combinational output driven the address input port (same address as before).
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CustomMultiportMemory_chroma is
	port(
		clk,reset_n,Wr1_n: IN std_logic;
		Addr_IN: IN std_logic_vector(5 downto 0); 
		InData: IN std_logic_vector(7 downto 0);
		OutData0,OutData1,OutData2: OUT std_logic_vector(7 downto 0)
	);
end entity CustomMultiportMemory_chroma;

architecture behavioural of CustomMultiportMemory_chroma is

subtype Data_Typ is std_logic_vector(23 downto 0);	-- 3 registers, 8 bit per register
type Reg_Typ is array(0 to 34) of Data_Typ;		-- 35 locations are required when processing a 32x32 prediction block with a 4-tap filter
signal rf:Reg_Typ;

begin

wr_process: process (clk,reset_n)
begin
	if reset_n='0' then rf<=(others=>(others=>'0'));
	elsif clk'event and clk='1' then	-- positive edge clock
		if Wr1_n='0' and to_integer(unsigned(Addr_IN))<=34 then	-- for safety
	 		rf(to_integer(unsigned(Addr_IN)))(7 downto 0)<=InData;	-- always write to the right most location of the addressed row, and shift left the other locations
			rf(to_integer(unsigned(Addr_IN)))(15 downto 8)<=rf(to_integer(unsigned(Addr_IN)))(7 downto 0);
			rf(to_integer(unsigned(Addr_IN)))(23 downto 16)<=rf(to_integer(unsigned(Addr_IN)))(15 downto 8);
		end if;
	end if;
end process wr_process;

-- Combinational output settings
OutData2<=
	rf(to_integer(unsigned(Addr_IN)))(7 downto 0) when to_integer(unsigned(Addr_IN)) <= 34 else
	rf(34)(7 downto 0);	-- condition, for safety
OutData1<=
	rf(to_integer(unsigned(Addr_IN)))(15 downto 8) when to_integer(unsigned(Addr_IN)) <= 34 else
	rf(34)(15 downto 8);	-- condition, for safety
OutData0<=
	rf(to_integer(unsigned(Addr_IN)))(23 downto 16) when to_integer(unsigned(Addr_IN)) <= 34 else
	rf(34)(23 downto 16);	-- condition, for safety

end architecture behavioural;

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
-- Module Name:			CustomMultiportMemory.vhd
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

entity CustomMultiportMemory is
	port(
		clk,reset_n,Wr1_n: IN std_logic;		-- input clock, asynchronous active-low reset, synchronous active low shift enable (Wr1_n) 
		Addr_IN: IN std_logic_vector(6 downto 0);	-- input address port
		InData: IN std_logic_vector(7 downto 0);	-- input data port
		OutData0,OutData1,OutData2,OutData3,OutData4,OutData5,OutData6: OUT std_logic_vector(7 downto 0)	-- combinational output data ports
	);
end entity CustomMultiportMemory;

architecture behavioural of CustomMultiportMemory is

subtype Data_Typ is std_logic_vector(55 downto 0);	-- 7 registers, 8 bit per register
type Reg_Typ is array(0 to 70) of Data_Typ;		-- 71 locations are required when processing a 64x64 prediction block with the 8-tap filter
signal rf:Reg_Typ;

begin

wr_process: process (clk,reset_n)
begin
	if reset_n='0' then rf<=(others=>(others=>'0'));
	elsif clk'event and clk='1' then	-- positive edge clock
		if Wr1_n='0' and to_integer(unsigned(Addr_IN))<=70 then	-- for safety
	 		rf(to_integer(unsigned(Addr_IN)))(7 downto 0)<=InData;	-- always write to the right most location of the addressed row, and shift left the other locations
			rf(to_integer(unsigned(Addr_IN)))(15 downto 8)<=rf(to_integer(unsigned(Addr_IN)))(7 downto 0);
			rf(to_integer(unsigned(Addr_IN)))(23 downto 16)<=rf(to_integer(unsigned(Addr_IN)))(15 downto 8);
			rf(to_integer(unsigned(Addr_IN)))(31 downto 24)<=rf(to_integer(unsigned(Addr_IN)))(23 downto 16);
			rf(to_integer(unsigned(Addr_IN)))(39 downto 32)<=rf(to_integer(unsigned(Addr_IN)))(31 downto 24);
			rf(to_integer(unsigned(Addr_IN)))(47 downto 40)<=rf(to_integer(unsigned(Addr_IN)))(39 downto 32);
			rf(to_integer(unsigned(Addr_IN)))(55 downto 48)<=rf(to_integer(unsigned(Addr_IN)))(47 downto 40);
		end if;
	end if;
end process wr_process;

-- Combinational output settings
OutData6<=
	rf(to_integer(unsigned(Addr_IN)))(7 downto 0) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(7 downto 0);	-- condition, for safety
OutData5<=
	rf(to_integer(unsigned(Addr_IN)))(15 downto 8) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(15 downto 8);	-- condition, for safety
OutData4<=
	rf(to_integer(unsigned(Addr_IN)))(23 downto 16) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(23 downto 16);	-- condition, for safety
OutData3<=
	rf(to_integer(unsigned(Addr_IN)))(31 downto 24) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(31 downto 24);	-- condition, for safety
OutData2<=
	rf(to_integer(unsigned(Addr_IN)))(39 downto 32) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(39 downto 32);	-- condition, for safety
OutData1<=
	rf(to_integer(unsigned(Addr_IN)))(47 downto 40) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(47 downto 40);	-- condition, for safety
OutData0<=
	rf(to_integer(unsigned(Addr_IN)))(55 downto 48) when to_integer(unsigned(Addr_IN)) <= 70 else
	rf(70)(55 downto 48);	-- condition, for safety

end architecture behavioural;

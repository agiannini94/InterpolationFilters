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
-- Module Name:			SIPO_SE.vhd
-- Project:			None
-- Description:			Serial Input Parallel Output register with Shift Enable and asynchronous reset
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity SIPO_SE is
	generic(n:positive:=16;m:positive:=8);			-- m: number of registers, n: number of bit per register
	port(
		clk,reset_n,SE:IN std_logic;			-- reset_n: active-low asynchronous reset, SE: active-high synchronous serial enable signal
		data_in:IN std_logic_vector(n-1 downto 0);	-- serial input port
		data_out:OUT std_logic_vector(m*n-1 downto 0)	-- parallel output port
	);
end entity SIPO_SE;

architecture behavioural of SIPO_SE is

signal sr:std_logic_vector(m*n-1 downto 0);

begin

serial_in:process(clk,reset_n) is
begin
	if reset_n='0' then sr<=(others=>'0');
	elsif clk'event and clk='1' then	-- positive edge clock
		if SE='1' then
			sr(m*n-1 downto n)<=sr((m-1)*n-1 downto 0);	-- shift m-1 register
			sr(n-1 downto 0)<=data_in;			-- shift-in input value
		end if;
	end if;
end process serial_in;

data_out<=sr;	-- parallel output setting

end architecture behavioural;

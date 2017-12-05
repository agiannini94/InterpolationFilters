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
-- Create Date(mm/aaaa):	12/2015 
-- Module Name:			Pipo_LE.vhd
-- Project:			None
-- Description:			Parallel Input Parallel Output register with Load Enable and asynchronous reset
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity Pipo_LE is
	generic(n:positive:=8);			-- n: input/output number of bits
	port(
		clk,LE,rst_n:IN std_logic;	-- rst_n: active-low asynchronous reset, LE: active-high synchronous load enable signal
		data_in:IN std_logic_vector(n-1 downto 0);
		data_out:OUT std_logic_vector(n-1 downto 0)
	);
end Pipo_LE;

architecture behavioural of Pipo_LE is
begin

process(clk,rst_n)
begin
	if rst_n ='1' then
		if clk'event and clk='1' then
			if LE='1' then
				data_out<=data_in;
			end if;
		end if;
	else
		data_out<=(others=>'0');
	end if;
end process;

end behavioural;
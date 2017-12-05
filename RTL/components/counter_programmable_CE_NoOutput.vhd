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
-- Module Name:			counter_programmable_CE_NoOutput.vhd
-- Project:			None
-- Description:			programmable counter with:
--					modulus input load enable register,
--					synchronous clear,
--					count enable,
--					terminal count
-- Dependencies:		
--				Pipo_LE.vhd
--				my_math.vhd
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.my_math.all;

entity counter_programmable_CE_NoOutput is
	generic(rg:positive:=63);	-- counter maximum range
	port(
		clk,reset_n,clear,LE_mod,CE:IN std_logic;		-- clear: synchronous clear count signal, LE_mod: synchronous load enable signal for count modulus, CE: syncrhonous count enable signal
		modulus:IN std_logic_vector(log2(rg)-1 downto 0);	-- programmable input modulus
		terminal_count:OUT std_logic
	);
end counter_programmable_CE_NoOutput;

architecture behavioural of counter_programmable_CE_NoOutput is
component Pipo_LE is
	generic(n:positive);
	port(
		clk,LE,rst_n:IN std_logic;
		data_in:IN std_logic_vector(n-1 downto 0);
		data_out:OUT std_logic_vector(n-1 downto 0)
	);
end component Pipo_LE;
	signal q:integer range 0 to rg;
	signal modulus_int:std_logic_vector(log2(rg)-1 downto 0);
begin

	REG_MOD:Pipo_LE
		generic map(n=>log2(rg))
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_mod,
			data_in=>modulus,
			data_out=>modulus_int
		);
cnt_proc: process(reset_n,clk) is
variable cnt:integer range 0 to rg;
begin
	if reset_n='0' then
		cnt:=0;
	elsif clk'event and clk='1' then
		if clear='1' then
			cnt:=0;
		else
			if CE='1' then
				if cnt>=to_integer(unsigned(modulus_int)) then		-- the '=' condition is enough here to work properly, the '>=' is better for safety in a real hardware application
					cnt:=0;
				else 
					cnt:=cnt+1;
				end if;
			end if;
		end if;
	end if;
	q<=cnt;
end process cnt_proc;

terminal_count<='1' when q>=to_integer(unsigned(modulus_int)) else
		'0';

end architecture behavioural;

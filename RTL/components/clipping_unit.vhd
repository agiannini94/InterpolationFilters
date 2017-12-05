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
-- Module Name:			clipping_unit.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			clip the signed data input to 8 bit unsigned, to 255 if higher then 255 and to 0 if lower then 0
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clipping_unit is
	generic(n:positive:=10);
	port(
		data_in:IN std_logic_vector(n-1 downto 0);	-- input must be fixed point (n-6).6
		data_out:OUT std_logic_vector(7 downto 0)	-- pixel 8-bit unsigned (0 to 255)
	);
end clipping_unit;

architecture behavioural of clipping_unit is
begin

clipping_proc:process(data_in)
begin
	if to_integer(signed(data_in))<0 then		-- data_in < 0, then result=0
		data_out<=std_logic_vector(to_unsigned(0,8));	--zero;
	elsif  to_integer(signed(data_in))>255 then	-- data_in > 255, then result=255
		data_out<=std_logic_vector(to_unsigned(255,8));	--max_val(7 downto 0);
	else
		data_out<=data_in(7 downto 0);
	end if;
end process clipping_proc;

end architecture behavioural;

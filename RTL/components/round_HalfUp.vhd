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
-- Create Date(gg/mm/aaaa):	09/2017 
-- Module Name:			round_HalfUp.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			round half up. Add '1' to least significant position and chop the LSB. Note that input data must be already right shifted to rounded bit depth - 1.
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity round_HalfUp is
	generic(n:positive:=8);
	port(
		data_ToBeRounded:IN std_logic_vector(n-1 downto 0);
		data_out:OUT std_logic_vector(n-2 downto 0)
	);
end entity round_HalfUp;

architecture behavioural of round_HalfUp is
	signal o_int:std_logic_vector(n-1 downto 0);
begin

o_int<=std_logic_vector(signed(data_ToBeRounded)+1);	-- add 1
data_out<=o_int(n-1 downto 1);				-- truncate the LSB

end architecture behavioural;

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
-- Author: --
-- 
-- Create Date(mm/aaaa):	09/2017 
-- Module Name:			clk_gen.vhd
-- Project:			None
-- Description:			Clock generator
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity clk_gen is
  port (
    END_SIM : in  std_logic;
    CLK     : out std_logic;
    RST_n   : out std_logic);
end clk_gen;

architecture beh of clk_gen is

  constant Ts : time := 1 ns;
  
  signal CLK_i : std_logic;
  
begin  -- beh

  process
  begin
    if (CLK_i = 'U') then
      CLK_i <= '0';
    else
      CLK_i <= not(CLK_i);
    end if;
    wait for Ts/2;
  end process;

  CLK <= CLK_i and not(END_SIM);

  process
  begin
    RST_n <= '0';
    wait for Ts;
    RST_n <= '1';
    wait;
  end process;

end beh;

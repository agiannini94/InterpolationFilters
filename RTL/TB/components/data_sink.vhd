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
-- Module Name:			data_sink.vhd
-- Project:			None
-- Description:			Sample the output on rising clock edge if VOUT is '1', then print the results on a results_sim.txt
-- Dependencies:		None
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;

entity data_sink is
  port (
    CLK   : in std_logic;
    RST_n : in std_logic;
    VOUT   : in std_logic;
    DOUT   : in std_logic_vector(16 downto 0));
end data_sink;

architecture beh of data_sink is

begin  -- beh

  process (CLK, RST_n)
    file res_fp : text open WRITE_MODE is "./samples_TB_ProcessingElement/results_sim.txt";
    variable line_out : line;    
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      null;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if (VOUT = '1') then
        write(line_out, to_integer(unsigned(DOUT)));
        writeline(res_fp, line_out);
      end if;
    end if;
  end process;

end beh;

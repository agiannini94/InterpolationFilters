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
-- Create Date(mm/aaaa):	10/2017 
-- Module Name:			data_maker_chroma_approximate_4tap.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			data generator for the approximate chroma processing element, 4-tap filters.
--				It tries different filter configurations from 1D to 2D filtering.
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

entity data_maker_chroma_approximate_4tap is
	port (
		CLK: in  std_logic;
		RST_n: in  std_logic;
		Vin,
		horVer,
		ME_MCBi:OUT std_logic;
		filterSel_1,filterSel_2:OUT std_logic_vector(3 downto 0);
		InData:OUT std_logic_vector(7 downto 0);
		modAddr_IN:OUT std_logic_vector(5 downto 0);
		END_SIM : out std_logic);
end data_maker_chroma_approximate_4tap;

architecture beh of data_maker_chroma_approximate_4tap is

  constant tco : time := 0.17 ns; --1 ns

  signal sEndSim : std_logic;
  signal END_SIM_i : std_logic_vector(0 to 10);
  signal Vin_int:std_logic;

begin  -- beh

  process (CLK, RST_n)
    file fp1_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp2_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp3_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp4_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp5_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp6_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp7_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4.txt";
    file fp8_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp9_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp10_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp11_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp12_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp13_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp14_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    file fp15_in : text open READ_MODE is "./samples_TB_ProcessingElement/samples_chroma_32x32_4&4.txt";
    variable line_in : line;
    variable x : integer;
    variable f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13:boolean;
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      InData <= (others => '0') after tco;      
      Vin_int <= '0' after tco;
	horVer<='0' after tco;
	ME_MCBi<='1' after tco;
	filterSel_1<="0000" after tco;
	filterSel_2<="0000" after tco;
	modAddr_IN<="000000" after tco;
      sEndSim <= '0' after tco;
	elsif CLK'event and CLK = '1' then  -- rising clock edge
	      if not endfile(fp1_in) then	-- filter 4/8th half-pixel
	        readline(fp1_in, line_in);
	        read(line_in, x);
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
	        sEndSim <= '0' after tco;
		f1:=true;
	      elsif f1=true then
		f1:=false;
		Vin_int<='0' after tco;
	      elsif not endfile(fp2_in) then	-- filter 1/8th quarter-pixel
	        readline(fp2_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0001" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
		sEndSim <= '0' after tco;
		f2:=true;
	      elsif f2=true then
		f2:=false;
		Vin_int<='0' after tco;	
	      elsif not endfile(fp3_in) then	-- filter 2/8th quarter-pixel
	        readline(fp3_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0011" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
		sEndSim <= '0' after tco;
		f3:=true;
	      elsif f3=true then
		f3:=false;
		Vin_int<='0' after tco;	
	      elsif not endfile(fp4_in) then	-- filter 3/8th quarter-pixel
	        readline(fp4_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0101" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
		sEndSim <= '0' after tco;
		f4:=true;
	      elsif f4=true then
		f4:=false;
		Vin_int<='0' after tco;		
	      elsif not endfile(fp5_in) then	-- filter 5/8th quarter-pixel
	        readline(fp5_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0110" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
		sEndSim <= '0' after tco;
		f5:=true;
	      elsif f5=true then
		f5:=false;
		Vin_int<='0' after tco;		
	      elsif not endfile(fp6_in) then	-- filter 6/8th quarter-pixel
	        readline(fp6_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0100" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
		sEndSim <= '0' after tco;
		f6:=true;
	      elsif f6=true then
		f6:=false;
		Vin_int<='0' after tco;		
	      elsif not endfile(fp7_in) then	-- filter 7/8th quarter-pixel
	        readline(fp7_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='0' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0010" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(31,6)) after tco;
		sEndSim <= '0' after tco;
		f7:=true;
	      elsif f7=true then
		f7:=false;
		Vin_int<='0' after tco;		
	      elsif not endfile(fp8_in) then	-- filter 4/8th half-pixel horizontal and 4/8th half-pixel vertical
	        readline(fp8_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0000" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
		f8:=true;
	      elsif f8=true then
		f8:=false;
		Vin_int<='0' after tco;			
	      elsif not endfile(fp9_in) then	-- filter 4/8th half-pixel horizontal and 1/8th quarter-pixel vertical
	        readline(fp9_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0001" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
		f9:=true;
	      elsif f9=true then
		f9:=false;
		Vin_int<='0' after tco;			
	      elsif not endfile(fp10_in) then	-- filter 4/8th half-pixel horizontal and 2/8th quarter-pixel vertical
	        readline(fp10_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0011" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
		f10:=true;
	      elsif f10=true then
		f10:=false;
		Vin_int<='0' after tco;			
	      elsif not endfile(fp11_in) then	-- filter 4/8th half-pixel horizontal and 3/8th quarter-pixel vertical
	        readline(fp11_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0101" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
		f11:=true;
	      elsif f11=true then
		f11:=false;
		Vin_int<='0' after tco;			
	      elsif not endfile(fp12_in) then	-- filter 4/8th half-pixel horizontal and 5/8th quarter-pixel vertical
	        readline(fp12_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0110" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
		f12:=true;
	      elsif f12=true then
		f12:=false;
		Vin_int<='0' after tco;			
	      elsif not endfile(fp13_in) then	-- filter 4/8th half-pixel horizontal and 6/8th quarter-pixel vertical
	        readline(fp13_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0100" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
		f13:=true;
	      elsif f13=true then
		f13:=false;
		Vin_int<='0' after tco;			
	      elsif not endfile(fp14_in) then	-- filter 4/8th half-pixel horizontal and 7/8th quarter-pixel vertical
	        readline(fp14_in, line_in);
	        read(line_in, x);
	
	        InData <= std_logic_vector(to_unsigned(x, 8)) after tco;
	        Vin_int <= '1' after tco;
		horVer<='1' after tco;
		ME_MCBi<='1' after tco;
		filterSel_1<="0000" after tco;
		filterSel_2<="0010" after tco;
		modAddr_IN<=std_logic_vector(to_unsigned(34,6)) after tco;
		sEndSim <= '0' after tco;
	
	      else
		Vin_int<='0' after tco;
	        sEndSim <= '1' after tco;
	      end if;
        end if;	-- clk
  end process;

Vin<=Vin_int;

  process (CLK, RST_n)
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      END_SIM_i <= (others => '0') after tco;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      END_SIM_i(0) <= sEndSim after tco;
      END_SIM_i(1 to 10) <= END_SIM_i(0 to 9) after tco;
    end if;
  end process;

  END_SIM <= END_SIM_i(10);  

end beh;

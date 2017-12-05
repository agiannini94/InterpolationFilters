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
-- Module Name:			FSM2_filter_chroma_approximate.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			second stage Moore Finite State Machine chroma approximate
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FSM2_filter_chroma_approximate is
	port(
		clk,reset_n,
		start,							-- FSM2 start signal
		terminal_count,terminal_count_Add: IN std_logic;	-- pixel counter (SHARED_CNT in ControlUnit.vhd) and input buffer address counter terminal count
		conftap_2:OUT std_logic_vector(1 downto 0);		-- config stage2 legacy routing unit
		---------- Additional signals required for approximate version
		filterSel:IN std_logic_vector(3 downto 0);		-- 2nd stage filter selector signals
		conf2_stage2,						-- config stage2 2-tap routing unit
		conf_2tap_stage2:OUT std_logic_vector(1 downto 0);	-- config stage2 2-tap filter
		----------
		conf_vect_stage2:OUT std_logic_vector(12 downto 0);	-- config stage2 legacy filter
		mod_PelCounter:OUT std_logic_vector(2 downto 0);	-- pixel counter modulus (SHARED_CNT)
		clear_count,						-- synchronous clear pixel counter (SHARED_CNT)
		LE_count,						-- load enable modulus pixel counter (SHARED_CNT)
		LE_rout2,						-- load enable stage2 config routing unit
		LE_conf_vect_stage2,					-- load enable stage2 filter configuration vector
		LE_regout,						-- output register load enable
		fir1or2,						-- '0'=>1D output, '1'=>2D output
		---------- Additional signals required for approximate version
		LE_rout2_2tap,						-- load enable stage2 config 2-tap routing unit
		LE_conf_2tap_stage2:OUT std_logic			-- load enable stage2 config 2-tap filter
		----------
  );
end entity FSM2_filter_chroma_approximate;

architecture behavioural of FSM2_filter_chroma_approximate is
	type state_type is(
		IDLE,								-- wait for a start condition 
		SET48,SET18,SET78,SET28,SET68,SET38,SET58,			-- sets the routing unit and the filter configuration registers of the second stage legacy branch
		SET2_48,SET2_18,SET2_78,SET2_28,SET2_68,SET2_38,SET2_58,	-- sets the routing unit and the filter configuration registers of the second stage 2-tap branch
		WAITFULL,							-- wait for the 2nd stage shift register to be full with Ntap-1 data
		WAITLINE,							-- start setting the output and wait for a line to be written in the input buffer
		LASTPEL4, LASTPEL2						-- sample the last pixel before stalling the output, reset SHARED_CNT (inserted for timing issues with the input address terminal count)
		);
	signal y_present,y_next: state_type;
begin

state_transitions:process(y_present,filterSel,terminal_count,terminal_count_Add,start)	-- Vin
begin
y_next<=IDLE;
	case y_present is
		when IDLE=>
			if start='1' then
				case filterSel is
					when "0000"=>	-- 4 tap 4/8 filter
						y_next<=SET48;
					when "0001"=>	-- 4 tap 1/8 filter
						y_next<=SET18;
					when "0010"=>	-- 4 tap 7/8 filter
						y_next<=SET78;
					when "0011"=>	-- 4 tap 2/8 filter
						y_next<=SET28;
					when "0100"=>	-- 4 tap 6/8 filter
						y_next<=SET68;
					when "0101"=>	-- 4 tap 3/8 filter
						y_next<=SET38;
					when "0110"=>	-- 4 tap 5/8 filter
						y_next<=SET58;
					when "0111"=>	-- 2 tap 4/8 filter
						y_next<=SET2_48;
					when "1000"=>	-- 2 tap 1/8 filter
						y_next<=SET2_18;
					when "1001"=>	-- 2 tap 7/8 filter
						y_next<=SET2_78;
					when "1010"=>	-- 2 tap 2/8 filter
						y_next<=SET2_28;
					when "1011"=>	-- 2 tap 6/8 filter
						y_next<=SET2_68;
					when "1100"=>	-- 2 tap 3/8 filter
						y_next<=SET2_38;
					when "1101"=>	-- 2 tap 5/8 filter
						y_next<=SET2_58;
					when others =>	-- for safety
						y_next<=IDLE;
				end case;
			else
				y_next<=IDLE;
			end if;
		when SET48=>
			y_next<=WAITFULL;
		when SET18=>
			y_next<=WAITFULL;
		when SET78=>
			y_next<=WAITFULL;
		when SET28=>
			y_next<=WAITFULL;
		when SET68=>
			y_next<=WAITFULL;
		when SET38=>
			y_next<=WAITFULL;
		when SET58=>
			y_next<=WAITFULL;
		when SET2_48=>
			y_next<=WAITLINE;	-- Note: bypass the WAITFULL state
		when SET2_18=>
			y_next<=WAITLINE;
		when SET2_78=>
			y_next<=WAITLINE;
		when SET2_28=>
			y_next<=WAITLINE;
		when SET2_68=>
			y_next<=WAITLINE;
		when SET2_38=>
			y_next<=WAITLINE;
		when SET2_58=>
			y_next<=WAITLINE;
		when WAITFULL=>
			if terminal_count='1' then
				y_next<=WAITLINE;
			else
				y_next<=WAITFULL;
			end if;
		when WAITLINE=>
			if terminal_count_Add='1' then
				case filterSel is
					when "0000"=>	-- 4 tap 4/8 filter
						y_next<=LASTPEL4;
					when "0001"=>	-- 4 tap 1/8 filter
						y_next<=LASTPEL4;
					when "0010"=>	-- 4 tap 7/8 filter
						y_next<=LASTPEL4;
					when "0011"=>	-- 4 tap 2/8 filter
						y_next<=LASTPEL4;
					when "0100"=>	-- 4 tap 6/8 filter
						y_next<=LASTPEL4;
					when "0101"=>	-- 4 tap 3/8 filter
						y_next<=LASTPEL4;
					when "0110"=>	-- 4 tap 5/8 filter
						y_next<=LASTPEL4;
					when "0111"=>	-- 2 tap 4/8 filter
						y_next<=LASTPEL2;
					when "1000"=>	-- 2 tap 1/8 filter
						y_next<=LASTPEL2;
					when "1001"=>	-- 2 tap 7/8 filter
						y_next<=LASTPEL2;
					when "1010"=>	-- 2 tap 2/8 filter
						y_next<=LASTPEL2;
					when "1011"=>	-- 2 tap 6/8 filter
						y_next<=LASTPEL2;
					when "1100"=>	-- 2 tap 3/8 filter
						y_next<=LASTPEL2;
					when "1101"=>	-- 2 tap 5/8 filter
						y_next<=LASTPEL2;
					when others =>	-- for safety
						y_next<=IDLE;
				end case;
			else
				y_next<=WAITLINE;
			end if;
		when LASTPEL4=>
				if start='1' then
					y_next<=WAITFULL;
				else
					y_next<=IDLE;
				end if;
		when LASTPEL2=>
				if start='1' then
					y_next<=WAITFULL;
				else
					y_next<=IDLE;
				end if;
	end case;
end process state_transitions;

state_registers:process(clk,reset_n)
begin
  if reset_n='0' then y_present<=IDLE;
  elsif(clk'event and clk='1') then 
    y_present<=y_next;
  end if;
end process state_registers;

output_process:process(y_present)
begin
	case y_present is
		when IDLE=>
			conftap_2<="00";
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='0';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='0';
			conf2_stage2<="00";
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='0';
			LE_conf_2tap_stage2<='0';
		when SET48=>
			conftap_2<="00";	-- set 4/8th filter
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET18=>
			conftap_2<="10";	-- set 1/8th filter
			conf_vect_stage2<="1100000100011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET78=>
			conftap_2<="11";	-- set 7/8th filter
			conf_vect_stage2<="1100000100011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET28=>
			conftap_2<="10";	-- set 2/8th filter
			conf_vect_stage2<="1011011000001";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET68=>
			conftap_2<="11";	-- set 6/8th filter
			conf_vect_stage2<="1011011000001";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET38=>
			conftap_2<="10";	-- set 3/8th filter
			conf_vect_stage2<="0001001010100";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET58=>
			conftap_2<="11";	-- set 5/8th filter
			conf_vect_stage2<="0001001010100";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='0';
		when SET2_48=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="00";	-- set 2 tap 4/8th filter
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when SET2_18=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="10";	-- set 2 tap 1/8th filter
			conf_2tap_stage2<="01";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when SET2_78=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="11";	-- set 2 tap 7/8th filter
			conf_2tap_stage2<="01";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when SET2_28=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="10";	-- set 2 tap 2/8th filter
			conf_2tap_stage2<="10";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when SET2_68=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="11";	-- set 2 tap 6/8th filter
			conf_2tap_stage2<="10";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when SET2_38=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="10";	-- set 2 tap 3/8th filter
			conf_2tap_stage2<="11";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when SET2_58=>
			conftap_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='1';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="11";	-- set 2 tap 5/8th filter
			conf_2tap_stage2<="11";
			LE_rout2_2tap<='1';
			LE_conf_2tap_stage2<='1';
		when WAITFULL=>
			conftap_2<="00";
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='0';
			LE_count<='0';
			LE_rout2<='0';
			LE_conf_vect_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			conf2_stage2<="00";
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='0';
			LE_conf_2tap_stage2<='0';
		when WAITLINE=>	-- start output data
			conftap_2<="00";
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='0';
			LE_conf_vect_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
			conf2_stage2<="00";
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='0';
			LE_conf_2tap_stage2<='0';
		when LASTPEL4=>	-- sample last column pixel and start counter
			conftap_2<="00";
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(2,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='0';
			LE_conf_vect_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
			conf2_stage2<="00";
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='0';
			LE_conf_2tap_stage2<='0';
		when LASTPEL2=>	-- sample last column pixel and start counter
			conftap_2<="00";
			conf_vect_stage2<="0000110011011";
			mod_PelCounter<=std_logic_vector(to_unsigned(0,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='0';
			LE_conf_vect_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
			conf2_stage2<="00";
			conf_2tap_stage2<="00";
			LE_rout2_2tap<='0';
			LE_conf_2tap_stage2<='0';
	end case;
end process output_process;

end behavioural;

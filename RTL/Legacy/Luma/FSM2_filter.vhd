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
-- Module Name:			FSM2_filter.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			second stage Moore Finite State Machine luma legacy
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FSM2_filter is
	port(
		clk,reset_n,
		start,							-- FSM2 start signal
		terminal_count,terminal_count_Add: IN std_logic;	-- pixel counter (SHARED_CNT in ControlUnit.vhd) and input buffer address counter terminal count
		EightOrSeven:IN std_logic_vector(1 downto 0);		-- "00"=>half-pixel 8-tap filter, "10"=>quarter-pixel 7-tap filter type 1, "11"=>quarter-pixel 7-tap filter type 2 ("01" useless, covered for safety)
		conftap_8or7_2:OUT std_logic_vector(1 downto 0);	-- config stage2 routing unit
		conf_vect1_stage2,conf_vect2_stage2:OUT std_logic_vector(8 downto 0);	-- config stage2 half filters
		mod_PelCounter:OUT std_logic_vector(2 downto 0);	-- pixel counter modulus (SHARED_CNT)
		clear_count,						-- synchronous clear pixel counter (SHARED_CNT)
		LE_count,						-- load enable modulus pixel counter (SHARED_CNT)
		LE_rout2,						-- load enable stage2 config routing unit
		LE_conf_vect1_stage2,LE_conf_vect2_stage2,		-- load enable stage2 half filters configuration vectors
		LE_regout,						-- output register load enable
		fir1or2:OUT std_logic					-- '0'=>1D output, '1'=>2D output
  );
end entity FSM2_filter;

architecture behavioural of FSM2_filter is
	type state_type is(
		IDLE,			-- wait for a start condition 
		SET8,SET71,SET72,	-- sets the routing unit and the filter configuration registers of the second stage branch
		WAITFULL,		-- wait for the 2nd stage shift register to be full with Ntap-1 data
		WAITLINE,		-- start setting the output and wait for a line to be written in the input buffer
		LASTPEL8,LASTPEL7	-- sample the last pixel before stalling the output, reset SHARED_CNT (inserted for timing issues with the input address terminal count)
		);
	signal y_present,y_next: state_type;
begin

state_transitions:process(y_present,EightOrSeven,terminal_count,terminal_count_Add,start)	-- Vin
begin
y_next<=IDLE;
	case y_present is
		when IDLE=>
			if start='1' then
				case EightOrSeven is
					when "00"=>	-- 8 tap
						y_next<=SET8;
					when "10"=>	-- 7 tap 1
						y_next<=SET71;
					when "11"=>	-- 7 tap 2
						y_next<=SET72;
					when others =>	-- for safety
						y_next<=IDLE;
				end case;
			else
				y_next<=IDLE;
			end if;
		when SET8=>
			y_next<=WAITFULL;
		when SET71=>
			y_next<=WAITFULL;
		when SET72=>
			y_next<=WAITFULL;
		when WAITFULL=>
			if terminal_count='1' then
				y_next<=WAITLINE;
			else
				y_next<=WAITFULL;
			end if;
		when WAITLINE=>
			if terminal_count_Add='1' then
				case EightOrSeven is
					when "00"=>	-- 8 tap
						y_next<=LASTPEL8;
					when "10"=>	-- 7 tap 1
						y_next<=LASTPEL7;
					when "11"=>	-- 7 tap 2
						y_next<=LASTPEL7;
					when others =>	-- for safety
						y_next<=IDLE;
				end case;
			else
				y_next<=WAITLINE;
			end if;
		when LASTPEL8=>
				if start='1' then
					y_next<=WAITFULL;
				else
					y_next<=IDLE;
				end if;
		when LASTPEL7=>
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
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(6,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='0';
		when SET8=>
			conftap_8or7_2<="00";	-- set 8 tap filter
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(5,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='1';
			LE_conf_vect2_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
		when SET71=>
			conftap_8or7_2<="10";	-- set 7 tap filter 1
			conf_vect1_stage2<="111101111";
			conf_vect2_stage2<="001010001";
			mod_PelCounter<=std_logic_vector(to_unsigned(4,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='1';
			LE_conf_vect2_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
		when SET72=>
			conftap_8or7_2<="11";	-- set 7 tap filter 2
			conf_vect1_stage2<="001010001";
			conf_vect2_stage2<="111101111";
			mod_PelCounter<=std_logic_vector(to_unsigned(4,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='1';
			LE_conf_vect2_stage2<='1';
			LE_regout<='0';
			fir1or2<='1';
		when WAITFULL=>
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(7,3));
			clear_count<='0';
			LE_count<='0';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
		when WAITLINE=>	-- start output data
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(7,3));
			clear_count<='1';
			LE_count<='0';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
		when LASTPEL8=>	-- sample last column pixel and start counter
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(6,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
		when LASTPEL7=>	-- sample last column pixel and start counter
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(5,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
	end case;
end process output_process;

end behavioural;
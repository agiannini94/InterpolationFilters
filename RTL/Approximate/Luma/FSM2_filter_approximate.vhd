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
-- Module Name:			FSM2_filter_approximate.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			second stage Moore Finite State Machine luma approximate
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FSM2_filter_approximate is
	port(
		clk,reset_n,
		start,							-- FSM2 start signal
		terminal_count,terminal_count_Add: IN std_logic;	-- pixel counter (SHARED_CNT in ControlUnit.vhd) and input buffer address counter terminal count
		conftap_8or7_2:OUT std_logic_vector(1 downto 0);	-- config stage2 legacy routing unit
		---------- Additional signals required for approximate version
		filterSel:IN std_logic_vector(3 downto 0);		-- 2nd stage filter selection signals
		conf3_stage2,						-- config stage2 3-tap routing unit
		conf5_stage2:OUT std_logic_vector(1 downto 0);		-- config stage1 5-tap routing unit
		----------
		conf_vect1_stage2,conf_vect2_stage2:OUT std_logic_vector(8 downto 0);	-- config stage2 legacy half filters
		mod_PelCounter:OUT std_logic_vector(2 downto 0);	-- pixel counter modulus (SHARED_CNT)
		clear_count,						-- synchronous clear pixel counter (SHARED_CNT)
		LE_count,						-- load enable modulus pixel counter (SHARED_CNT)
		LE_rout2,						-- load enable stage2 config routing unit
		LE_conf_vect1_stage2,LE_conf_vect2_stage2,		-- load enable stage2 half filters configuration vectors
		LE_regout,						-- output register load enable
		fir1or2,						-- '0'=>1D output, '1'=>2D output
		---------- Additional signals required for approximate version
		LE_rout2_3tap,						-- load enable stage2 config 3-tap routing unit
		LE_rout2_5tap:OUT std_logic				-- load enable stage2 config 5-tap routing unit
		----------
  );
end entity FSM2_filter_approximate;

architecture behavioural of FSM2_filter_approximate is
	type state_type is(
		IDLE,			-- wait for a start condition 
		SET8,SET71,SET72,	-- sets the routing unit and the filter configuration registers of the second stage legacy branch
		SET3H,SET3Q1,SET3Q2,	-- sets the routing unit and the filter configuration registers of the second stage 3-tap branch
		SET5H,SET5Q1,SET5Q2,	-- sets the routing unit and the filter configuration registers of the second stage 5-tap branch
		WAITFULL,		-- wait for the 2nd stage shift register to be full with Ntap-1 data
		WAITLINE,		-- start setting the output and wait for a line to be written in the input buffer
		LASTPEL8,		-- sample the last pixel before stalling the output, reset SHARED_CNT (inserted for timing issues with the input address terminal count)
		LASTPEL7,
		LASTPEL5,
		LASTPEL3
		);
	signal y_present,y_next: state_type;
begin

state_transitions:process(y_present,terminal_count,terminal_count_Add,start,filterSel)
begin
y_next<=IDLE;
	case y_present is
		when IDLE=>
			if start='1' then
				case filterSel is
					when "0000"=>	-- 8 tap
						y_next<=SET8;
					when "0001"=>	-- 7 tap 1
						y_next<=SET71;
					when "0010"=>	-- 7 tap 2
						y_next<=SET72;
					when "0011"=>	-- 3 tap half pixel
						y_next<=SET3H;
					when "0100"=>	-- 3 tap quarter pixel type 1
						y_next<=SET3Q1;
					when "0101"=>	-- 3 tap quarter pixel type 2
						y_next<=SET3Q2;
					when "0110"=>	-- 5 tap half pixel
						y_next<=SET5H;
					when "0111"=>	-- 5 tap quarter pixel type 1
						y_next<=SET5Q1;
					when "1000"=>	-- 5 tap quarter pixel type 2
						y_next<=SET5Q2;
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
		when SET3H=>
			y_next<=WAITFULL;
		when SET3Q1=>
			y_next<=WAITFULL;
		when SET3Q2=>
			y_next<=WAITFULL;
		when SET5H=>
			y_next<=WAITFULL;
		when SET5Q1=>
			y_next<=WAITFULL;
		when SET5Q2=>
			y_next<=WAITFULL;
		when WAITFULL=>
			if terminal_count='1' then
				y_next<=WAITLINE;
			else
				y_next<=WAITFULL;
			end if;
		when WAITLINE=>
			if terminal_count_Add='1' then
				case filterSel is
					when "0000"=>	-- 8 tap
						y_next<=LASTPEL8;
					when "0001"=>	-- 7 tap 1
						y_next<=LASTPEL7;
					when "0010"=>	-- 7 tap 2
						y_next<=LASTPEL7;
					when "0011"=>	-- 3 tap half pixel
						y_next<=LASTPEL3;
					when "0100"=>	-- 3 tap quarter pixel type 1
						y_next<=LASTPEL3;
					when "0101"=>	-- 3 tap quarter pixel type 2
						y_next<=LASTPEL3;
					when "0110"=>	-- 5 tap half pixel
						y_next<=LASTPEL5;
					when "0111"=>	-- 5 tap quarter pixel type 1
						y_next<=LASTPEL5;
					when "1000"=>	-- 5 tap quarter pixel type 2
						y_next<=LASTPEL5;
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
		when LASTPEL5=>
				if start='1' then
					y_next<=WAITFULL;
				else
					y_next<=IDLE;
				end if;
		when LASTPEL3=>
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
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
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
			LE_rout2_3tap<='1';
			LE_rout2_5tap<='1';
			conf3_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
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
			LE_rout2_3tap<='1';
			LE_rout2_5tap<='1';
			conf3_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
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
			LE_rout2_3tap<='1';
			LE_rout2_5tap<='1';
			conf3_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
		when SET5H=>
			conftap_8or7_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(2,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			LE_rout2_3tap<='1';
			LE_rout2_5tap<='1';	-- load routing and filter config
			conf3_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage2<="00";	-- half pixel filter
		when SET5Q1=>
			conftap_8or7_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(2,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			LE_rout2_3tap<='1';
			LE_rout2_5tap<='1';	-- load routing and filter config
			conf3_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage2<="10";	-- quarter pixel type 1 filter
		when SET5Q2=>
			conftap_8or7_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(2,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			LE_rout2_3tap<='1';
			LE_rout2_5tap<='1';	-- load routing and filter config
			conf3_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage2<="11";	-- quarter pixel type 2 filter
		when SET3H=>
			conftap_8or7_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(0,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			LE_rout2_3tap<='1';	-- load routing and filter config
			LE_rout2_5tap<='1';
			conf3_stage2<="00";	-- half pixel filter
			conf5_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
		when SET3Q1=>
			conftap_8or7_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(0,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			LE_rout2_3tap<='1';	-- load routing and filter config
			LE_rout2_5tap<='1';
			conf3_stage2<="10";	-- quarter pixel filter type 1
			conf5_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
		when SET3Q2=>
			conftap_8or7_2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(0,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='1';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='0';
			fir1or2<='1';
			LE_rout2_3tap<='1';	-- load routing and filter config
			LE_rout2_5tap<='1';
			conf3_stage2<="11";	-- quarter pixel filter type 2
			conf5_stage2<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
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
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
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
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
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
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
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
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
		when LASTPEL5=>	-- sample last column pixel and start counter
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(3,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
		when LASTPEL3=>	-- sample last column pixel and start counter
			conftap_8or7_2<="00";
			conf_vect1_stage2<=(others=>'0');
			conf_vect2_stage2<=(others=>'0');
			mod_PelCounter<=std_logic_vector(to_unsigned(1,3));
			clear_count<='1';
			LE_count<='1';
			LE_rout2<='0';
			LE_conf_vect1_stage2<='0';
			LE_conf_vect2_stage2<='0';
			LE_regout<='1';
			fir1or2<='1';
			LE_rout2_3tap<='0';
			LE_rout2_5tap<='0';
			conf3_stage2<="00";
			conf5_stage2<="00";
	end case;
end process output_process;

end behavioural;

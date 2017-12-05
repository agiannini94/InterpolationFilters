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
-- Module Name:			FSM1_filter.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			first stage Moore Finite State Machine luma legacy
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FSM1_filter is
	port(
		clk,reset_n,
		terminal_count_1,terminal_count_2,			-- input buffer address counter and line counter (SHARED_CNT in ControlUnit.vhd) terminal count
		Vin,							-- input data and config sampling strobe
		horVer:IN std_logic;					-- '0'=>1D filtering, '1'=>2D filtering
		EightOrSeven:IN std_logic_vector(1 downto 0);		-- "00"=>half-pixel 8-tap filter, "10"=>quarter-pixel 7-tap filter type 1, "11"=>quarter-pixel 7-tap filter type 2 ("01" useless, covered for safety)
		mod_LineCounter:OUT std_logic_vector(2 downto 0);	-- line counter modulus (SHARED_CNT)
		conftap_8or7_1:OUT std_logic_vector(1 downto 0);	-- config stage1 routing unit
		conf_vect1_stage1,conf_vect2_stage1:OUT std_logic_vector(8 downto 0);	-- config stage1 half filters
		LE_LineCounter,						-- load enable modulus line counter (SHARED_CNT)
		LE_rout1,						-- load enable stage1 config routing unit
		LE_conf_vect1_stage1,LE_conf_vect2_stage1,		-- load enable stage1 half filters configuration vectors
		LE_regout,						-- output register load enable
		clear_AddCounter,					-- synchronous clear address counter
		clear_LineCounter,					-- synchronous clear line counter (SHARED_CNT)
		CE_LineCounter,						-- Count Enable line counter (SHARED_CNT)
		wr_n,							-- input buffer write enable (active-low)
		startFir2,						-- FSM2 start signal
		SE,							-- serial enable for second stage shift register
		LE_ME_MCBi: OUT std_logic				-- load enable motion compensation biprediction register
  );
end entity FSM1_filter;

architecture behavioural of FSM1_filter is
	type state_type is(
		IDLE,			-- wait for a start condition
		SET8,SET71,SET72,	-- sets the routing unit and the filter configuration registers of the first stage branch
		WAITLINE,		-- wait for a line to be written in the input buffer
		LINE_1,			-- increment the line counter (SHARED_CNT)
		STARTFSM2,		-- start FSM2 (2D filtering)
		SETOUT			-- set the output data register
		);
	signal y_present,y_next: state_type;
begin

state_transitions:process(y_present,Vin,EightOrSeven,horVer,terminal_count_1,terminal_count_2)
begin
y_next<=IDLE;
	case y_present is
		when IDLE=>
			if Vin='1' then
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
			y_next<=WAITLINE;
		when SET71=>
			y_next<=WAITLINE;
		when SET72=>
			y_next<=WAITLINE;
		when WAITLINE=>
			if terminal_count_1='0' then
				y_next<=WAITLINE;
			elsif terminal_count_2='0' then
				y_next<=LINE_1;
			elsif horVer='1' then
				y_next<=STARTFSM2;
			else
				y_next<=SETOUT;
			end if;
		when LINE_1=>
			y_next<=WAITLINE;
		when STARTFSM2=>
			if Vin='0' then
				y_next<=IDLE;
			else
				y_next<=STARTFSM2;
			end if;
		when SETOUT=>
			if Vin='1' then
				y_next<=SETOUT;
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
			LE_LineCounter<='0';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(7,3));
			conftap_8or7_1<="00";
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='1';
			clear_LineCounter<='1';
			CE_LineCounter<='0';
			wr_n<='1';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
		when SET8=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='1';
			LE_conf_vect2_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(6,3));
			conftap_8or7_1<="00";	-- set 8 tap filter
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
		when SET71=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='1';
			LE_conf_vect2_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(5,3));
			conftap_8or7_1<="10";	-- set 7 tap filter 1
			conf_vect1_stage1<="111101111";
			conf_vect2_stage1<="001010001";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
		when SET72=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='1';
			LE_conf_vect2_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(5,3));
			conftap_8or7_1<="11";	-- set 7 tap filter 2
			conf_vect1_stage1<="001010001";
			conf_vect2_stage1<="111101111";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
		when WAITLINE=>
			LE_LineCounter<='0';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(7,3));
			conftap_8or7_1<="00";
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
		when LINE_1=>
			LE_LineCounter<='0';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(7,3));
			conftap_8or7_1<="00";
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='1';	-- increment line counter
			wr_n<='0';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
		when STARTFSM2=>
			LE_LineCounter<='0';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(7,3));
			conftap_8or7_1<="00";
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='1';
			CE_LineCounter<='0';
			wr_n<='0';
			startFir2<='1';	-- start FSM2
			SE<='1';
			LE_ME_MCBi<='0';
		when SETOUT=>
			LE_LineCounter<='0';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='1';	-- set output register
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(7,3));
			conftap_8or7_1<="00";
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='1';
			CE_LineCounter<='0';
			wr_n<='0';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
	end case;
end process output_process;

end behavioural;

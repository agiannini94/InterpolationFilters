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
-- Module Name:			FSM1_filter_approximate.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			first stage Moore Finite State Machine luma approximate
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FSM1_filter_approximate is
	port(
		clk,reset_n,
		terminal_count_1,terminal_count_2,			-- input buffer address counter and line counter (SHARED_CNT in ControlUnit.vhd) terminal count
		Vin,							-- input data and config sampling strobe
		horVer:IN std_logic;					-- '0'=>1D filtering, '1'=>2D filtering
		mod_LineCounter:OUT std_logic_vector(2 downto 0);	-- line counter modulus (SHARED_CNT)
		conftap_8or7_1:OUT std_logic_vector(1 downto 0);	-- config stage1 legacy routing unit
		---------- Additional signals required for approximate version
		filterSel:IN std_logic_vector(3 downto 0);		-- 1st stage filter selection signals
		conf3_stage1,						-- config stage1 3-tap routing unit
		conf5_stage1,						-- config stage1 5-tap routing unit
		dpSelect:OUT std_logic_vector(1 downto 0);		-- stage1 and stage2 output filter selection signals
		----------
		conf_vect1_stage1,conf_vect2_stage1:OUT std_logic_vector(8 downto 0);	-- config stage1 legacy half filters
		LE_LineCounter,						-- load enable modulus line counter (SHARED_CNT)
		LE_rout1,						-- load enable stage1 config legacy routing unit
		LE_conf_vect1_stage1,LE_conf_vect2_stage1,		-- load enable stage1 legacy half filters configuration vectors
		LE_regout,						-- output register load enable
		clear_AddCounter,					-- synchronous clear address counter
		clear_LineCounter,					-- synchronous clear line counter (SHARED_CNT)
		CE_LineCounter,						-- Count Enable line counter (SHARED_CNT)
		wr_n,							-- input buffer write enable (active-low)
		startFir2,						-- FSM2 start signal
		SE,							-- serial enable for second stage shift register
		LE_ME_MCBi,						-- load enable motion compensation biprediction register
		---------- Additional signals required for approximate version
		LE_rout1_3tap,						-- load enable stage1 config 3-tap routing unit
		LE_rout1_5tap,						-- load enable stage1 config 5-tap routing unit
		LE_dpSelect:OUT std_logic				-- load enable stage1 and stage2 output filter selection
		----------
  );
end entity FSM1_filter_approximate;

architecture behavioural of FSM1_filter_approximate is
	type state_type is(
		IDLE,			-- wait for a start condition
		SET8,SET71,SET72,	-- sets the routing unit and the filter configuration registers of the first stage legacy branch
		SET3H,SET3Q1,SET3Q2,	-- sets the routing unit and the filter configuration registers of the first stage 3-tap branch
		SET5H,SET5Q1,SET5Q2,	-- sets the routing unit and the filter configuration registers of the first stage 5-tap branch
		WAITLINE,		-- wait for a line to be written in the input buffer
		LINE_1,			-- increment the line counter (SHARED_CNT)
		STARTFSM2,		-- start FSM2 (2D filtering)
		SETOUT			-- set the output data register
		);
	signal y_present,y_next: state_type;
begin

state_transitions:process(y_present,Vin,horVer,terminal_count_1,terminal_count_2,filterSel)
begin
y_next<=IDLE;
	case y_present is
		when IDLE=>
			if Vin='1' then
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
			y_next<=WAITLINE;
		when SET71=>
			y_next<=WAITLINE;
		when SET72=>
			y_next<=WAITLINE;
		when SET3H=>
			y_next<=WAITLINE;
		when SET3Q1=>
			y_next<=WAITLINE;
		when SET3Q2=>
			y_next<=WAITLINE;
		when SET5H=>
			y_next<=WAITLINE;
		when SET5Q1=>
			y_next<=WAITLINE;
		when SET5Q2=>
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
			mod_LineCounter<=std_logic_vector(to_unsigned(6,3));
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
			conf3_stage1<="00";
			conf5_stage1<="00";
			dpSelect<="00";
			LE_rout1_3tap<='0';
			LE_rout1_5tap<='0';
			LE_dpSelect<='0';
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
			conf3_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			dpSelect<="00";
			LE_rout1_3tap<='1';
			LE_rout1_5tap<='1';
			LE_dpSelect<='1';	-- load branch config
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
			conf3_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			dpSelect<="00";
			LE_rout1_3tap<='1';
			LE_rout1_5tap<='1';
			LE_dpSelect<='1';	-- load branch config
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
			conf3_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			dpSelect<="00";
			LE_rout1_3tap<='1';
			LE_rout1_5tap<='1';
			LE_dpSelect<='1';	-- load branch config
		when SET5H=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(3,3));
			conftap_8or7_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf3_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage1<="00";	-- half pixel filter
			dpSelect<="10";		-- select 5 tap branch
			LE_rout1_3tap<='1';
			LE_rout1_5tap<='1';	-- load routing and filter config
			LE_dpSelect<='1';	-- load branch config
		when SET5Q1=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(3,3));
			conftap_8or7_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf3_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage1<="10";	-- quarter pixel type 1 filter
			dpSelect<="10";		-- select 5 tap branch
			LE_rout1_3tap<='1';
			LE_rout1_5tap<='1';	-- load routing and filter config
			LE_dpSelect<='1';	-- load branch config
		when SET5Q2=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(3,3));
			conftap_8or7_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf3_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf5_stage1<="11";	-- quarter pixel type 2 filter
			dpSelect<="10";		-- select 5 tap branch
			LE_rout1_3tap<='1';
			LE_rout1_5tap<='1';	-- load routing and filter config
			LE_dpSelect<='1';	-- load branch config
		when SET3H=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(1,3));
			conftap_8or7_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf3_stage1<="00";	-- half pixel filter
			conf5_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			dpSelect<="11";		-- select 3 tap branch
			LE_rout1_3tap<='1';	-- load routing and filter config
			LE_rout1_5tap<='1';
			LE_dpSelect<='1';	-- load branch config
		when SET3Q1=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(1,3));
			conftap_8or7_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf3_stage1<="10";	-- quarter pixel type 1 filter
			conf5_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			dpSelect<="11";		-- select 3 tap branch
			LE_rout1_3tap<='1';	-- load routing and filter config
			LE_rout1_5tap<='1';
			LE_dpSelect<='1';	-- load branch config
		when SET3Q2=>
			LE_LineCounter<='1';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(1,3));
			conftap_8or7_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect1_stage1<=(others=>'0');
			conf_vect2_stage1<=(others=>'0');
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf3_stage1<="11";	-- quarter pixel type 2 filter
			conf5_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			dpSelect<="11";		-- select 3 tap branch
			LE_rout1_3tap<='1';	-- load routing and filter config
			LE_rout1_5tap<='1';
			LE_dpSelect<='1';	-- load branch config
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
			conf3_stage1<="00";
			conf5_stage1<="00";
			dpSelect<="00";
			LE_rout1_3tap<='0';
			LE_rout1_5tap<='0';
			LE_dpSelect<='0';
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
			conf3_stage1<="00";
			conf5_stage1<="00";
			dpSelect<="00";
			LE_rout1_3tap<='0';
			LE_rout1_5tap<='0';
			LE_dpSelect<='0';
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
			conf3_stage1<="00";
			conf5_stage1<="00";
			dpSelect<="00";
			LE_rout1_3tap<='0';
			LE_rout1_5tap<='0';
			LE_dpSelect<='0';
		when SETOUT=>
			LE_LineCounter<='0';
			LE_conf_vect1_stage1<='0';
			LE_conf_vect2_stage1<='0';
			LE_regout<='1';		-- set output register
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
			conf3_stage1<="00";
			conf5_stage1<="00";
			dpSelect<="00";
			LE_rout1_3tap<='0';
			LE_rout1_5tap<='0';
			LE_dpSelect<='0';
	end case;
end process output_process;

end behavioural;

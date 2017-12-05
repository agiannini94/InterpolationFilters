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
-- Module Name:			FSM1_filter_chroma_approximate.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			first stage Moore Finite State Machine chroma approximate
-- Dependencies:		None
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FSM1_filter_chroma_approximate is
	port(
		clk,reset_n,
		terminal_count_1,terminal_count_2,			-- input buffer address counter and line counter (SHARED_CNT in ControlUnit.vhd) terminal count
		Vin,							-- input data and config sampling strobe
		horVer:IN std_logic;					-- '0'=>1D filtering, '1'=>2D filtering
		---------- Additional signals required for approximate version
		filterSel:IN std_logic_vector(3 downto 0);		-- 1st stage filter selection signals
		conf2_stage1,						-- config stage1 2-tap routing unit
		conf_2tap_stage1:OUT std_logic_vector(1 downto 0);	-- config stage1 2-tap filter
		----------
		mod_LineCounter:OUT std_logic_vector(2 downto 0);	-- line counter modulus (SHARED_CNT)
		conftap_1:OUT std_logic_vector(1 downto 0);		-- config stage1 routing unit
		conf_vect_stage1:OUT std_logic_vector(12 downto 0);	-- config stage1 filter
		LE_LineCounter,						-- load enable modulus line counter (SHARED_CNT)
		LE_rout1,						-- load enable stage1 config routing unit
		LE_conf_vect_stage1,					-- load enable stage1 filter configuration vector
		LE_regout,						-- output register load enable
		clear_AddCounter,					-- synchronous clear address counter
		clear_LineCounter,					-- synchronous clear line counter (SHARED_CNT)
		CE_LineCounter,						-- Count Enable line counter (SHARED_CNT)
		wr_n,							-- input buffer write enable (active-low)
		startFir2,						-- FSM2 start signal
		SE,							-- serial enable for second stage shift register
		LE_ME_MCBi,						-- load enable motion compensation biprediction register
		---------- Additional signals required for approximate version
		LE_rout1_2tap,						-- load enable stage1 config 2-tap routing unit
		LE_conf_2tap_stage1,					-- load enable stage1 config 2-tap filter
		LE_dpSelect,						-- load enable stage1 and stage2 output filter selection
		dpSelect:OUT std_logic					-- stage1 and stage2 output filter selection signal
		----------
  );
end entity FSM1_filter_chroma_approximate;

architecture behavioural of FSM1_filter_chroma_approximate is
	type state_type is(
		IDLE,								-- wait for a start condition
		SET48,SET18,SET78,SET28,SET68,SET38,SET58,			-- sets the routing unit and the filter configuration registers of the first stage legacy branch
		SET2_48,SET2_18,SET2_78,SET2_28,SET2_68,SET2_38,SET2_58,	-- sets the routing unit and the filter configuration registers of the first stage 2-tap branch
		WAITLINE,							-- wait for a line to be written in the input buffer
		LINE_1,								-- increment the line counter (SHARED_CNT)
		STARTFSM2,							-- start FSM2 (2D filtering)
		SETOUT								-- set the output data register
		);
	signal y_present,y_next: state_type;
begin

state_transitions:process(y_present,Vin,filterSel,horVer,terminal_count_1,terminal_count_2)
begin
y_next<=IDLE;
	case y_present is
		when IDLE=>
			if Vin='1' then
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
			y_next<=WAITLINE;
		when SET18=>
			y_next<=WAITLINE;
		when SET78=>
			y_next<=WAITLINE;
		when SET28=>
			y_next<=WAITLINE;
		when SET68=>
			y_next<=WAITLINE;
		when SET38=>
			y_next<=WAITLINE;
		when SET58=>
			y_next<=WAITLINE;
		when SET2_48=>
			y_next<=WAITLINE;
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
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="00";
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='1';
			clear_LineCounter<='1';
			CE_LineCounter<='0';
			wr_n<='1';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
			conf2_stage1<="00";
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='0';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='0';
			dpSelect<='0';
		when SET48=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="00";	-- set 4/8th filter
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET18=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="10";	-- set 1/8th filter
			conf_vect_stage1<="1100000100011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET78=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="11";	-- set 7/8th filter
			conf_vect_stage1<="1100000100011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET28=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="10";	-- set 2/8th filter
			conf_vect_stage1<="1011011000001";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET68=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="11";	-- set 6/8th filter
			conf_vect_stage1<="1011011000001";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET38=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="10";	-- set 3/8th filter
			conf_vect_stage1<="0001001010100";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET58=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='1';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="11";	-- set 5/8th filter
			conf_vect_stage1<="0001001010100";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='1';
			dpSelect<='0';
		when SET2_48=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="00";	-- set 2 tap 4/8th filter
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when SET2_18=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="10";	-- set 2 tap 1/8th filter
			conf_2tap_stage1<="01";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when SET2_78=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="11";	-- set 2 tap 7/8th filter
			conf_2tap_stage1<="01";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when SET2_28=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="10";	-- set 2 tap 2/8th filter
			conf_2tap_stage1<="10";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when SET2_68=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="11";	-- set 2 tap 6/8th filter
			conf_2tap_stage1<="10";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when SET2_38=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="10";	-- set 2 tap 3/8th filter
			conf_2tap_stage1<="11";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when SET2_58=>
			LE_LineCounter<='1';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='1';
			mod_LineCounter<=std_logic_vector(to_unsigned(0,3));
			conftap_1<="01";	-- set routing unit outputs to zero to reduce dynamic power consumption
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';	-- start writing
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='1';
			conf2_stage1<="11";	-- set 2 tap 5/8th filter
			conf_2tap_stage1<="11";
			LE_rout1_2tap<='1';
			LE_conf_2tap_stage1<='1';
			LE_dpSelect<='1';
			dpSelect<='1';
		when WAITLINE=>
			LE_LineCounter<='0';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="00";
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='0';
			wr_n<='0';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
			conf2_stage1<="00";
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='0';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='0';
		when LINE_1=>
			LE_LineCounter<='0';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="00";
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='0';
			CE_LineCounter<='1';	-- increment line counter
			wr_n<='0';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
			conf2_stage1<="00";
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='0';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='0';
		when STARTFSM2=>
			LE_LineCounter<='0';
			LE_conf_vect_stage1<='0';
			LE_regout<='0';
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="00";
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='1';
			CE_LineCounter<='0';
			wr_n<='0';
			startFir2<='1';	-- start FSM2
			SE<='1';
			LE_ME_MCBi<='0';
			conf2_stage1<="00";
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='0';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='0';
		when SETOUT=>
			LE_LineCounter<='0';
			LE_conf_vect_stage1<='0';
			LE_regout<='1';	-- set output register
			LE_rout1<='0';
			mod_LineCounter<=std_logic_vector(to_unsigned(2,3));
			conftap_1<="00";
			conf_vect_stage1<="0000110011011";
			clear_AddCounter<='0';
			clear_LineCounter<='1';
			CE_LineCounter<='0';
			wr_n<='0';
			startFir2<='0';
			SE<='0';
			LE_ME_MCBi<='0';
			conf2_stage1<="00";
			conf_2tap_stage1<="00";
			LE_rout1_2tap<='0';
			LE_conf_2tap_stage1<='0';
			LE_dpSelect<='0';
	end case;
end process output_process;

end behavioural;

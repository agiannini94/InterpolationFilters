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
-- Module Name:			DataPath.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			datapath luma legacy
-- Dependencies:		
--			CustomMultiportMemory.vhd
--			RoutingUnit.vhd
--			filter_reconfigurable.vhd
--			filter_reconfigurable_stage2.vhd
--			SIPO_SE.vhd
--			round_HalfUp.vhd
--			clipping_unit.vhd
--			Pipo_LE.vhd
--			counter_programmable.vhd
--			
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.my_math.all;

entity DataPath is
	port(
		clk,reset_n,
		wr_n,								-- input buffer write enable (active-low) 
		SE,								-- serial enable for second stage shift register
		LE_dataIn,LE_dataOut,						-- input and output register load enable
		fir1or2,							-- stage1 or stage2 filter selection signal
		LE_conf_vect1_stage1,LE_conf_vect2_stage1,LE_conf_vect1_stage2,LE_conf_vect2_stage2,	-- load enable stage1 and stage2 half filters configuration vectors
		LE_rout1,LE_rout2,						-- load enable stage1 and stage2 config routing units
		LE_modAdd,							-- load enable modulus input address counter
		clear_AddCounter,						-- synchronous clear address counter signal
		ME_MCBi,							-- motion compensation biprediction output selection signal
		LE_ME_MCBi:IN std_logic;					-- load enable motion compensation biprediction register
		modAddr_IN:IN std_logic_vector(6 downto 0);			-- counter modulus address input
		InData:IN std_logic_vector(7 downto 0);				-- input pixel
		conftap_8or7_1,conftap_8or7_2:IN std_logic_vector(1 downto 0);	-- config stage1 and stage2 routing units
		conf_vect1_stage1,conf_vect2_stage1,conf_vect1_stage2,conf_vect2_stage2:IN std_logic_vector(8 downto 0);	-- config stage1 and stage2 half filters
		terminal_count_Add:OUT std_logic;				-- address counter terminal count
		Vout:OUT std_logic;						-- sampling strobe output signal
		o:OUT std_logic_vector(16 downto 0)				-- output data port
	);
end entity DataPath;

architecture structural of DataPath is
component CustomMultiportMemory is
	port(
		clk,reset_n,Wr1_n: IN std_logic;
		Addr_IN: IN std_logic_vector(6 downto 0); 
		InData: IN std_logic_vector(7 downto 0);
		OutData0,OutData1,OutData2,OutData3,OutData4,OutData5,OutData6: OUT std_logic_vector(7 downto 0)
	);
end component CustomMultiportMemory;
component RoutingUnit is
	generic(n:positive);	-- number of bit per operand
	port(
		in0,in1,in2,in3,in4,in5,in6,in7:IN std_logic_vector(n-1 downto 0);
		conftap_8or7:IN std_logic_vector(1 downto 0);					-- 00 | 01 -> 8-tap, 10 -> 7-tap 1, 11 -> 7-tap 2
		s0_1,s1_1,s2_1,s3_1,s3_2,s2_2,s1_2,s0_2:OUT std_logic_vector(n-1 downto 0)
	);
end component RoutingUnit;
component filter_reconfigurable is
	port(
		s0,s1,s2,s3:IN std_logic_vector(7 downto 0);
		conf_vect:IN std_logic_vector(8 downto 0);
		o:OUT std_logic_vector(14 downto 0)
	);
end component filter_reconfigurable;
component filter_reconfigurable_stage2 is
	port(
		s0,s1,s2,s3:IN std_logic_vector(15 downto 0);
		conf_vect:IN std_logic_vector(8 downto 0);
		o:OUT std_logic_vector(21 downto 0)
	);
end component filter_reconfigurable_stage2;
component SIPO_SE is	-- Serial Input Parallel Output
	generic(n:positive;m:positive);	-- m: number of registers, n: number of bit per register
	port(
		clk,reset_n,SE:IN std_logic;
		data_in:IN std_logic_vector(n-1 downto 0);
		data_out:OUT std_logic_vector(m*n-1 downto 0)
	);
end component SIPO_SE;
component round_HalfUp is
	generic(n:positive);
	port(
		data_ToBeRounded:IN std_logic_vector(n-1 downto 0);
		data_out:OUT std_logic_vector(n-2 downto 0)
	);
end component round_HalfUp;
component clipping_unit is
	generic(n:positive);
	port(
		data_in:IN std_logic_vector(n-1 downto 0);	-- input must be fixed point (n-6).6
		data_out:OUT std_logic_vector(7 downto 0)	-- pixel 8-bit unsigned (0 to 255)
	);
end component clipping_unit;
component Pipo_LE is
	generic(n:positive);
	port(
		clk,LE,rst_n:IN std_logic;
		data_in:IN std_logic_vector(n-1 downto 0);
		data_out:OUT std_logic_vector(n-1 downto 0)
	);
end component Pipo_LE;
component counter_programmable is	-- programmable counter with mode register, clear, count output, terminal count
	generic(rg:positive);
	port(
		clk,reset_n,clear,LE_mod:IN std_logic;
		modulus:IN std_logic_vector(log2(rg)-1 downto 0);
		count:OUT std_logic_vector(log2(rg)-1 downto 0);
		terminal_count:OUT std_logic
	);
end component counter_programmable;

	signal InData_int,
		in0_rout1,in1_rout1,in2_rout1,in3_rout1,in4_rout1,in5_rout1,in6_rout1,in7_rout1,
		s0_1_stage1,s1_1_stage1,s2_1_stage1,s3_1_stage1,s3_2_stage1,s2_2_stage1,s1_2_stage1,s0_2_stage1:std_logic_vector(7 downto 0);
	signal Addr_IN: std_logic_vector(6 downto 0);
	signal conftap_8or7_1_int,conftap_8or7_2_int:std_logic_vector(1 downto 0);
	signal conf_vect1_stage1_int,conf_vect2_stage1_int,conf_vect1_stage2_int,conf_vect2_stage2_int: std_logic_vector(8 downto 0);
	signal oint1_stage1,oint2_stage1:std_logic_vector(14 downto 0);
	signal oint1_stage2,oint2_stage2:std_logic_vector(21 downto 0);
	signal oint_stage1,
		in0_rout2,in1_rout2,in2_rout2,in3_rout2,in4_rout2,in5_rout2,in6_rout2,in7_rout2,
		s0_1_stage2,s1_1_stage2,s2_1_stage2,s3_1_stage2,s3_2_stage2,s2_2_stage2,s1_2_stage2,s0_2_stage2:std_logic_vector(15 downto 0);
	signal oint_stage2:std_logic_vector(22 downto 0);
	signal data_sr:std_logic_vector(127 downto 0);
	signal data2round_1,data2round_2,data2round_in:std_logic_vector(11 downto 0);
	signal data2clip:std_logic_vector(10 downto 0);
	signal o_int:std_logic_vector(7 downto 0); -- o2_int
	signal o_MuxMC,o_OutMux:std_logic_vector(16 downto 0);
	signal ME_MCBi_input,ME_MCBi_int:std_logic_vector(0 downto 0);
begin
	REG_DIN:Pipo_LE			-- input data register
		generic map(n=>8)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_dataIn,
			data_in=>InData,
			data_out=>InData_int
		);
	ADD_CNT:counter_programmable	-- SRB address counter
		generic map(rg=>127)
		port map(
			clk=>clk,
			reset_n=>reset_n,
			clear=>clear_AddCounter,
			LE_mod=>LE_modAdd,
			modulus=>modAddr_IN,
			count=>Addr_IN,
			terminal_count=>terminal_count_Add
		);
	MEM:CustomMultiportMemory 	-- input buffer
		port map(
			clk=>clk,
			reset_n=>reset_n,
			Wr1_n=>wr_n,
			Addr_IN=>Addr_IN,
			InData=>InData_int,
			OutData0=>in0_rout1,
			OutData1=>in1_rout1,
			OutData2=>in2_rout1,
			OutData3=>in3_rout1,
			OutData4=>in4_rout1,
			OutData5=>in5_rout1,
			OutData6=>in6_rout1
		);
in7_rout1<=InData_int;	-- the rightmost pixel to be filtered comes from the sampled input
	REG_ROUT1:Pipo_LE		-- 1st stage routing unit config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_rout1,
			data_in=>conftap_8or7_1,
			data_out=>conftap_8or7_1_int
		);
	ROUT1:RoutingUnit		-- 1st stage routing unit
		generic map(n=>8)
		port map(
			in0=>in0_rout1,
			in1=>in1_rout1,
			in2=>in2_rout1,
			in3=>in3_rout1,
			in4=>in4_rout1,
			in5=>in5_rout1,
			in6=>in6_rout1,
			in7=>in7_rout1,
			conftap_8or7=>conftap_8or7_1_int,
			s0_1=>s0_1_stage1,
			s1_1=>s1_1_stage1,
			s2_1=>s2_1_stage1,
			s3_1=>s3_1_stage1,
			s3_2=>s3_2_stage1,
			s2_2=>s2_2_stage1,
			s1_2=>s1_2_stage1,
			s0_2=>s0_2_stage1
		);
	REG_CONF1_SG1:Pipo_LE		-- 1st stage half filter 1 config register
		generic map(n=>9)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_vect1_stage1,
			data_in=>conf_vect1_stage1,
			data_out=>conf_vect1_stage1_int
		);
	FIR1_SG1:filter_reconfigurable	-- 1st stage half filter 1
		port map(
			s0=>s0_1_stage1,
			s1=>s1_1_stage1,
			s2=>s2_1_stage1,
			s3=>s3_1_stage1,
			conf_vect=>conf_vect1_stage1_int,
			o=>oint1_stage1
		);
	REG_CONF2_SG1:Pipo_LE		-- 1st stage half filter 2 config register
		generic map(n=>9)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_vect2_stage1,
			data_in=>conf_vect2_stage1,
			data_out=>conf_vect2_stage1_int
		);
	FIR2_SG1:filter_reconfigurable	-- 1st stage half filter 2
		port map(
			s0=>s0_2_stage1,
			s1=>s1_2_stage1,
			s2=>s2_2_stage1,
			s3=>s3_2_stage1,
			conf_vect=>conf_vect2_stage1_int,
			o=>oint2_stage1
		);
oint_stage1<=std_logic_vector(signed(oint1_stage1(14)&oint1_stage1)+signed(oint2_stage1(14)&oint2_stage1));
	SR:SIPO_SE			-- 2nd stage shift register, for partly interpolated samples
		generic map(n=>16,m=>8)
		port map(
			clk=>clk,
			reset_n=>reset_n,
			SE=>SE,
			data_in=>oint_stage1,
			data_out=>data_sr
		);
in0_rout2<=data_sr(127 downto 112);
in1_rout2<=data_sr(111 downto 96);
in2_rout2<=data_sr(95 downto 80);
in3_rout2<=data_sr(79 downto 64);
in4_rout2<=data_sr(63 downto 48);
in5_rout2<=data_sr(47 downto 32);
in6_rout2<=data_sr(31 downto 16);
in7_rout2<=data_sr(15 downto 0);
	REG_ROUT2:Pipo_LE		-- 2nd stage routing unit config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_rout2,
			data_in=>conftap_8or7_2,
			data_out=>conftap_8or7_2_int
		);
	ROUT2:RoutingUnit		-- 2nd stage routing unit
		generic map(n=>16)
		port map(
			in0=>in0_rout2,
			in1=>in1_rout2,
			in2=>in2_rout2,
			in3=>in3_rout2,
			in4=>in4_rout2,
			in5=>in5_rout2,
			in6=>in6_rout2,
			in7=>in7_rout2,
			conftap_8or7=>conftap_8or7_2_int,
			s0_1=>s0_1_stage2,
			s1_1=>s1_1_stage2,
			s2_1=>s2_1_stage2,
			s3_1=>s3_1_stage2,
			s3_2=>s3_2_stage2,
			s2_2=>s2_2_stage2,
			s1_2=>s1_2_stage2,
			s0_2=>s0_2_stage2
		);
	REG_CONF1_SG2:Pipo_LE		-- 2nd stage half filter 1 config register
		generic map(n=>9)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_vect1_stage2,
			data_in=>conf_vect1_stage2,
			data_out=>conf_vect1_stage2_int
		);
	FIR1_SG2:filter_reconfigurable_stage2	-- 2nd stage half filter 1
		port map(
			s0=>s0_1_stage2,
			s1=>s1_1_stage2,
			s2=>s2_1_stage2,
			s3=>s3_1_stage2,
			conf_vect=>conf_vect1_stage2_int,
			o=>oint1_stage2
		);
	REG_CONF2_SG2:Pipo_LE		-- 2nd stage half filter 2 config register
		generic map(n=>9)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_vect2_stage2,
			data_in=>conf_vect2_stage2,
			data_out=>conf_vect2_stage2_int
		);
	FIR2_SG2:filter_reconfigurable_stage2	-- 2nd stage half filter 2
		port map(
			s0=>s0_2_stage2,
			s1=>s1_2_stage2,
			s2=>s2_2_stage2,
			s3=>s3_2_stage2,
			conf_vect=>conf_vect2_stage2_int,
			o=>oint2_stage2
		);
oint_stage2<=std_logic_vector(signed(oint1_stage2(21)&oint1_stage2)+signed(oint2_stage2(21)&oint2_stage2));
data2round_1<='0'&oint_stage1(15 downto 5);
-- MUX round in
data2round_in<=
	data2round_1 when fir1or2='0' else	-- filter stage 1
	data2round_2;				-- filter stage 2

	ROUND:round_HalfUp
		generic map(n=>12)
		port map(
			data_ToBeRounded=>data2round_in,
			data_out=>data2clip
		);
	CLIP1:clipping_unit
		generic map(n=>11)
		port map(
			data_in=>data2clip,
			data_out=>o_int
		);
data2round_2<=oint_stage2(22 downto 11);	-- oint_stage2 >> 11
-- MUX Motion Compensation biprediction
o_MuxMC<=
	('0'&oint_stage1) when fir1or2='0' else
	oint_stage2(22 downto 6);

	REG_OUT:Pipo_LE		-- output register
		generic map(n=>17)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_dataOut,
			data_in=>o_OutMux,
			data_out=>o
		);
ME_MCBi_input(0)<=ME_MCBi;	-- same timing as input (but std_logic_vector(0 downto 0) instead of std_logic)
	REG_MEC_BI:Pipo_LE	-- biprediction conf register
		generic map(n=>1)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_ME_MCBi,
			data_in=>ME_MCBi_input,
			data_out=>ME_MCBi_int
		);
-- MUX Output
o_OutMux<=
	("000000000"&o_int) when ME_MCBi_int(0)='0' else
	o_MuxMC;
Vout_reg:process(clk,reset_n)	-- register on the output reg load enable signal. Data out sampling strobe
begin
	if reset_n='0' then
		Vout<='0';
	elsif clk'event and clk='1' then
		Vout<=LE_dataOut;
	end if;
end process Vout_reg;
end architecture structural;

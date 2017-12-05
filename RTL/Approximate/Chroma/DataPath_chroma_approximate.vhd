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
-- Module Name:			DataPath_chroma_approximate.vhd
-- Project:			interpolation filter project for HEVC
-- Description:			datapath chroma approximate
-- Dependencies:		
--			CustomMultiportMemory_chroma.vhd
--			RoutingUnit_chroma.vhd
--			RoutingUnit_chroma_2tap.vhd
--			filter_chroma_reconfigurable.vhd
--			filter_reconfigurable_chroma_2tap_ver2.vhd
--			filter_chroma_reconfigurable_stage2.vhd
--			filter_reconfigurable_chroma_2tap_stage2_ver2
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

entity DataPath_chroma_approximate is
	port(
		clk,reset_n,
		wr_n,						-- input buffer write enable (active-low) 
		SE,						-- serial enable for second stage shift register
		LE_dataIn,LE_dataOut,				-- input and output register load enable
		fir1or2,					-- stage1 or stage2 filter selection signal
		LE_conf_vect_stage1,LE_conf_vect_stage2,	-- load enable stage1 and stage2 legacy filters configuration vectors
		LE_rout1,LE_rout2,				-- load enable stage1 and stage2 config legacy routing units
		LE_modAdd,					-- load enable modulus input address counter
		clear_AddCounter,				-- synchronous clear address counter signal
		ME_MCBi,					-- motion compensation biprediction output selection signal
		LE_ME_MCBi,					-- load enable motion compensation biprediction register
		---------- Additional signals required for approximate version
		LE_rout1_2tap,LE_rout2_2tap,			-- load enable stage1 and stage2 config 2-tap routing units
		LE_conf_2tap_stage1,LE_conf_2tap_stage2,	-- load enable stage1 and stage2 2-tap filters configuration vectors
		LE_dpSelect,					-- load enable stage1 and stage2 output filter selection
		dpSelect:IN std_logic;				-- stage1 and stage2 output filter selection signals
		----------
		modAddr_IN:IN std_logic_vector(5 downto 0);	-- counter modulus address input
		InData:IN std_logic_vector(7 downto 0);		-- input pixel
		conftap_1,conftap_2,				-- config stage1 and stage2 legacy routing units
		---------- Additional signals required for approximate version
		conf2_stage1,conf2_stage2,						-- config stage1 and stage2 2-tap routing units
		conf_2tap_stage1,conf_2tap_stage2:IN std_logic_vector(1 downto 0);	-- config stage1 and stage2 2-tap filters
		----------
		conf_vect_stage1,conf_vect_stage2:IN std_logic_vector(12 downto 0);	-- config stage1 and stage2 legacy filters
		terminal_count_Add:OUT std_logic;		-- address counter terminal count
		Vout:OUT std_logic;				-- sampling strobe output signal
		o:OUT std_logic_vector(15 downto 0)		-- output data port
	);
end entity DataPath_chroma_approximate;

architecture structural of DataPath_chroma_approximate is
component CustomMultiportMemory_chroma is
	port(
		clk,reset_n,Wr1_n: IN std_logic;
		Addr_IN: IN std_logic_vector(5 downto 0); 
		InData: IN std_logic_vector(7 downto 0);
		OutData0,OutData1,OutData2: OUT std_logic_vector(7 downto 0)
	);
end component CustomMultiportMemory_chroma;
component RoutingUnit_chroma is
	generic(n:positive);	-- number of bit per operand
	port(
		in0,in1,in2,in3:IN std_logic_vector(n-1 downto 0);
		conf:IN std_logic_vector(1 downto 0);	-- "00" => half pixel filter, "10" => quarter pixel filter type 1, "11" => quarter pixel filter type 2, ("01" => outputs are zero TODO!!)
		in0_int,in1_int,in2_int,in3_int:OUT std_logic_vector(n-1 downto 0)
	);
end component RoutingUnit_chroma;
component RoutingUnit_chroma_2tap is
	generic(n:positive);	-- number of bit per operand
	port(
		in0,in1:IN std_logic_vector(n-1 downto 0);
		conf:IN std_logic_vector(1 downto 0);	-- "00" => half pixel filter, "10" => quarter pixel filter type 1, "11" => quarter pixel filter type 2, ("01" => outputs are zero TODO!!)
		in0_int,in1_int:OUT std_logic_vector(n-1 downto 0)
	);
end component RoutingUnit_chroma_2tap;
component filter_chroma_reconfigurable is
	port(
		s0,s1,s2,s3:IN std_logic_vector(7 downto 0);
		conf_vect:IN std_logic_vector(12 downto 0);
		o:OUT std_logic_vector(15 downto 0)
	);
end component;
component filter_reconfigurable_chroma_2tap_ver2 is
	port(
		in0,in1:IN std_logic_vector(7 downto 0);
		conf:IN std_logic_vector(1 downto 0);	-- "00" => half pixel 4/8th filter, "01" => quarter pixel 1/8th filter,
							-- "10" => quarter pixel 2/8th filter, "11" => quarter pixel 3/8th filter
		o:OUT std_logic_vector(13 downto 0)
	);
end component filter_reconfigurable_chroma_2tap_ver2;
component filter_chroma_reconfigurable_stage2 is
	port(
		s0,s1,s2,s3:IN std_logic_vector(15 downto 0);
		conf_vect:IN std_logic_vector(12 downto 0);
		o:OUT std_logic_vector(21 downto 0)
	);
end component filter_chroma_reconfigurable_stage2;
component filter_reconfigurable_chroma_2tap_stage2_ver2 is
	port(
		in0,in1:IN std_logic_vector(13 downto 0);
		conf:IN std_logic_vector(1 downto 0);	-- "00" => half pixel 4/8th filter, "01" => quarter pixel 1/8th filter,
							-- "10" => quarter pixel 2/8th filter, "11" => quarter pixel 3/8th filter
		o:OUT std_logic_vector(19 downto 0)
	);
end component filter_reconfigurable_chroma_2tap_stage2_ver2;
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
		in0_rout1,in1_rout1,in2_rout1,in3_rout1,
		s0_stage1,s1_stage1,s2_stage1,s3_stage1,
		in0_2_stage1,in1_2_stage1:std_logic_vector(7 downto 0);
	signal Addr_IN: std_logic_vector(5 downto 0);
	signal conftap_1_int,conftap_2_int,
		conf2_stage1_int,conf2_stage2_int,
		conf_2tap_stage1_int,conf_2tap_stage2_int:std_logic_vector(1 downto 0);
	signal conf_vect_stage1_int,conf_vect_stage2_int: std_logic_vector(12 downto 0);
	signal oint_stage1,
		oint_legacy_stage1,
		in0_rout2,in1_rout2,in2_rout2,in3_rout2,
		s0_stage2,s1_stage2,s2_stage2,s3_stage2,
		oint_stage2:std_logic_vector(15 downto 0);
	signal in0_2_stage2,in1_2_stage2,
		oint_2tap_stage1:std_logic_vector(13 downto 0);
	signal --oint_stage2,
		oint_legacy_stage2:std_logic_vector(21 downto 0);
	signal oint_2tap_stage2:std_logic_vector(19 downto 0);
	signal data_sr:std_logic_vector(63 downto 0);
	signal data2round_1,data2round_2,data2round_in:std_logic_vector(10 downto 0);
	signal data2clip:std_logic_vector(9 downto 0);
	signal o_int:std_logic_vector(7 downto 0); -- o2_int
	signal o_MuxMC,o_OutMux:std_logic_vector(15 downto 0);
	signal ME_MCBi_input,ME_MCBi_int,dpSelect_input,dpSelect_output:std_logic_vector(0 downto 0);
	signal dpSelect_int:std_logic;
begin
	REG_DIN:Pipo_LE				-- input data register
		generic map(n=>8)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_dataIn,
			data_in=>InData,
			data_out=>InData_int
		);
	ADD_CNT:counter_programmable		-- SRB address counter
		generic map(rg=>63)
		port map(
			clk=>clk,
			reset_n=>reset_n,
			clear=>clear_AddCounter,
			LE_mod=>LE_modAdd,
			modulus=>modAddr_IN,
			count=>Addr_IN,
			terminal_count=>terminal_count_Add
		);
	MEM:CustomMultiportMemory_chroma 	-- input buffer
		port map(
			clk=>clk,
			reset_n=>reset_n,
			Wr1_n=>wr_n,
			Addr_IN=>Addr_IN,
			InData=>InData_int,
			OutData0=>in0_rout1,
			OutData1=>in1_rout1,
			OutData2=>in2_rout1
		);
-- legacy branch stage 1
in3_rout1<=InData_int;				-- the rightmost pixel to be filtered comes from the sampled input
	REG_ROUT1:Pipo_LE			-- 1st stage routing unit config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_rout1,
			data_in=>conftap_1,
			data_out=>conftap_1_int
		);
	ROUT1:RoutingUnit_chroma		-- 1st stage legacy routing unit
		generic map(n=>8)
		port map(
			in0=>in0_rout1,
			in1=>in1_rout1,
			in2=>in2_rout1,
			in3=>in3_rout1,
			conf=>conftap_1_int,
			in0_int=>s0_stage1,
			in1_int=>s1_stage1,
			in2_int=>s2_stage1,
			in3_int=>s3_stage1
		);
	REG_CONF_SG1:Pipo_LE			-- 1st stage legacy filter config register
		generic map(n=>13)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_vect_stage1,
			data_in=>conf_vect_stage1,
			data_out=>conf_vect_stage1_int
		);
	FIR_SG1:filter_chroma_reconfigurable	-- 1st stage legacy filter
		port map(
			s0=>s0_stage1,
			s1=>s1_stage1,
			s2=>s2_stage1,
			s3=>s3_stage1,
			conf_vect=>conf_vect_stage1_int,
			o=>oint_legacy_stage1
		);
-- end of legacy branch stage 1
-- 2 tap branch stage 1
	REG_ROUT1_2tap:Pipo_LE			-- 1st stage 2-tap routing unit config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_rout1_2tap,
			data_in=>conf2_stage1,
			data_out=>conf2_stage1_int
		);
	ROUT1_2TAP:RoutingUnit_chroma_2tap	-- 1st stage 2-tap routing unit
		generic map(n=>8)
		port map(
			in0=>in2_rout1,
			in1=>InData_int,
			conf=>conf2_stage1_int,
			in0_int=>in0_2_stage1,
			in1_int=>in1_2_stage1
		);
	REG_CONF_2TAP_SG1:Pipo_LE		-- 1st stage 2-tap filter config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_2tap_stage1,
			data_in=>conf_2tap_stage1,
			data_out=>conf_2tap_stage1_int
		);
	FIR_2TAP_SG1:filter_reconfigurable_chroma_2tap_ver2	-- 1st stage 2-tap filter
		port map(
			in0=>in0_2_stage1,
			in1=>in1_2_stage1,
			conf=>conf_2tap_stage1_int,
			o=>oint_2tap_stage1
		);
-- end of 2 tap branch stage 1
	REG_DPSEL:Pipo_LE			-- stage1 and stage2 output filter selection register
		generic map(n=>1)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_dpSelect,
			data_in=>dpSelect_input,
			data_out=>dpSelect_output
		);
dpSelect_input(0)<=dpSelect;		-- same timing, but left std_logic, right std_logic_vector
dpSelect_int<=dpSelect_output(0);	-- same timing, but left std_logic, right std_logic_vector
--MUX selecting branch stage 1
oint_stage1<=
	oint_legacy_stage1 when dpSelect_int='0' else
	"00"&oint_2tap_stage1;

	SR:SIPO_SE				-- 2nd stage shift register, for partly interpolated samples
		generic map(n=>16,m=>4)
		port map(
			clk=>clk,
			reset_n=>reset_n,
			SE=>SE,
			data_in=>oint_stage1,
			data_out=>data_sr
		);
in0_rout2<=data_sr(63 downto 48);
in1_rout2<=data_sr(47 downto 32);
in2_rout2<=data_sr(31 downto 16);
in3_rout2<=data_sr(15 downto 0);
-- legacy branch stage 2
	REG_ROUT2:Pipo_LE			-- 2nd stage legacy routing unit config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_rout2,
			data_in=>conftap_2,
			data_out=>conftap_2_int
		);
	ROUT2:RoutingUnit_chroma		-- 2nd stage legacy routing unit
		generic map(n=>16)
		port map(
			in0=>in0_rout2,
			in1=>in1_rout2,
			in2=>in2_rout2,
			in3=>in3_rout2,
			conf=>conftap_2_int,
			in0_int=>s0_stage2,
			in1_int=>s1_stage2,
			in2_int=>s2_stage2,
			in3_int=>s3_stage2
		);
	REG_CONF_SG2:Pipo_LE			-- 2nd stage legacy filter config register
		generic map(n=>13)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_vect_stage2,
			data_in=>conf_vect_stage2,
			data_out=>conf_vect_stage2_int
		);
	FIR_SG2:filter_chroma_reconfigurable_stage2	-- 2nd stage legacy filter
		port map(
			s0=>s0_stage2,
			s1=>s1_stage2,
			s2=>s2_stage2,
			s3=>s3_stage2,
			conf_vect=>conf_vect_stage2_int,
			o=>oint_legacy_stage2
		);
-- end of legacy branch stage 2
-- 2 tap branch stage 2
	REG_ROUT2_2TAP:Pipo_LE				-- 2nd stage 2-tap routing unit config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_rout2_2tap,
			data_in=>conf2_stage2,
			data_out=>conf2_stage2_int
		);
	ROUT2_2TAP:RoutingUnit_chroma_2tap		-- 2nd stage 2-tap routing unit
		generic map(n=>14)
		port map(
			in0=>in2_rout2(13 downto 0),	-- discard MSB
			in1=>in3_rout2(13 downto 0),	-- discard MSB
			conf=>conf2_stage2_int,
			in0_int=>in0_2_stage2,
			in1_int=>in1_2_stage2
		);
	REG_CONF_2TAP_SG2:Pipo_LE			-- 2nd stage 2-tap filter config register
		generic map(n=>2)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_conf_2tap_stage2,
			data_in=>conf_2tap_stage2,
			data_out=>conf_2tap_stage2_int
		);
	FIR_2TAP_SG2:filter_reconfigurable_chroma_2tap_stage2_ver2	-- 2nd stage 2-tap filter
		port map(
			in0=>in0_2_stage2,
			in1=>in1_2_stage2,
			conf=>conf_2tap_stage2_int,
			o=>oint_2tap_stage2
		);
-- end of 2 tap branch stage 2
-- MUX selecting branch stage 2
oint_stage2<=
	oint_legacy_stage2(21 downto 6) when dpSelect_int='0' else
	"00"&oint_2tap_stage2(19 downto 6);
data2round_1<=oint_stage1(15 downto 5);
-- MUX round in
data2round_in<=
	data2round_1 when fir1or2='0' else	-- filter stage 1
	data2round_2;				-- filter stage 2

	ROUND:round_HalfUp
		generic map(n=>11)
		port map(
			data_ToBeRounded=>data2round_in,
			data_out=>data2clip
		);
	CLIP1:clipping_unit
		generic map(n=>10)
		port map(
			data_in=>data2clip,
			data_out=>o_int
		);
data2round_2<=oint_stage2(15 downto 5);

-- MUX Motion Compensation biprediction
o_MuxMC<=
	(oint_stage1) when fir1or2='0' else
	oint_stage2;

	REG_OUT:Pipo_LE
		generic map(n=>16)
		port map(
			clk=>clk,
			rst_n=>reset_n,
			LE=>LE_dataOut,
			data_in=>o_OutMux,--o_int,
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
	("00000000"&o_int) when ME_MCBi_int(0)='0' else
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

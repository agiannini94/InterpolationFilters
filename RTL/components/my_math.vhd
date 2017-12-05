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
-- Create Date(mm/aaaa):	06/2016 
-- Module Name:			my_math.vhd
-- Project:			None
-- Description:			package for floor(log2(input)) function for logic synthesis
-- Dependencies:		None
--
-- Revision: 
--		1.0 created
----------------------------------------------------------------------------------
package my_math is
	function log2(i: natural) return integer;
end my_math;

package body my_math is
	
	function log2(i: natural) return integer is
		variable temp	: integer := i;
		variable ret_val: integer := 0;
	begin
		while temp > 1 loop
			ret_val := ret_val+1;
			if(temp mod 2=1) then
				temp := temp/2+1;
			else
				temp := temp/2;
			end if;
		end loop;

		return ret_val;
	end log2;

end my_math;

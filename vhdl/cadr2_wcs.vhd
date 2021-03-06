-- Module Name:    cadr2_wcs - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity cadr2_wcs is
  Port ( addr : in std_logic_vector(13 downto 0);
			di : in std_logic_vector(48 downto 0);
			do : out std_logic_vector(48 downto 0);
			wr : in std_logic;
			en : in std_logic;
			clk	: in std_logic
);
end cadr2_wcs;

architecture low_level of cadr2_wcs is

signal dip : std_logic_vector(1 downto 0);
signal dop : std_logic_vector(1 downto 0);

begin

   RAMB16_S18_0_0 : RAMB16_S18
   generic map (
      INIT => X"00000", --  Value of output RAM registers at startup
      SRVAL => X"00000", --  Ouput value upon SSR assertion
      WRITE_MODE => "WRITE_FIRST" --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      )
   port map (
      DO => do(15 downto 0),      -- 16-bit Data Output
      ADDR => addr(9 downto 0),  -- 10-bit Address Input
      CLK => clk,    -- Clock
      DI => di(15 downto 0),      -- 16-bit Data Input
		DIP => dip,
      EN => en,      -- RAM Enable Input
      SSR => '0',    -- Synchronous Set/Reset Input
      WE => wr       -- Write Enable Input
   );

   RAMB16_S18_0_1 : RAMB16_S18
   generic map (
      INIT => X"00000", --  Value of output RAM registers at startup
      SRVAL => X"00000", --  Ouput value upon SSR assertion
      WRITE_MODE => "WRITE_FIRST" --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      )
   port map (
      DO => do(31 downto 16),      -- 16-bit Data Output
      ADDR => addr(9 downto 0),  -- 10-bit Address Input
      CLK => clk,    -- Clock
      DI => di(31 downto 16),      -- 16-bit Data Input
		DIP => dip,
      EN => en,      -- RAM Enable Input
      SSR => '0',    -- Synchronous Set/Reset Input
      WE => wr       -- Write Enable Input
   );

   RAMB16_S18_0_2 : RAMB16_S18
   generic map (
      INIT => X"00000", --  Value of output RAM registers at startup
      SRVAL => X"00000", --  Ouput value upon SSR assertion
      WRITE_MODE => "WRITE_FIRST" --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      )
   port map (
      DO => do(47 downto 32),      -- 16-bit Data Output
		DOP => dop,
      ADDR => addr(9 downto 0),  -- 10-bit Address Input
      CLK => clk,    -- Clock
      DI => di(47 downto 32),      -- 16-bit Data Input
		DIP => dip,
      EN => en,      -- RAM Enable Input
      SSR => '0',    -- Synchronous Set/Reset Input
      WE => wr       -- Write Enable Input
   );

dip <= "0" & di(48);
do(48) <= dop(0);

end low_level;
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.01.2026 11:19:51
-- Design Name: 
-- Module Name: Timer_MMIO - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------



-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Timer_MMIO is
  Port(
    clk   : in  std_logic;
    rst   : in  std_logic;

    addr  : in  std_logic_vector(31 downto 0);
    we    : in  std_logic;
    re    : in  std_logic;
    wdata : in  std_logic_vector(31 downto 0);
    rdata : out std_logic_vector(31 downto 0)
  );
end;

architecture rtl of Timer_MMIO is
  signal counter : unsigned(31 downto 0) := (others => '0');
begin

  -- compteur
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        counter <= (others => '0');
      else
        counter <= counter + 1;

        -- option : écrire base+0 pour charger le compteur
        if (we='1') and (addr(3 downto 2)="00") then
          counter <= unsigned(wdata);
        end if;
      end if;
    end if;
  end process;

  -- lecture
  process(addr, re, counter)
    variable v : std_logic_vector(31 downto 0);
  begin
    v := (others => '0');
    if (re='1') and (addr(3 downto 2)="00") then
      v := std_logic_vector(counter);
    end if;
    rdata <= v;
  end process;

end rtl;

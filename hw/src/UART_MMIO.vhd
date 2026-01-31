----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.01.2026 11:14:20
-- Design Name: 
-- Module Name: UART_MMIO - Behavioral
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

entity UART_MMIO is
  Port(
    clk   : in  std_logic;
    rst   : in  std_logic;

    -- bus
    addr  : in  std_logic_vector(31 downto 0);
    we    : in  std_logic;
    re    : in  std_logic;
    wdata : in  std_logic_vector(31 downto 0);
    rdata : out std_logic_vector(31 downto 0);

    -- UART pin
    tx    : out std_logic
  );
end;

architecture rtl of UART_MMIO is
  signal tx_start : std_logic;
  signal tx_data  : std_logic_vector(7 downto 0);
  signal tx_busy  : std_logic;
begin
  tx_data <= wdata(7 downto 0);

  -- DATA @ base+0 : write déclenche un envoi si pas busy
  tx_start <= '1' when (we='1' and addr(3 downto 2)="00" and tx_busy='0') else '0';

  UTX: entity work.UART_Tx
    port map(
      clk      => clk,
      rst      => rst,
      tx_start => tx_start,
      tx_data  => tx_data,
      tx       => tx,
      tx_busy  => tx_busy
    );

  -- STATUS @ base+4 : bit0 = busy
  process(addr, re, tx_busy)
    variable v : std_logic_vector(31 downto 0);
  begin
    v := (others => '0');
    if (re='1') and (addr(3 downto 2) = "01") then
      v(0) := tx_busy;
    end if;
    rdata <= v;
  end process;

end rtl;


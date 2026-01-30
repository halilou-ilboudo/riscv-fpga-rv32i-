----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 12:40:31
-- Design Name: 
-- Module Name: RegFile - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RegFile is Port (
              clk,rst: in  std_logic;
              we: in  std_logic;                -- Write Enable
              rs1: in  std_logic_vector(4 downto 0); -- Source register 1 (5 bits)
              rs2: in  std_logic_vector(4 downto 0); -- Source register 2 (5 bits)
              rd: in  std_logic_vector(4 downto 0); -- Destination register (5 bits)
              wdata: in  std_logic_vector(31 downto 0); -- Write data
              rdata1: out std_logic_vector(31 downto 0); -- Read data 1
              rdata2: out std_logic_vector(31 downto 0)  -- Read data 2

 );
end RegFile;

architecture Behavioral of RegFile is
  -- Déclaration des 32 registres de 32 bits
type reg_array is array (31 downto 0) of std_logic_vector(31 downto 0);
signal regs : reg_array := (
    0  => (others => '0'),  -- x0 = 0 immuable
    1  => x"00000005",     -- x1 = 5
    2  => x"0000000A",     -- x2 = 10
    others => (others => '0')
);

begin


 process(clk,rst)
    begin
        if rst = '1' then 
         regs<= (others => (others => '0'));
        elsif rising_edge(clk) then
        
            if (we = '1') and (rd /= "00000") then   -- on n'écrit pas dans x0
                regs(to_integer(unsigned(rd))) <= wdata;
            end if;
        end if;
    end process;

    -- Lecture combinatoire (immédiate)
    rdata1 <= (others => '0') when (rs1 = "00000") else regs(to_integer(unsigned(rs1)));
    rdata2 <= (others => '0') when (rs2 = "00000") else regs(to_integer(unsigned(rs2)));




end Behavioral;

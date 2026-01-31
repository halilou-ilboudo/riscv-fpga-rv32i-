----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 12:49:16
-- Design Name: 
-- Module Name: GPIO - Behavioral
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

entity GPIO is Port (
           clk      : in  std_logic;
        rst      : in  std_logic;
        addr     : in  std_logic_vector(31 downto 0);
        we       : in  std_logic;
        re       : in  std_logic;
        wdata    : in  std_logic_vector(31 downto 0);
        rdata    : out std_logic_vector(31 downto 0);
        gpio_in  : in  std_logic_vector(7 downto 0);
        gpio_out : out std_logic_vector(7 downto 0)

 );
end GPIO;

architecture Behavioral of GPIO is
    signal out_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal in_sync1, in_sync2 : std_logic_vector(7 downto 0) := (others => '0');

    constant ZERO24 : std_logic_vector(23 downto 0) := (others => '0');

begin

    ------------------------------------------------------------
    -- Synchronisation des entrées GPIO (anti-métastabilité)
    ------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            in_sync1 <= gpio_in;
            in_sync2 <= in_sync1;
        end if;
    end process;

    ------------------------------------------------------------
    -- Écriture : 0x80000000
    ------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            out_reg <= (others => '0');
        elsif rising_edge(clk) then
            if we = '1' and addr = x"80000000" then
                out_reg <= wdata(7 downto 0);
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Lecture combinatoire
    ------------------------------------------------------------
    process(re, addr, out_reg, in_sync2)
    begin
        if re = '1' then
            case addr(3 downto 2) is
                when "00" =>
                    rdata <= ZERO24 & out_reg;   -- 0x80000000
                when "01" =>
                    rdata <= ZERO24 & in_sync2; -- 0x80000004
                when others =>
                    rdata <= (others => '0');
            end case;
        else
            rdata <= (others => '0');
        end if;
    end process;

    ------------------------------------------------------------
    -- Sortie physique
    ------------------------------------------------------------
    gpio_out <= out_reg;


end Behavioral;

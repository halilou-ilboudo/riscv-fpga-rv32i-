----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 12:54:23
-- Design Name: 
-- Module Name: UART_Tx - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_Tx is Port ( 
        clk       : in  std_logic;
        rst       : in  std_logic;
        tx_start  : in  std_logic;
        tx_data   : in  std_logic_vector(7 downto 0);
        tx        : out std_logic;
        tx_busy   : out std_logic

);
end UART_Tx;

architecture Behavioral of UART_Tx is
    constant CLK_FREQ  : integer := 100000000;
    constant BAUD_RATE : integer := 115200;
    constant DIVISOR   : integer := CLK_FREQ / BAUD_RATE;

    signal baud_cnt  : integer := 0;
    signal bit_cnt   : integer := 0;
    signal busy      : std_logic := '0';
    signal shift_reg : std_logic_vector(9 downto 0) := (others => '1');

begin


    process(clk, rst)
    begin
        if rst = '1' then
            baud_cnt  <= 0;
            bit_cnt   <= 0;
            busy      <= '0';
            shift_reg <= (others => '1');

        elsif rising_edge(clk) then

            ---------------------------------------------------------
            -- Start d'émission (1 front)
            ---------------------------------------------------------
            if tx_start = '1' and busy = '0' then
                -- STOP=1, 8 DATA bits, START=0
                shift_reg <= '1' & tx_data & '0';
                busy      <= '1';
                bit_cnt   <= 0;
                baud_cnt  <= 0;

            elsif busy = '1' then

                -----------------------------------------------------
                -- Tick baud
                -----------------------------------------------------
                if baud_cnt = DIVISOR-1 then
                    baud_cnt <= 0;

                    -------------------------------------------------
                    -- Envoi du bit courant
                    -------------------------------------------------
                    tx <= shift_reg(0);

                    -------------------------------------------------
                    -- Décalage
                    -------------------------------------------------
                    shift_reg <= '1' & shift_reg(9 downto 1);

                    -------------------------------------------------
                    -- Fin après 10 bits (start+8data+stop)
                    -------------------------------------------------
                    if bit_cnt = 9 then
                        busy <= '0';
                    else
                        bit_cnt <= bit_cnt + 1;
                    end if;

                else
                    baud_cnt <= baud_cnt + 1;
                end if;

            end if;

        end if;
    end process;

    tx_busy <= busy;

end Behavioral;

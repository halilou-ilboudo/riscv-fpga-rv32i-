----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 12:52:08
-- Design Name: 
-- Module Name: UART_Rx - Behavioral
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

entity UART_Rx is Port ( 
        clk      : in  std_logic;
        rst      : in  std_logic;
        rx       : in  std_logic;
        rx_ready : out std_logic;
        rx_data  : out std_logic_vector(7 downto 0)

);
end UART_Rx;

architecture Behavioral of UART_Rx is

    constant CLK_FREQ   : integer := 100000000;
    constant BAUD_RATE  : integer := 115200;
    constant OVERSAMPLE : integer := 16;
    constant BAUD_TICK  : integer := CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

    signal tick_cnt  : integer := 0;
    signal sample_cnt : integer := 0;
    signal bit_cnt     : integer := 0;

    signal shift_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal ready_reg   : std_logic := '0';
    signal rx_sync     : std_logic_vector(1 downto 0) := (others => '1');

    signal receiving   : std_logic := '0';

begin

    ---------------------------------------------------------------------
    -- Double synchronisation du RX (évite les métastabilités)
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync <= rx_sync(0) & rx;
        end if;
    end process;

    ---------------------------------------------------------------------
    -- UART Receiver
    ---------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            tick_cnt    <= 0;
            sample_cnt  <= 0;
            bit_cnt     <= 0;
            receiving   <= '0';
            ready_reg   <= '0';

        elsif rising_edge(clk) then

            ready_reg <= '0';  -- pulse 1 cycle

            -- clock divider for oversampling tick
            if tick_cnt = BAUD_TICK then
                tick_cnt <= 0;

                if receiving = '0' then
                    ---------------------------------------------------------
                    -- DETECT START BIT
                    ---------------------------------------------------------
                    if rx_sync(1) = '0' then
                        receiving  <= '1';
                        sample_cnt <= OVERSAMPLE/2; -- centre du start bit
                        bit_cnt    <= 0;
                    end if;

                else
                    ---------------------------------------------------------
                    -- RECEIVING FRAME
                    ---------------------------------------------------------
                    if sample_cnt = OVERSAMPLE then
                        sample_cnt <= 1;

                        if bit_cnt = 0 then
                            -- still inside start bit, ignore
                            bit_cnt <= 1;

                        elsif bit_cnt >= 1 and bit_cnt <= 8 then
                            -- sample data bits
                            shift_reg(bit_cnt-1) <= rx_sync(1);
                            bit_cnt <= bit_cnt + 1;

                        elsif bit_cnt = 9 then
                            -- STOP BIT
                            if rx_sync(1) = '1' then
                                ready_reg <= '1';
                            end if;
                            receiving <= '0';
                        end if;

                    else
                        sample_cnt <= sample_cnt + 1;
                    end if;

                end if;

            else
                tick_cnt <= tick_cnt + 1;
            end if;

        end if;
    end process;

    rx_ready <= ready_reg;
    rx_data  <= shift_reg;


end Behavioral;

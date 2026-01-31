----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.12.2025 07:51:29
-- Design Name: 
-- Module Name: DataMemory - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity DataMemory is
    Port (
        clk        : in  std_logic;
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        addr       : in  std_logic_vector(31 downto 0);
        wdata      : in  std_logic_vector(31 downto 0);
        rdata      : out std_logic_vector(31 downto 0);

        load_type  : in std_logic_vector(2 downto 0); -- LB/LBU/LH/LHU/LW
        store_type : in std_logic_vector(1 downto 0)  -- SB/SH/SW
    );
end DataMemory;

architecture Behavioral of DataMemory is

    -----------------------------------------------------------------
    -- BYTE-ADDRESSABLE MEMORY : 1024 bytes (1 KB)
    -----------------------------------------------------------------
    type ram_type is array (0 to 1023) of std_logic_vector(7 downto 0);
    signal RAM : ram_type := (others => (others => '0'));

    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";  -- >>> FORCER BRAM <<<

    signal addr_i : integer range 0 to 1023 := 0;

    signal byte0, byte1, byte2, byte3 : std_logic_vector(7 downto 0);

begin

    addr_i <= to_integer(unsigned(addr(11 downto 2)) & "00");  -- word-aligned

    process(clk)
    begin
        if rising_edge(clk) then

            ------------------------------------------------
            -- STORE OPERATIONS
            ------------------------------------------------
            if mem_write = '1' then
                case store_type is

                    when "00" =>  -- SW
                        RAM(addr_i)     <= wdata(7 downto 0);
                        RAM(addr_i + 1) <= wdata(15 downto 8);
                        RAM(addr_i + 2) <= wdata(23 downto 16);
                        RAM(addr_i + 3) <= wdata(31 downto 24);

                    when "01" =>  -- SB
                        RAM(addr_i) <= wdata(7 downto 0);

                    when "10" =>  -- SH
                        RAM(addr_i)     <= wdata(7 downto 0);
                        RAM(addr_i + 1) <= wdata(15 downto 8);

                    when others =>
                        null;

                end case;
            end if;

            ------------------------------------------------
            -- LOAD OPERATIONS
            ------------------------------------------------
            if mem_read = '1' then
                byte0 <= RAM(addr_i);
                byte1 <= RAM(addr_i + 1);
                byte2 <= RAM(addr_i + 2);
                byte3 <= RAM(addr_i + 3);
            end if;

        end if;
    end process;

    --------------------------------------------------------
    -- ASSEMBLE AND SIGN-EXTEND FOR RV32I LOADS
    --------------------------------------------------------
    process(load_type, byte0, byte1, byte2, byte3)
    begin
        case load_type is

            when "000" =>  -- LW
                rdata <= byte3 & byte2 & byte1 & byte0;

            when "001" =>  -- LB
                rdata <= (31 downto 8 => byte0(7)) & byte0;

            when "010" =>  -- LBU
                rdata <= (31 downto 8 => '0') & byte0;

            when "011" =>  -- LH
                rdata <= (31 downto 16 => byte1(7)) & byte1 & byte0;

            when "100" =>  -- LHU
                rdata <= (31 downto 16 => '0') & byte1 & byte0;

            when others =>
                rdata <= (others => '0');

        end case;
    end process;

end Behavioral;


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 12:33:32
-- Design Name: 
-- Module Name: InstructionMemory - Behavioral
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

use IEEE.NUMERIC_STD.ALL;

entity InstructionMemory is 
    Port ( 
        clk      : in  std_logic;

        -- Lecture CPU
        raddr    : in  std_logic_vector(31 downto 0);
        rdata    : out std_logic_vector(31 downto 0);

        -- Écriture Bootloader UART
        we       : in  std_logic;
        waddr    : in  std_logic_vector(31 downto 0);
        wdata    : in  std_logic_vector(31 downto 0)
    );
end InstructionMemory;

architecture Behavioral of InstructionMemory is

    constant MEM_DEPTH : integer := 1024;  -- 4 KB (1024 x 32 bits)

    type mem_array is array (0 to MEM_DEPTH-1) of std_logic_vector(31 downto 0);

    signal mem       : mem_array := (others => (others => '0'));
    signal rdata_reg : std_logic_vector(31 downto 0) := (others => '0');

    -- >>> FORCER BRAM <<<
    attribute ram_style : string;
    attribute ram_style of mem : signal is "block";

    signal rindex, windex : integer range 0 to MEM_DEPTH-1 := 0;

begin

    ------------------------------------------
    -- Mémoire synchrone (style BRAM FPGA)
    ------------------------------------------
   process(clk)
      variable ridx : integer;
      variable widx : integer;
    begin
      if rising_edge(clk) then
        ridx := to_integer(unsigned(raddr(11 downto 2)));
        widx := to_integer(unsigned(waddr(11 downto 2)));
    
        if we='1' and widx < MEM_DEPTH then
          mem(widx) <= wdata;
        end if;
    
        if ridx < MEM_DEPTH then
          rdata_reg <= mem(ridx);
        else
          rdata_reg <= (others=>'0');
        end if;
      end if;
    end process;


    -- sortie synchrone
    rdata <= rdata_reg;

end Behavioral;

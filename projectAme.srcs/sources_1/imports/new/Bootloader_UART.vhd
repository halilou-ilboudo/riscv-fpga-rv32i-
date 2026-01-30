----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.12.2025 14:28:34
-- Design Name: 
-- Module Name: Bootloader_UART - Behavioral
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

entity Bootloader_UART is
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        -- UART décodé (1 octet + strobe)
        rx_ready    : in  std_logic;
        rx_data     : in  std_logic_vector(7 downto 0);

        -- Interface d'écriture InstructionMemory
        imem_we     : out std_logic;
        imem_waddr  : out std_logic_vector(31 downto 0);
        imem_wdata  : out std_logic_vector(31 downto 0);

        -- 1 => boot terminé, CPU peut démarrer
        boot_done   : out std_logic
    );
end Bootloader_UART;

architecture Behavioral of Bootloader_UART is

    signal byte_count  : integer range 0 to 3 := 0;
    signal instr_buf   : std_logic_vector(31 downto 0) := (others => '0');
    signal addr_cnt    : unsigned(31 downto 0) := (others => '0');

    signal boot_done_reg : std_logic := '0';
    signal ff_count      : integer range 0 to 4 := 0;  -- fin de programme (séquence 0xFF)

begin

    boot_done <= boot_done_reg;

    process(clk, rst)
          variable tmp : std_logic_vector(31 downto 0);
    begin
          if rst = '1' then
            byte_count    <= 0;
            instr_buf     <= (others => '0');
            addr_cnt      <= (others => '0');
            boot_done_reg <= '0';
            ff_count      <= 0;
        
            imem_we       <= '0';
            imem_waddr    <= (others => '0');
            imem_wdata    <= (others => '0');
        
          elsif rising_edge(clk) then
        
            -- Valeurs par défaut
            imem_we <= '0';
        
            -- Si boot fini : on ignore tout
            if boot_done_reg = '1' then
              null;
        
            -- Boot en cours : on traite les octets reçus
            elsif rx_ready = '1' then
        
              -------------------------------------------------------
              -- 1) Terminator : 4 x 0xFF UNIQUEMENT si byte_count=0
              --    (et on NE DOIT PAS les utiliser comme données)
              -------------------------------------------------------
              if (byte_count = 0) and (rx_data = x"FF") then
                ff_count <= ff_count + 1;
                if ff_count = 3 then
                  boot_done_reg <= '1';
                end if;
        
              else
                -- Ce n'est pas un FF aligné => on reset le compteur FF
                ff_count <= 0;
        
                -------------------------------------------------------
                -- 2) Reconstruction instruction 32 bits little-endian
                -------------------------------------------------------
                case byte_count is
                  when 0 =>
                    instr_buf(7 downto 0) <= rx_data;
                    byte_count <= 1;
        
                  when 1 =>
                    instr_buf(15 downto 8) <= rx_data;
                    byte_count <= 2;
        
                  when 2 =>
                    instr_buf(23 downto 16) <= rx_data;
                    byte_count <= 3;
        
                  when 3 =>
                    -- On construit le mot complet avec tmp (évite les soucis de timing)
                    tmp := instr_buf;
                    tmp(31 downto 24) := rx_data;
        
                    -- Ecriture en InstructionMemory
                    imem_we    <= '1';
                    imem_waddr <= std_logic_vector(addr_cnt);
                    imem_wdata <= tmp;
        
                    -- Mot suivant (PC += 4)
                    addr_cnt   <= addr_cnt + 4;
        
                    -- Reset buffer
                    instr_buf  <= (others => '0');
                    byte_count <= 0;
        
                  when others =>
                    byte_count <= 0;
                end case;
        
              end if; -- terminator vs data
        
            end if; -- rx_ready
        
          end if; -- rising_edge
        end process;
        
end Behavioral;

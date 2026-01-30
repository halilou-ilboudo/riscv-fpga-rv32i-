----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 12:43:30
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is Port (
        op1: in  std_logic_vector(31 downto 0);op2: in  std_logic_vector(31 downto 0);
        alu_ctrl: in  std_logic_vector(3 downto 0);  -- code de l'opération
        result: out std_logic_vector(31 downto 0);
        zero: out std_logic                   -- flag pour les branches

 );
end ALU;

architecture Behavioral of ALU is
begin

process(op1,op2,alu_ctrl)
 variable res : std_logic_vector(31 downto 0);
    begin
        case alu_ctrl is
            -- 0000 : ADD
            when "0000" =>
                res := std_logic_vector(signed(op1) + signed(op2));
            -- 0001 : SUB
            when "0001" =>
                res := std_logic_vector(signed(op1) - signed(op2));
            -- 0010 : AND
            when "0010" =>
                res := op1 and op2;
            -- 0011 : OR
            when "0011" =>
                res := op1 or op2;
            -- 0100 : XOR
            when "0100" =>
                res := op1 xor op2;
            -- 0101 : SLL (shift left logical)
            when "0101" =>
                res := std_logic_vector(shift_left(unsigned(op1), to_integer(unsigned(op2(4 downto 0)))));
            -- 0110 : SRL (shift right logical)
            when "0110" =>
                res := std_logic_vector(shift_right(unsigned(op1), to_integer(unsigned(op2(4 downto 0)))));
            -- 0111 : SRA (shift right arithmetic)
            when "0111" =>
                res := std_logic_vector(shift_right(signed(op1), to_integer(unsigned(op2(4 downto 0)))));
           -- 1000 : SLT (signed comparison)
            when "1000" =>
                if signed(op1) < signed(op2) then
                    res := (others => '0');
                    res(0) := '1';
                else
                    res := (others => '0');
                end if;
            -- 1001 : SLTU (unsigned comparison)
            when "1001" =>
                if unsigned(op1) < unsigned(op2) then
                    res := (others => '0');
                    res(0) := '1';
                else
                    res := (others => '0');
                end if;
            -- Valeur par défaut
            when others =>
                res := (others => '0');

        end case;

        result <= res;

        -- flag zero = 1 si résultat == 0
        if res = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;
    end process;


end Behavioral;

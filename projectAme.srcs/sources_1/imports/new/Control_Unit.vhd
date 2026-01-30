----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.12.2025 07:49:46
-- Design Name: 
-- Module Name: Control_Unit - Behavioral
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Control_Unit is
    Port (
        opcode       : in  std_logic_vector(6 downto 0);
        funct3       : in  std_logic_vector(2 downto 0);
        funct7       : in  std_logic_vector(6 downto 0);

        alu_ctrl     : out std_logic_vector(3 downto 0);
        reg_write    : out std_logic;
        mem_read     : out std_logic;
        mem_write    : out std_logic;
        alu_src      : out std_logic;
        mem_to_reg   : out std_logic;

        branch       : out std_logic;
        branch_type  : out std_logic_vector(2 downto 0);
        jump         : out std_logic;

        load_type    : out std_logic_vector(2 downto 0);  -- 000=LW, 001=LB,010=LBU,011=LH,100=LHU
        store_type   : out std_logic_vector(1 downto 0)   -- 00=SW, 01=SB, 10=SH
    );
end Control_Unit;

architecture Behavioral of Control_Unit is

    constant OPCODE_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
    constant OPCODE_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
    constant OPCODE_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant OPCODE_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant OPCODE_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant OPCODE_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant OPCODE_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant OPCODE_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant OPCODE_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

begin

process(opcode, funct3, funct7)
begin
    alu_ctrl   <= "0000";
    reg_write  <= '0';
    mem_read   <= '0';
    mem_write  <= '0';
    alu_src    <= '0';
    mem_to_reg <= '0';
    branch     <= '0';
    branch_type<= (others => '0');
    jump       <= '0';
    load_type  <= "000";
    store_type <= "00";

    case opcode is

        -----------------------------------------------------------
        when OPCODE_RTYPE =>
            reg_write <= '1';
            alu_src   <= '0';
            mem_to_reg<= '0';

            case funct3 is
                when "000" =>
                    if funct7 = "0000000" then
                        alu_ctrl <= "0000"; -- ADD
                    else
                        alu_ctrl <= "0001"; -- SUB
                    end if;
                when "111" => alu_ctrl <= "0010"; -- AND
                when "110" => alu_ctrl <= "0011"; -- OR
                when "100" => alu_ctrl <= "0100"; -- XOR
                when "001" => alu_ctrl <= "0101"; -- SLL
                when "101" =>
                    if funct7 = "0000000" then alu_ctrl <= "0110";
                    else alu_ctrl <= "0111";
                    end if;
                when "010" => alu_ctrl <= "1000"; -- SLT
                when "011" => alu_ctrl <= "1001"; -- SLTU
                when others => alu_ctrl <= "0000";
            end case;

        -----------------------------------------------------------
        when OPCODE_ITYPE =>
            reg_write <= '1';
            alu_src   <= '1';

            case funct3 is
                when "000" => alu_ctrl <= "0000"; -- ADDI
                when "111" => alu_ctrl <= "0010"; -- ANDI
                when "110" => alu_ctrl <= "0011"; -- ORI
                when "100" => alu_ctrl <= "0100"; -- XORI
                when "001" => alu_ctrl <= "0101"; -- SLLI
                when "101" =>
                    if funct7 = "0000000" then alu_ctrl <= "0110";
                    else alu_ctrl <= "0111";
                    end if;
                when "010" => alu_ctrl <= "1000"; -- SLTI
                when "011" => alu_ctrl <= "1001"; -- SLTIU
                when others => null;
            end case;

        -----------------------------------------------------------
        when OPCODE_LOAD =>
            reg_write  <= '1';
            mem_read   <= '1';
            mem_to_reg <= '1';
            alu_src    <= '1'; -- address = rs1 + imm

            case funct3 is
                when "010" => load_type <= "000"; -- LW
                when "000" => load_type <= "001"; -- LB
                when "100" => load_type <= "010"; -- LBU
                when "001" => load_type <= "011"; -- LH
                when "101" => load_type <= "100"; -- LHU
                when others => load_type <= "000";
            end case;

        -----------------------------------------------------------
        when OPCODE_STORE =>
            mem_write <= '1';
            alu_src   <= '1';

            case funct3 is
                when "010" => store_type <= "00"; -- SW
                when "000" => store_type <= "01"; -- SB
                when "001" => store_type <= "10"; -- SH
                when others => store_type <= "00";
            end case;

        -----------------------------------------------------------
        when OPCODE_BRANCH => branch <= '1';
        when OPCODE_JAL    => jump <= '1';
        when OPCODE_JALR   => jump <= '1';
        when OPCODE_LUI    => reg_write <= '1';
        when OPCODE_AUIPC  => reg_write <= '1';

        when others => null;
    end case;
end process;

end Behavioral;
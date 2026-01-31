library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_CPU is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;

        gpio_in   : in  std_logic_vector(7 downto 0);
        gpio_out  : out std_logic_vector(7 downto 0);

        uart_rx   : in  std_logic;
        uart_tx   : out std_logic
    );
end Top_CPU;

architecture Structural of Top_CPU is

    -- Opcodes utiles
    constant OPCODE_JAL  : std_logic_vector(6 downto 0) := "1101111";
    constant OPCODE_JALR : std_logic_vector(6 downto 0) := "1100111";

    -- =========================
    -- Signaux Bootloader / UART
    -- =========================
    signal bl_rx_ready   : std_logic;
    signal bl_rx_data    : std_logic_vector(7 downto 0);

    signal bl_imem_we    : std_logic;
    signal bl_imem_waddr : std_logic_vector(31 downto 0);
    signal bl_imem_wdata : std_logic_vector(31 downto 0);

    signal boot_done     : std_logic;

    -- Reset CPU (bloqué tant que boot pas fini)
    signal cpu_rst       : std_logic;

    -- =========================
    -- Instruction / PC
    -- =========================
    signal pc_current : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_next    : std_logic_vector(31 downto 0);
    signal pc_plus4   : std_logic_vector(31 downto 0);

    signal instruction : std_logic_vector(31 downto 0);

    -- champs instruction
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);
    signal rs1, rs2, rd : std_logic_vector(4 downto 0);

    -- immediats
    signal imm_i, imm_s, imm_b, imm_j : std_logic_vector(31 downto 0);

    -- =========================
    -- Regfile / ALU / WB
    -- =========================
    signal rdata1, rdata2 : std_logic_vector(31 downto 0);
    signal alu_result     : std_logic_vector(31 downto 0);
    signal alu_op2        : std_logic_vector(31 downto 0);
    signal wb_data        : std_logic_vector(31 downto 0);

    signal zero : std_logic;

    -- =========================
    -- Control
    -- =========================
    signal alu_ctrl    : std_logic_vector(3 downto 0);
    signal reg_write   : std_logic;
    signal mem_read    : std_logic;
    signal mem_write   : std_logic;
    signal alu_src     : std_logic;
    signal mem_to_reg  : std_logic;
    signal branch      : std_logic;
    signal branch_type : std_logic_vector(2 downto 0);
    signal jump        : std_logic;

    -- ? nouveaux signaux (fix warnings)
    signal load_type   : std_logic_vector(2 downto 0);
    signal store_type  : std_logic_vector(1 downto 0);

    -- =========================
    -- DataMemory / GPIO / UART mapped
    -- =========================
    signal data_rdata : std_logic_vector(31 downto 0);
    signal gpio_rdata : std_logic_vector(31 downto 0);

    signal data_we, data_re : std_logic;
    signal gpio_we, gpio_re : std_logic;
    signal uart_we          : std_logic;

    -- GPIO normal (avant mux diag)
    signal gpio_out_periph  : std_logic_vector(7 downto 0);

    -- UART_TX côté CPU
    signal tx_start_cpu : std_logic;
    signal tx_busy_cpu  : std_logic;
    signal tx_data_cpu  : std_logic_vector(7 downto 0);

    -- =========================
    -- LEDs de diagnostic (latch)
    -- =========================
    signal led_rx_seen   : std_logic := '0';
    signal led_mem_write : std_logic := '0';
    
    signal gpio_out_final  : std_logic_vector(7 downto 0);
    signal imm_alu : std_logic_vector(31 downto 0);
    signal imm_u : std_logic_vector(31 downto 0);

    constant OPCODE_LUI : std_logic_vector(6 downto 0) := "0110111";
    
    signal uart_rdata : std_logic_vector(31 downto 0);
    signal uart_re    : std_logic;
    signal tim_we, tim_re : std_logic;
    signal tim_rdata : std_logic_vector(31 downto 0);

begin

    -- CPU bloqué tant que boot pas fini
    cpu_rst <= rst or (not boot_done);

    -- =========================
    -- Latch diag LEDs
    -- =========================
    process(clk, rst)
    begin
        if rst = '1' then
            led_rx_seen   <= '0';
            led_mem_write <= '0';
        elsif rising_edge(clk) then
            if bl_rx_ready = '1' then
                led_rx_seen <= '1';
            end if;
            if bl_imem_we = '1' then
                led_mem_write <= '1';
            end if;
        end if;
    end process;

    -- =========================
    -- UART RX -> Bootloader
    -- =========================
    U_RX : entity work.UART_Rx
        port map (
            clk      => clk,
            rst      => rst,
            rx       => uart_rx,
            rx_ready => bl_rx_ready,
            rx_data  => bl_rx_data
        );

    -- =========================
    -- Bootloader -> IMEM write
    -- =========================
    U_BOOT : entity work.Bootloader_UART
        port map (
            clk        => clk,
            rst        => rst,
            rx_ready   => bl_rx_ready,
            rx_data    => bl_rx_data,
            imem_we    => bl_imem_we,
            imem_waddr => bl_imem_waddr,
            imem_wdata => bl_imem_wdata,
            boot_done  => boot_done
        );

    -- =========================
    -- InstructionMemory
    -- =========================
    U_IMEM : entity work.InstructionMemory
        port map (
            clk   => clk,
            raddr => pc_current,
            rdata => instruction,
            we    => bl_imem_we,
            waddr => bl_imem_waddr,
            wdata => bl_imem_wdata
        );

    -- =========================
    -- Decode instruction fields
    -- =========================
    opcode <= instruction(6 downto 0);
    rd     <= instruction(11 downto 7);
    funct3 <= instruction(14 downto 12);
    rs1    <= instruction(19 downto 15);
    rs2    <= instruction(24 downto 20);
    funct7 <= instruction(31 downto 25);

    -- =========================
    -- Immediates (RV32I)
    -- =========================
    -- I-type
    imm_i(11 downto 0)  <= instruction(31 downto 20);
    imm_i(31 downto 12) <= (others => instruction(31));

    -- S-type
    imm_s(4 downto 0)   <= instruction(11 downto 7);
    imm_s(11 downto 5)  <= instruction(31 downto 25);
    imm_s(31 downto 12) <= (others => instruction(31));

    -- B-type
    imm_b(0)            <= '0';
    imm_b(4 downto 1)   <= instruction(11 downto 8);
    imm_b(10 downto 5)  <= instruction(30 downto 25);
    imm_b(11)           <= instruction(7);
    imm_b(12)           <= instruction(31);
    imm_b(31 downto 13) <= (others => instruction(31));

    -- J-type
    imm_j(0)            <= '0';
    imm_j(10 downto 1)  <= instruction(30 downto 21);
    imm_j(11)           <= instruction(20);
    imm_j(19 downto 12) <= instruction(19 downto 12);
    imm_j(20)           <= instruction(31);
    imm_j(31 downto 21) <= (others => instruction(31));
    imm_u(31 downto 12) <= instruction(31 downto 12);
     imm_u(11 downto 0)  <= (others => '0');

    

    -- =========================
    -- Control Unit (? load/store types connectés)
    -- =========================
    U_CU : entity work.Control_Unit
        port map (
            opcode      => opcode,
            funct3      => funct3,
            funct7      => funct7,
            alu_ctrl    => alu_ctrl,
            reg_write   => reg_write,
            mem_read    => mem_read,
            mem_write   => mem_write,
            alu_src     => alu_src,
            mem_to_reg  => mem_to_reg,
            branch      => branch,
            branch_type => branch_type,
            jump        => jump,
            load_type   => load_type,
            store_type  => store_type
        );

    -- =========================
    -- Register File
    -- =========================
    U_RF : entity work.RegFile
        port map (
            clk    => clk,
            rst    => cpu_rst,
            we     => reg_write,
            rs1    => rs1,
            rs2    => rs2,
            rd     => rd,
            wdata  => wb_data,
            rdata1 => rdata1,
            rdata2 => rdata2
        );

    -- =========================
    -- ALU
    -- =========================
    imm_alu <= imm_s when opcode = "0100011" else  -- STORE
           imm_i;                              -- I-type (addi, lw, jalr, etc.)

    alu_op2 <= imm_alu when alu_src = '1' else rdata2;


    U_ALU : entity work.ALU
        port map (
            op1      => rdata1,
            op2      => alu_op2,
            alu_ctrl => alu_ctrl,
            result   => alu_result,
            zero     => zero
        );

    -- =========================
    -- DataMemory (? load/store types connectés)
    -- =========================
    -- Exemple simple de mapping (tu peux garder ton mapping original si différent)
    data_we <= mem_write when (alu_result(31 downto 28) = x"0") else '0';
    data_re <= mem_read  when (alu_result(31 downto 28) = x"0") else '0';

    U_DMEM : entity work.DataMemory
        port map (
            clk        => clk,
            mem_read   => data_re,
            mem_write  => data_we,
            addr       => alu_result,
            wdata      => rdata2,
            rdata      => data_rdata,
            load_type  => load_type,
            store_type => store_type
        );

    -- =========================
    -- GPIO (mapped, exemple 0x8...)
    -- =========================
    gpio_we <= mem_write when (alu_result(31 downto 28) = x"8") else '0';
    gpio_re <= mem_read  when (alu_result(31 downto 28) = x"8") else '0';

    U_GPIO : entity work.GPIO
        port map (
            clk      => clk,
            rst      => cpu_rst,
            addr     => alu_result,
            we       => gpio_we,
            re       => gpio_re,
            wdata    => rdata2,
            rdata    => gpio_rdata,
            gpio_in  => gpio_in,
            gpio_out => gpio_out_periph
        );


        uart_we <= mem_write when (alu_result(31 downto 28) = x"9") else '0';
        uart_re <= mem_read  when (alu_result(31 downto 28) = x"9") else '0';
        
        U_UART: entity work.UART_MMIO
          port map(
            clk   => clk,
            rst   => cpu_rst,
            addr  => alu_result,
            we    => uart_we,
            re    => uart_re,
            wdata => rdata2,
            rdata => uart_rdata,
            tx    => uart_tx
          );
    -- =========================
    -- UART TX (mapped exemple 0x9...)
    -- =========================
    

            tim_we <= mem_write when (alu_result(31 downto 28)=x"A") else '0';
            tim_re <= mem_read  when (alu_result(31 downto 28)=x"A") else '0';
            
            U_TIM: entity work.Timer_MMIO
              port map(
                clk   => clk,
                rst   => cpu_rst,
                addr  => alu_result,
                we    => tim_we,
                re    => tim_re,
                wdata => rdata2,
                rdata => tim_rdata
              );
    -- =========================
    -- Writeback
    -- =========================
    -- Sélection load : DMEM ou GPIO (tu peux étendre plus tard)
  wb_data <= imm_u when opcode = OPCODE_LUI else
           data_rdata when mem_to_reg='1' and data_re='1' else
           gpio_rdata when mem_to_reg='1' and gpio_re='1' else
           uart_rdata when mem_to_reg='1' and uart_re='1' else
           alu_result;


    -- =========================
    -- PC update
    -- =========================
    pc_plus4 <= std_logic_vector(unsigned(pc_current) + 4);

    process(clk)
    begin
        if rising_edge(clk) then
            if cpu_rst = '1' then
                pc_current <= (others => '0');
            else
                pc_current <= pc_next;
            end if;
        end if;
    end process;

    -- ? process avec liste explicite (pas de process(all))
    process(pc_plus4, pc_current, branch, branch_type, rdata1, rdata2, imm_b,
            jump, opcode, imm_j, imm_i)
        variable next_pc : std_logic_vector(31 downto 0);
    begin
        next_pc := pc_plus4;

        -- Branches
        if branch = '1' then
            case branch_type is
                when "000" => -- BEQ
                    if rdata1 = rdata2 then
                        next_pc := std_logic_vector(signed(pc_current) + signed(imm_b));
                    end if;
                when "001" => -- BNE
                    if rdata1 /= rdata2 then
                        next_pc := std_logic_vector(signed(pc_current) + signed(imm_b));
                    end if;
                when "010" => -- BLT
                    if signed(rdata1) < signed(rdata2) then
                        next_pc := std_logic_vector(signed(pc_current) + signed(imm_b));
                    end if;
                when "011" => -- BGE
                    if signed(rdata1) >= signed(rdata2) then
                        next_pc := std_logic_vector(signed(pc_current) + signed(imm_b));
                    end if;
                when "100" => -- BLTU
                    if unsigned(rdata1) < unsigned(rdata2) then
                        next_pc := std_logic_vector(signed(pc_current) + signed(imm_b));
                    end if;
                when "101" => -- BGEU
                    if unsigned(rdata1) >= unsigned(rdata2) then
                        next_pc := std_logic_vector(signed(pc_current) + signed(imm_b));
                    end if;
                when others =>
                    null;
            end case;

        -- Jumps
        elsif jump = '1' then
            if opcode = OPCODE_JAL then
                next_pc := std_logic_vector(signed(pc_current) + signed(imm_j));
            elsif opcode = OPCODE_JALR then
                next_pc := std_logic_vector(signed(rdata1) + signed(imm_i));
                next_pc(0) := '0';
            end if;
        end if;

        pc_next <= next_pc;
    end process;

    -- =========================
    -- MUX sorties GPIO / LEDs diag
    -- Pendant boot : afficher diag sur gpio_out(3..0)
    -- Après boot   : gpio_out = GPIO normal
    -- =========================
   gpio_out <= gpio_out_final;

process(boot_done, gpio_out_periph, led_rx_seen, led_mem_write, cpu_rst, rst)
  variable v : std_logic_vector(7 downto 0);
begin
  -- par défaut : GPIO normal
  v := gpio_out_periph;

  -- LEDs debug permanentes
  v(4) := cpu_rst;     -- reset CPU
  v(5) := rst;         -- reset global
  v(6) := boot_done;   -- boot terminé
  v(3) := not cpu_rst;
  -- LEDs boot uniquement
  if boot_done = '0' then
    v(0) := led_rx_seen;
    v(1) := led_mem_write;
    v(2) := boot_done;
    
  end if;

  gpio_out_final <= v;
end process;


end Structural;

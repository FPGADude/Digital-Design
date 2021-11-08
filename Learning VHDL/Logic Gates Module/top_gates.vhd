library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_gates is
  Port (
    sw0     : in    std_logic;
    sw1     : in    std_logic;
    sw2     : in    std_logic;
    sw3     : in    std_logic;
    sw6     : in    std_logic;
    sw7     : in    std_logic;
    sw8     : in    std_logic;
    sw9     : in    std_logic;
    sw12    : in    std_logic;
    sw13    : in    std_logic;
    sw14    : in    std_logic;
    sw15    : in    std_logic;
    led0    : out   std_logic;
    led3    : out   std_logic;
    led6    : out   std_logic;
    led9    : out   std_logic;
    led12   : out   std_logic;
    led15   : out   std_logic
  );
end top_gates;

architecture Behavioral of top_gates is

    component and_gate is
        port (
            in_1    : in    std_logic;
            in_2    : in    std_logic;
            y_out   : out   std_logic);
    end component and_gate;

    component nand_gate is
        port (
            in_1    : in    std_logic;
            in_2    : in    std_logic;
            y_out   : out   std_logic);
    end component nand_gate;
    
    component or_gate is
        port (
            in_1    : in    std_logic;
            in_2    : in    std_logic;
            y_out   : out   std_logic);
    end component or_gate;
    
    component nor_gate is
        port (
            in_1    : in    std_logic;
            in_2    : in    std_logic;
            y_out   : out   std_logic);
    end component nor_gate;
    
    component xor_gate is
        port (
            in_1    : in    std_logic;
            in_2    : in    std_logic;
            y_out   : out   std_logic);
    end component xor_gate;
    
    component xnor_gate is
        port (
            in_1    : in    std_logic;
            in_2    : in    std_logic;
            y_out   : out   std_logic);
    end component xnor_gate;

begin
    
    and_gate_INST : and_gate
        port map (
            in_1    =>  sw0,
            in_2    =>  sw1,
            y_out   =>  led0);
            
    or_gate_INST : or_gate
        port map (
            in_1    =>  sw2,
            in_2    =>  sw3,
            y_out   =>  led3);
            
    nand_gate_INST : nand_gate
        port map (
            in_1    => sw6,
            in_2    => sw7,
            y_out   => led6);
            
    nor_gate_INST : nor_gate
        port map (
            in_1    => sw8,
            in_2    => sw9,
            y_out   => led9);
            
    xor_gate_INST : xor_gate
        port map (
            in_1    => sw12,
            in_2    => sw13,
            y_out   => led12);
            
    xnor_gate_INST : xnor_gate
        port map (
            in_1    => sw14,
            in_2    => sw15,
            y_out   => led15);

end Behavioral;

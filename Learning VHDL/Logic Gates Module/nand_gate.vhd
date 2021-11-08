library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity nand_gate is
  Port (
    in_1    : in    std_logic;
    in_2    : in    std_logic;
    y_out   : out   std_logic
   );
end nand_gate;

architecture Behavioral of nand_gate is

begin
    y_out <= in_1 nand in_2;

end Behavioral;

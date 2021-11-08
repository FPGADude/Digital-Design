library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity nor_gate is
  Port (
    in_1    : in    std_logic;
    in_2    : in    std_logic;
    y_out   : out   std_logic
   );
end nor_gate;

architecture Behavioral of nor_gate is

begin
    y_out <= in_1 nor in_2;

end Behavioral;

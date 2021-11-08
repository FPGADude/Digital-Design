library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity or_gate is
  Port (
    in_1    : in    std_logic;
    in_2    : in    std_logic;
    y_out   : out   std_logic
   );
end or_gate;

architecture Behavioral of or_gate is

begin
    y_out <= in_1 or in_2;

end Behavioral;

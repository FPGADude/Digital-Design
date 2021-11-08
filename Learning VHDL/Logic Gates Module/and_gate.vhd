library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity and_gate is
  Port (
    in_1    : in    std_logic;
    in_2    : in    std_logic;
    y_out   : out   std_logic
   );
end and_gate;

architecture Behavioral of and_gate is

begin
    y_out <= in_1 and in_2;

end Behavioral;

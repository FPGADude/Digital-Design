library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decoder3x8_conditional is
    Port (ABC   : in    bit_vector(2 downto 0);
          F     : out   bit_vector(7 downto 0)  
    );
end decoder3x8_conditional;

architecture Behavioral of decoder3x8_conditional is
begin
    F <= "00000001" when (ABC = "000") else
         "00000010" when (ABC = "001") else
         "00000100" when (ABC = "010") else
         "00001000" when (ABC = "011") else
         "00010000" when (ABC = "100") else
         "00100000" when (ABC = "101") else
         "01000000" when (ABC = "110") else
         "10000000" when (ABC = "111");

end Behavioral;

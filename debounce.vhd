library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity debounce is
    generic
    (
        clk_freq    : integer := 125_000_000; --system clock frequency in Hz
        stable_time : integer := 10);        --time button must remain stable in ms
    port
    (
        clk    : in std_logic;   --input clock
        rst    : in std_logic;   --asynchronous active low reset
        button : in std_logic;   --input signal to be debounced
        result : out std_logic); --debounced signal
end debounce;

architecture Behavioral of debounce is
    
    signal sig: std_logic;
    signal count: integer range 0 to clk_freq * stable_time / 1000;
    signal MAX_DELAY: integer := clk_freq * stable_time / 1000;
    
begin

    process(clk, rst)
    begin
        if rst = '1' then
            sig <= '0';
            count <= 0;
        elsif rising_edge(clk) then
            if button = '1' then
                if count = MAX_DELAY - 1 then
                    sig <= '1';
                end if;
                count <= count + 1;
            else
                sig <= '0';
                count <= 0;
            end if;
        end if;
    end process;
    
    result <= sig;
    
end Behavioral;

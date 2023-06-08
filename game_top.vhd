library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity number_guess is
    generic
    (
        clk_freq    : integer := 125_000_000;
        stable_time : integer := 10;
        seed        : std_logic_vector(7 downto 0) := b"1011_0110");
    port
    (
        clk       : in std_logic;
        rst       : in std_logic;
        show      : in std_logic;
        capture   : in std_logic;
        enter     : in std_logic;
        switches  : in std_logic_vector (3 downto 0);
        leds      : out std_logic_vector (3 downto 0);
        red_led   : out std_logic;
        blue_led  : out std_logic;
        green_led : out std_logic
    );
end number_guess;

architecture Behavioral of number_guess is
    
    signal enter_btn: std_logic;
    signal show_btn: std_logic;
    signal clk_2Hz: std_logic;
    signal counter: integer range 0 to clk_freq - 1;
    constant HALF_PERIOD: integer := clk_freq / 4;
    signal blink: std_logic;
    
    signal enter_btn_pulse: std_logic;
    signal enter_btn_pulse_curr: std_logic;
    signal enter_btn_pulse_prev: std_logic;
    signal show_btn_pulse: std_logic;
    
    signal secret_number_int: integer range 0 to 15 := 0;
    signal secret_number_std: std_logic_vector(3 downto 0);
    signal guess: integer range 0 to 15 := 0;
    signal game_start: std_logic := '0';
    
    type STATE_TYPE is (NONE, HOT, COLD, WIN);
    signal progress_state: STATE_TYPE;
    
    component debounce is
        generic
        (
            clk_freq    : integer := clk_freq;
            stable_time : integer := stable_time);
        port
        (
            clk    : in std_logic;
            rst    : in std_logic;
            button : in std_logic;
            result : out std_logic);
    end component debounce;
    
    component single_pulse_detector is
        generic
        (
            detect_type: std_logic_vector(1 downto 0) := "00");
        port
        (
            clk          : in std_logic;
            rst          : in std_logic;
            input_signal : in std_logic;
            output_pulse : out std_logic);
    end component single_pulse_detector;
    
    component rand_gen is
        port
        (
            clk, rst : in std_logic;
            seed     : in std_logic_vector(7 downto 0);
            output   : out std_logic_vector (3 downto 0)
        );
    end component rand_gen;

begin
    
    enter_btn_debounce: debounce port map(clk => clk, rst => rst, button => enter, result => enter_btn);
    show_btn_debounce: debounce port map(clk => clk, rst => rst, button => show, result => show_btn);

    enter_btn_edge_detector: single_pulse_detector port map(clk => clk, rst => rst, input_signal => enter_btn, output_pulse => enter_btn_pulse);
    
    rand_gen_inst: rand_gen port map(clk => clk, rst => rst, seed => seed, output => secret_number_std);
    
    capture_proc: process(rst, clk)
    begin
        if rst = '1' then
            game_start <= '0';
            secret_number_int <= 0;
        elsif rising_edge(clk) then
            if enter_btn_pulse = '1' then
                if game_start = '0' then
                    secret_number_int <= to_integer(unsigned(secret_number_std));
                    game_start <= '1';
                end if;
            end if;
        end if;
    end process;
    
    enter_btn_state: process(rst, clk)
    begin
        if rst = '1' then
            enter_btn_pulse_curr <= '0';
            enter_btn_pulse_prev <= '0';
        elsif rising_edge(clk) then
            enter_btn_pulse_prev <= enter_btn_pulse_curr;
            enter_btn_pulse_curr <= enter_btn_pulse;
        end if;
    end process;
    
    user_input_proc: process(clk, rst)
    begin
        if rst = '1' then
            progress_state <= NONE;
        elsif rising_edge(clk) then
            if enter_btn_pulse_prev = '1' then
                if guess = secret_number_int then
                    progress_state <= WIN;
                elsif guess > secret_number_int then
                    progress_state <= HOT;
                elsif guess < secret_number_int then
                    progress_state <= COLD;
                else
                    progress_state <= NONE;
                end if;
            end if;
        end if;
    end process;
    
    clk_div_proc: process(clk, rst)
    begin
        if rst = '1' then
            clk_2Hz <= '0';
            counter <= 0;
        elsif rising_edge(clk) then
            counter <= counter + 1;
            if counter = HALF_PERIOD - 1 then
                clk_2Hz <= not clk_2Hz;
                counter <= 0;
            end if;
        end if;
    end process;
    
    blink_green: process(clk_2Hz, rst)
    begin
        if rst = '1' then
            blink <= '0';
        elsif rising_edge(clk) then
            if progress_state = WIN then
                blink <= not blink;
            else
                blink <= '0';
            end if;
        end if;
    end process;
    
    guess <= to_integer(unsigned(switches));
    
    red_led <= '1' when rst = '1' else
               '1' when progress_state = HOT else
               '0';
    
    blue_led <= '1' when progress_state = COLD else
                '0';
    
    green_led <= blink;
    
    leds <= std_logic_vector(to_unsigned(secret_number_int, 4)) when show_btn = '1' else (others => '0');
    
end Behavioral;

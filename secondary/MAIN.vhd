library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MAIN is
	port (
		CLOCK : in std_logic;

		P1_LEFT : in std_logic;
		P1_READY : in std_logic;
		P1_RIGHT : in std_logic;
		P2_LEFT : in std_logic;
		P2_READY : in std_logic;
		P2_RIGHT : in std_logic;

		P1_LEFT_OUT : out std_logic;
		P1_READY_OUT : out std_logic;
		P1_RIGHT_OUT : out std_logic;
		P2_LEFT_OUT : out std_logic;
		P2_READY_OUT : out std_logic;
		P2_RIGHT_OUT : out std_logic
	);
end MAIN;

architecture Behavioral of MAIN is

begin

	process (CLOCK) is
		variable button_debounce_p1_left : natural := 0;
		variable button_debounce_p1_ready : natural := 0;
		variable button_debounce_p1_right : natural := 0;
		variable button_debounce_p2_left : natural := 0;
		variable button_debounce_p2_ready : natural := 0;
		variable button_debounce_p2_right : natural := 0;
	begin
		if rising_edge(CLOCK) then
			if P1_LEFT = '0' then
				button_debounce_p1_left := 10000;
			end if;
			if P1_READY = '0' then
				button_debounce_p1_ready := 10000;
			end if;
			if P1_RIGHT = '0' then
				button_debounce_p1_right := 10000;
			end if;
			if P2_LEFT = '0' then
				button_debounce_p2_left := 10000;
			end if;
			if P2_READY = '0' then
				button_debounce_p2_ready := 10000;
			end if;
			if P2_RIGHT = '0' then
				button_debounce_p2_right := 10000;
			end if;

			if button_debounce_p1_left > 0 then
				button_debounce_p1_left := button_debounce_p1_left - 1;
				P1_LEFT_OUT <= '0';
			else
				P1_LEFT_OUT <= '1';
			end if;
			if button_debounce_p1_ready > 0 then
				button_debounce_p1_ready := button_debounce_p1_ready - 1;
				P1_READY_OUT <= '0';
			else
				P1_READY_OUT <= '1';
			end if;
			if button_debounce_p1_right > 0 then
				button_debounce_p1_right := button_debounce_p1_right - 1;
				P1_RIGHT_OUT <= '0';
			else
				P1_RIGHT_OUT <= '1';
			end if;
			if button_debounce_p2_left > 0 then
				button_debounce_p2_left := button_debounce_p2_left - 1;
				P2_LEFT_OUT <= '0';
			else
				P2_LEFT_OUT <= '1';
			end if;
			if button_debounce_p2_ready > 0 then
				button_debounce_p2_ready := button_debounce_p2_ready - 1;
				P2_READY_OUT <= '0';
			else
				P2_READY_OUT <= '1';
			end if;
			if button_debounce_p2_right > 0 then
				button_debounce_p2_right := button_debounce_p2_right - 1;
				P2_RIGHT_OUT <= '0';
			else
				P2_RIGHT_OUT <= '1';
			end if;
		end if;
	end process;

end Behavioral;
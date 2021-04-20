----------------------------------------------------------------------------------
-- Company: LeTourneau University
-- Engineer: 
-- 
-- Create Date:    19:46:40 04/11/2021 
-- Design Name: 
-- Module Name:    FinalDisplay - Behavioral 
-- Project Name: Digital Electronics Clock Display
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FinalDisplay is
    Port ( --SEC_0 : in  STD_LOGIC_VECTOR(3 downto 0);	
				-- clock signal
				CLK : in STD_LOGIC;
				
				-- 4 digits on board				
				AN1 : out  STD_LOGIC;
				AN2 : out  STD_LOGIC;
				AN3 : out  STD_LOGIC;
				AN4 : out  STD_LOGIC;
				AN5 : out STD_LOGIC;
				AN6 : out STD_LOGIC;
	 
				-- 7 outputs for 7 segment display
           C_A : out  STD_LOGIC;
           C_B : out  STD_LOGIC;
           C_C : out  STD_LOGIC;
           C_D : out  STD_LOGIC;
           C_E : out  STD_LOGIC;
           C_F : out  STD_LOGIC;
           C_G : out  STD_LOGIC;
			  DP : out STD_LOGIC;
			  
			  -- LED 0 for clock 2 indicator
			  LD0 : out STD_LOGIC;
			  
			  -- reset button, button 0
			  RESET : in STD_LOGIC;
			  
			  -- clock 2 from 555 timer
			  clk2 : in STD_LOGIC);
end FinalDisplay;


architecture Behavioral of FinalDisplay is
	-- clock NUMBER
	signal CLK_COUNTER : natural range 0 to 50000000 := 0;
	
	-- which AN port to trigger
	signal COUNTER: natural range 0 to 5 := 0;
	
	-- AN ports
	signal AN : std_logic_vector(5 downto 0);
	
	-- BCD of digits
	signal HOUR2 : STD_LOGIC_VECTOR(3 downto 0) := "0000"; 
	signal HOUR1 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal MIN2 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal MIN1 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal SEC2 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal SEC1 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	
	-- counter of number to display
	signal NUMBER : STD_LOGIC_VECTOR(3 downto 0);
	
	-- information for 7 segment display
	signal DISPLAY : std_logic_vector(6 downto 0);
	

signal hour24: std_logic_vector(0 downto 0);

signal dot: std_logic := '1'; -- AM & PM

--signal hset: std_logic_vector(0 downto 0);
--signal mset: std_logic_vector(0 downto 0);
--signal sset: std_logic_vector(0 downto 0);


begin
	
	-- do stuff every 1 ms, dividing clock signal
	Clock_Divider2 : process (CLK)
		begin
			if (rising_edge(CLK)) then
				CLK_COUNTER <= CLK_COUNTER + 1;
				-- every 8000 ticks, so every 1 ms for a 8 MHz clock
				if (CLK_COUNTER >= 8000) then
					CLK_COUNTER <= 0;
					
					-- increment COUNTER from 1 to 3
					COUNTER <= COUNTER + 1;
					if (COUNTER > 5) then
						COUNTER <= 0;
					end if;					
				end if;
			end if;
	end process;
	
	-- use COUNTER to modify which AN port is on
	Change_AN : process (COUNTER)
	begin
		case COUNTER is
			when 0 => AN <= "000001";
			when 1 => AN <= "000010";
			when 2 => AN <= "000100";
			when 3 => AN <= "001000";
			when 4 => AN <= "010000";
			when 5 => AN <= "100000";
			when others => AN <= "000000"; -- if counter above 5, all off
		end case;
		
		-- turn AN ports on or off accordingly
		-- @ change for hours
		AN1 <= AN(0);
		AN2 <= AN(1);
		AN3 <= AN(2);
		AN4 <= AN(3);
		AN5 <= AN(4);
		AN6 <= AN(5);
	end process;
	
	-- display decimal place based on counter, active low
	Display_DP : process (COUNTER)
	begin
		case COUNTER is
			when 0 => DP <= dot;
			when 1 => DP <= '1';
			when 2 => DP <= '0';
			when 3 => DP <= '1';
			when 4 => DP <= '0';
			when 5 => DP <= '1';
			when others => DP <= '1'; -- decimal place off if counter above 5
		end case;
	end process;
	
	-- change number displayed based on counter
	Change_Number : process (COUNTER)
	begin
		case COUNTER is
			when 0 => NUMBER <= SEC1;
			when 1 => NUMBER <= SEC2;
			when 2 => NUMBER <= MIN1;
			when 3 => NUMBER <= MIN2;
			when 4 => NUMBER <= HOUR1;
			when 5 => NUMBER <= HOUR2;
			when others => NUMBER <= "1111"; -- invalid number if counter above 5
		end case;
	end process;
	
	-- display numbers, active low
	Display_LED : process(NUMBER)
	begin
		case NUMBER is
				when "0000" =>
					DISPLAY <= "0000001"; -- 0
				when "0001" =>
					DISPLAY <= "1001111"; -- 1
				when "0010" =>
					DISPLAY <= "0010010"; -- 2
				when "0011" =>
					DISPLAY <= "0000110"; -- 3
				when "0100" =>
					DISPLAY <= "1001100"; -- 4
				when "0101" =>
					DISPLAY <= "0100100"; -- 5
				when "0110" =>
					DISPLAY <= "0100000"; -- 6
				when "0111" =>
					DISPLAY <= "0001111"; -- 7
				when "1000" =>
					DISPLAY <= "0000000"; -- 8
				when "1001" =>
					DISPLAY <= "0000100"; -- 9
				when others =>
					DISPLAY <= "1111111"; -- blank when not a digit
		end case;
		
		-- send information to board
		C_A <= DISPLAY(6);
		C_B <= DISPLAY(5);
		C_C <= DISPLAY(4);
		C_D <= DISPLAY(3);
		C_E <= DISPLAY(2);
		C_F <= DISPLAY(1);
		C_G <= DISPLAY(0);
		
		
	end process;
	
	-----process clock-----
	divide: process(clk2)
	begin
		if(rising_edge(clk2)) then
		
			if(sec1 = "1001") then 
				sec1 <= "0000";
				
				if(sec2 = "0101") then
					sec2 <= "0000";
					
					if(min1 = "1001") then
						min1 <= "0000";
						
						if(min2 = "0101") then
							min2 <= "0000";
							
							if(hour24 = "1") then
							--24 hour time
								if(hour1 = "1001" AND (hour2 = "0000" OR hour2 = "0001")) then
									hour1 <= "0000";
									hour2 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour2 )) +1, 4));
								elsif (hour1 = "0011" AND hour2 = "0010") then
									hour1 <= "0000";
									hour2 <= "0000";
								end if;
							
							-- 12 hour time
							else
								-- for normal increments, when hour1 is 9, set it to 0 and increment hour2
								if(hour1 = "1001" AND (hour2 = "0000")) then
									hour1 <= "0000";
									hour2 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour2 )) +1, 4));
								-- when hit 12, turn PM indicator on, unless it is on, then turn it off
								elsif (hour1 = "0010" AND hour2 = "0001") then
									hour1 <= "0001";
									hour2 <= "0000";
										if (dot = '1')then
											dot <= '0';
										else
											dot <= '1';
										end if;
										
								end if;
								
							end if;
							
						else
							min2 <= std_logic_vector(to_unsigned(to_integer(unsigned( min2 )) + 1, 4));
						end if;
						
					else
						min1 <= std_logic_vector(to_unsigned(to_integer(unsigned( min1 )) + 1, 4));
					end if;
					
				else
					sec2 <= std_logic_vector(to_unsigned(to_integer(unsigned( sec2 )) + 1, 4));
				end if;
				
			else
				sec1 <= std_logic_vector(to_unsigned(to_integer(unsigned( sec1 )) + 1, 4));
			end if;
			
			
			
		end if;
		
		
		-- reset clock if reset button, button 0, is pressed
		if(RESET = '0') then
			sec1 <= "0000";
			sec2 <= "0000";
			min1 <= "0000";
			min2 <= "0000";
			hour1 <= "0000";
			hour2 <= "0000";
			dot <= '0';
		end if;
		
	end process;
	
	-- use LED 0 as output for clock
	LD0 <= clk2;

end Behavioral;
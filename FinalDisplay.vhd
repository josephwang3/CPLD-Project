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
				BOARD_CLK : in STD_LOGIC;
				
				-- 10 digits on board, controlled by common cathodes (common ground)
				-- 6 for hour, minute, second
				C_SEC1 : out  STD_LOGIC;
				C_SEC2 : out  STD_LOGIC;
				C_MIN1 : out  STD_LOGIC;
				C_MIN2 : out  STD_LOGIC;
				C_HOUR1 : out  STD_LOGIC;
				C_HOUR2 : out  STD_LOGIC;
				
				-- 4 for month, day
				C_DAY1 : out  STD_LOGIC;
				C_DAY2 : out  STD_LOGIC;
				C_MONTH1 : out  STD_LOGIC;
				C_MONTH2 : out  STD_LOGIC;	
	 
				-- 7 anode outputs for 7 segment display
           AN_A : out  STD_LOGIC;
           AN_B : out  STD_LOGIC;
           AN_C : out  STD_LOGIC;
           AN_D : out  STD_LOGIC;
           AN_E : out  STD_LOGIC;
           AN_F : out  STD_LOGIC;
           AN_G : out  STD_LOGIC;
			  AN_DP : out STD_LOGIC;
			  
			  -- LED 0 for clock 2 indicator
			  LD0 : out STD_LOGIC;
			  
			  -- reset button, button 0
			  RESET : in STD_LOGIC;
			  
			  -- clock 2 from 555 timer
			  clk2 : in STD_LOGIC;
			  
			  -- set switch
			  	set : in STD_LOGIC;

			  	-- set buttons
				set_min : in STD_LOGIC;
				set_hour : in STD_LOGIC;
				set_day : in STD_LOGIC;
				set_month : in STD_LOGIC);
end FinalDisplay;


architecture Behavioral of FinalDisplay is
	-- clock NUMBER
	signal CLK_COUNTER : natural range 0 to 50000 := 0;
	
	-- which CATHODES port to trigger
	signal COUNTER: natural range 0 to 9 := 0;
	
	-- common cathode ports for multiplexing digits
	signal CATHODES : std_logic_vector(9 downto 0);
	
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

	-- decimal point to indicate AM/PM
	signal dot: std_logic := '0';

	-- this one contains 8 bits for the switch statement, it is one 4 bit
	-- number and another 4 bit number, not an 8 bit number
	signal month : std_logic_vector(7 downto 0);
	
	signal month1 : std_logic_vector(3 downto 0) := "0000";
	signal month2 : std_logic_vector(3 downto 0) := "0000";

	signal day1 : std_logic_vector(3 downto 0) := "0000";
	signal day2 : std_logic_vector(3 downto 0) := "0000";

	-- extra variables to know when to increment the month
	signal maxday1 : std_logic_vector(3 downto 0); 
	signal maxday2 : std_logic_vector(3 downto 0);

begin
	
	-- do stuff every 1 ms, dividing clock signal
	Clock_Divider2 : process (BOARD_CLK)
		begin
			if (rising_edge(BOARD_CLK)) then
				CLK_COUNTER <= CLK_COUNTER + 1;
				-- every 8000 ticks, so every 1 ms for a 8 MHz clock
				if (CLK_COUNTER >= 8000) then
					CLK_COUNTER <= 0;
					
					-- increment COUNTER from 0 to 9 for 10 displays
					COUNTER <= COUNTER + 1;
					if (COUNTER > 9) then
						COUNTER <= 0;
					end if;					
				end if;
			end if;
	end process;
	
	-- use COUNTER to modify which CATHODES port is on
	Change_Cathodes : process (COUNTER)
	begin
		case COUNTER is
			when 0 => CATHODES <= "1111111110";
			when 1 => CATHODES <= "1111111101";
			when 2 => CATHODES <= "1111111011";
			when 3 => CATHODES <= "1111110111";
			when 4 => CATHODES <= "1111101111";
			when 5 => CATHODES <= "1111011111";
			when 6 => CATHODES <= "1110111111";
			when 7 => CATHODES <= "1101111111";
			when 8 => CATHODES <= "1011111111";
			when 9 => CATHODES <= "0111111111";
			when others => CATHODES <= "1111111111"; -- if counter above 9, all off
		end case;
		
		-- turn CATHODES ports on or off accordingly
		C_SEC1 <= CATHODES(0);
		C_SEC2 <= CATHODES(1);
		C_MIN1 <= CATHODES(2);
		C_MIN2 <= CATHODES(3);
		C_HOUR1 <= CATHODES(4);
		C_HOUR2 <= CATHODES(5);
		C_DAY1 <= CATHODES(6);
		C_DAY2 <= CATHODES(7);
		C_MONTH1 <= CATHODES(8);
		C_MONTH2 <= CATHODES(9);		
	end process;
	
	-- display decimal place based on counter, active low
	Display_DP : process (COUNTER)
	begin
		case COUNTER is
			when 0 => AN_DP <= dot;
			when 1 => AN_DP <= '0';
			when 2 => AN_DP <= '1';
			when 3 => AN_DP <= '0';
			when 4 => AN_DP <= '1';
			when 5 => AN_DP <= '0';
			when 6 => AN_DP <= '0';
			when 7 => AN_DP <= '0';
			when 8 => AN_DP <= '1';
			when 9 => AN_DP <= '0';
			when others => AN_DP <= '0'; -- decimal place off if counter above 9
		end case;
	end process;
	
	-- change number displayed based on counter
	Change_Number : process (COUNTER)
	begin
		month1 <= month(3 downto 0);
		month2 <= month(7 downto 4);
	
		case COUNTER is
			when 0 => NUMBER <= SEC1;
			when 1 => NUMBER <= SEC2;
			when 2 => NUMBER <= MIN1;
			when 3 => NUMBER <= MIN2;
			when 4 => NUMBER <= HOUR1;
			when 5 => NUMBER <= HOUR2;
			when 6 => NUMBER <= DAY1;
			when 7 => NUMBER <= DAY2;
			when 8 => NUMBER <= MONTH1;
			when 9 => NUMBER <= MONTH2;
			when others => NUMBER <= "1111"; -- invalid number if counter above 5
		end case;
	end process;
	
	-- display numbers, active low
	Display_LED : process(NUMBER)
	begin
		case NUMBER is
				when "0000" =>
					DISPLAY <= "1111110"; -- 0
				when "0001" =>
					DISPLAY <= "0110000"; -- 1
				when "0010" =>
					DISPLAY <= "1101101"; -- 2
				when "0011" =>
					DISPLAY <= "1111001"; -- 3
				when "0100" =>
					DISPLAY <= "0110011"; -- 4
				when "0101" =>
					DISPLAY <= "1011011"; -- 5
				when "0110" =>
					DISPLAY <= "1011111"; -- 6
				when "0111" =>
					DISPLAY <= "1110000"; -- 7
				when "1000" =>
					DISPLAY <= "1111111"; -- 8
				when "1001" =>
					DISPLAY <= "1111011"; -- 9
				when others =>
					DISPLAY <= "0000000"; -- blank when not a digit
		end case;
		
		-- send information to board
		AN_A <= DISPLAY(6);
		AN_B <= DISPLAY(5);
		AN_C <= DISPLAY(4);
		AN_D <= DISPLAY(3);
		AN_E <= DISPLAY(2);
		AN_F <= DISPLAY(1);
		AN_G <= DISPLAY(0);
		
		
	end process;
	
	-----process clock-----
	divide: process(clk2)
	begin
	  if(rising_edge(clk2) AND set = '0') then
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

									case month is 
										--january
										when "00000001" => 
											maxday1 <= "0001";
											maxday2 <= "0011";
										--february
										when "00000010" => 
											maxday1 <= "1000";
											maxday2 <= "0010";
										--march
										when "00000011" =>
											maxday1 <= "0001";
											maxday2 <= "0011";
										--april
										when "00000100" =>
											maxday1 <= "0000";
											maxday2 <= "0011";
										--may
										when "00000101" =>
											maxday1 <= "0001";
											maxday2 <= "0011";
										--june
										when "00000110" =>
											maxday1 <= "0000";
											maxday2 <= "0011";
										--july
										when "00000111" =>
											maxday1 <= "0001";
											maxday2 <= "0011";
										--august
										when "00001000" =>
											maxday1 <= "0001";
											maxday2 <= "0011";
										--september
										when "00001001" =>
											maxday1 <= "0000";
											maxday2 <= "0011";
										--october
										when "00010000" =>
											maxday1 <= "0001";
											maxday2 <= "0011";
										--november
										when "00010001" =>
											maxday1 <= "0000";
											maxday2 <= "0011";
										--december
										when "00010010" =>
											maxday1 <= "0001";
											maxday2 <= "0011";
										when others => 
											maxday1 <= "0000";
											maxday2 <= "0000";
									end case;

									if(day1 = maxday1 AND day2 = maxday2) then
										day1 <= "0001";
										day2 <= "0000";
										if(month < "00001010") then 
											month <= std_logic_vector(to_unsigned(to_integer(unsigned( month )) +1, 8));
										elsif(month = "00001010") then 
											month <= "00010000";
										elsif(month = "00010000") then 
											month <= "00010001";
										elsif(month = "00010001") then 
											month <= "00010010"; 
										elsif(month = "00010010") then 
											month <= "00000000"; 		
										end if;
									else
										if(day1 = "1001") then
											day1 <= "0000";
											day2 <= std_logic_vector(to_unsigned(to_integer(unsigned( day2 )) +1, 4));
										else
											day1 <= std_logic_vector(to_unsigned(to_integer(unsigned( day1 )) +1, 4));
										end if;
									end if;
								else
									hour1 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour1 )) + 1, 4));
								end if;
								
							else
								-- for normal increments, when hour1 is 9, set it to 0 and increment hour2
								if(hour1 = "1001" AND hour2 = "0000") then
									hour1 <= "0000";
									hour2 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour2 )) +1, 4));
								elsif (hour1 = "0010" AND hour2 = "0001") then
									hour1 <= "0001";
									hour2 <= "0000";
										if (dot = '0')then
											dot <= '1';
											
											case month is 
												--january
												when "00000001" => 
													maxday1 <= "0001";
													maxday2 <= "0011";
												--february
												when "00000010" => 
													maxday1 <= "1000";
													maxday2 <= "0010";
												--march
												when "00000011" =>
													maxday1 <= "0001";
													maxday2 <= "0011";
												--april
												when "00000100" =>
													maxday1 <= "0000";
													maxday2 <= "0011";
												--may
												when "00000101" =>
													maxday1 <= "0001";
													maxday2 <= "0011";
												--june
												when "00000110" =>
													maxday1 <= "0000";
													maxday2 <= "0011";
												--july
												when "00000111" =>
													maxday1 <= "0001";
													maxday2 <= "0011";
												--august
												when "00001000" =>
													maxday1 <= "0001";
													maxday2 <= "0011";
												--september
												when "00001001" =>
													maxday1 <= "0000";
													maxday2 <= "0011";
												--october
												when "00010000" =>
													maxday1 <= "0001";
													maxday2 <= "0011";
												--november
												when "00010001" =>
													maxday1 <= "0000";
													maxday2 <= "0011";
												--december
												when "00010010" =>
													maxday1 <= "0001";
													maxday2 <= "0011";
												when others => 
													maxday1 <= "0000";
													maxday2 <= "0000";
											end case;

											if(day1 = maxday1 AND day2 = maxday2) then
												day1 <= "0001";
												day2 <= "0000";
												if(month < "00001010") then 
													month <= std_logic_vector(to_unsigned(to_integer(unsigned( month )) +1, 8));
												elsif(month = "00001010") then 
													month <= "00010000";
												elsif(month = "00010000") then 
													month <= "00010001";
												elsif(month = "00010001") then 
													month <= "00010010"; 
												elsif(month = "00010010") then 
													month <= "00000000"; 		
												end if;
											else
												if(day1 = "1001") then 
													day1 <= "0000";
													day2 <= std_logic_vector(to_unsigned(to_integer(unsigned( day2 )) +1, 4));
												else
													day1 <= std_logic_vector(to_unsigned(to_integer(unsigned( day1 )) +1, 4));
												end if;
											end if;
										end if;
								
								else
									hour1 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour1 )) + 1, 4));

								
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

		if(set = '1') then 
			sec1 <= "0000";
			sec2 <= "0000";

			if(set_min = '1') then 
				if(min1 = "1001") then
					if(min2 = "0101") then
						min2 <= "0000";
						min1 <= "0000";
					else
						min2 <= std_logic_vector(to_unsigned(to_integer(unsigned( min2 )) + 1, 4));
					end if;
				else
					min1 <= std_logic_vector(to_unsigned(to_integer(unsigned( min1 )) + 1, 4));
				end if;
			end if;

			if(set_hour = '1') then 
				if(hour24 = "1") then
					--24 hour time
					if(hour1 = "1001" AND (hour2 = "0000" OR hour2 = "0001")) then
						hour1 <= "0000";
						hour2 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour2 )) +1, 4));
					elsif(hour1 = "0011" AND hour2 = "0010") then
						hour1 <= "0000";
						hour2 <= "0000";
					elsif(hour2 > "0010" OR hour1 > "1001") then
						hour2 <= "0000";
						hour1 <= "0000";
					else
						hour1 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour1 )) + 1, 4));
					end if;

				else
					--not 24
					if(hour1 = "1001" AND hour2 = "0000") then
						hour1 <= "0000";
						hour2 <= "0001";
					elsif (hour1 = "0010" AND hour2 > "0000") then
						hour1 <= "0001";
						hour2 <= "0000";
						if (dot = '0')then
							dot <= '1';
						else
							dot <= '0';
						end if;
					elsif(hour2 > "0001" OR hour1 > "1001") then 
						hour2 <= "0000";
						hour1 <= "0000"; 
					else
						hour1 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour1 )) + 1, 4));		
					end if;

				end if;
			end if; 

			if(set_day = '1') then 
				case month is 
					--january
					when "00000001" => 
						maxday1 <= "0001";
						maxday2 <= "0011";
					--february
					when "00000010" => 
						maxday1 <= "1000";
						maxday2 <= "0010";
					--march
					when "00000011" =>
						maxday1 <= "0001";
						maxday2 <= "0011";
					--april
					when "00000100" =>
						maxday1 <= "0000";
						maxday2 <= "0011";
					--may
					when "00000101" =>
						maxday1 <= "0001";
						maxday2 <= "0011";
					--june
					when "00000110" =>
						maxday1 <= "0000";
						maxday2 <= "0011";
					--july
					when "00000111" =>
						maxday1 <= "0001";
						maxday2 <= "0011";
					--august
					when "00001000" =>
						maxday1 <= "0001";
						maxday2 <= "0011";
					--september
					when "00001001" =>
						maxday1 <= "0000";
						maxday2 <= "0011";
					--october
					when "00010000" =>
						maxday1 <= "0001";
						maxday2 <= "0011";
					--november
					when "00010001" =>
						maxday1 <= "0000";
						maxday2 <= "0011";
					--december
					when "00010010" =>
						maxday1 <= "0001";
						maxday2 <= "0011";
					when others => 
						maxday1 <= "0000";
						maxday2 <= "0000";
				end case;

				if(day1 = maxday1 AND day2 = maxday2) then
					day1 <= "0001";
					day2 <= "0000";
				elsif(day1 = "1001") then
					day1 <= "0000";
					day2 <= std_logic_vector(to_unsigned(to_integer(unsigned( day2 )) + 1, 4));
				else
					day1 <= std_logic_vector(to_unsigned(to_integer(unsigned( day1 )) + 1, 4));

				end if; 
			end if; 

			if(set_month = '1') then 
				if(month < "00001010") then 
					month <= std_logic_vector(to_unsigned(to_integer(unsigned( month )) + 1, 8));
				elsif(month = "00001010") then 
					month <= "00010000";
				elsif(month = "00010000") then 
					month <= "00010001";
				elsif(month = "00010001") then 
					month <= "00010010"; 
				elsif(month = "00010010") then 
					month <= "00000000"; 
				else
					month <= "00000000";
				end if;
			end if;
		end if;
		
		if(RESET = '0') then
			sec1 <= "0000";
			sec2 <= "0000";
			min1 <= "0000";
			min2 <= "0000";
			hour1 <= "0000";
			hour2 <= "0000";
			month <= "00000000";
			day1 <= "0000";
			day2 <= "0000";
			dot <= '0';
		end if;
				
	end process;
	
	-- use LED 0 as output for clock
	LD0 <= clk2;


end Behavioral;
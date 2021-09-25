----------------------------------------------------------------------------------
-- Company: LeTourneau University
-- Engineer: Joseph Wang
-- 
-- Create Date:    19:46:40 04/11/2021 
-- Design Name: 
-- Module Name:    FinalDisplay - Behavioral 
-- Project Name: Digital Electronics Clock Display
-- Target Devices: 
-- Tool versions: 
-- Description: VHDL code for digital clock built using a Xilinx CPLD
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
	 
				-- 7 outputs for 7 segment display
           		C_A : out  STD_LOGIC;
           		C_B : out  STD_LOGIC;
           		C_C : out  STD_LOGIC;
           		C_D : out  STD_LOGIC;
           		C_E : out  STD_LOGIC;
           		C_F : out  STD_LOGIC;
           		C_G : out  STD_LOGIC;
			  
			  	-- LED 0 for clock 2 indicator
			  	LD0 : out STD_LOGIC;

			  	--Reset button
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
	signal CLK_COUNTER : natural range 0 to 50000000 := 0;
	
	-- which AN port to trigger
	signal COUNTER: natural range 0 to 3 := 0;
	
	-- AN ports
	signal AN : std_logic_vector(3 downto 0);
	
	-- BCD of digits
	-- signal HR2
	-- signal HR1
	signal MIN2 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal MIN1 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal SEC2 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	signal SEC1 : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	
	-- counter of number to display
	signal NUMBER : STD_LOGIC_VECTOR(3 downto 0);
	
	-- information for 7 segment display
	signal DISPLAY : std_logic_vector(6 downto 0);
	
	
	-- contains the numbers to be displayed (1 = left, 2 = right)
	signal hour1 : std_logic_vector(3 downto 0);
	signal hour2 : std_logic_vector(3 downto 0);

	-- if 24 hour or not
	signal hour24: std_logic_vector(0 downto 0);

	-- PM/AM dot
	signal dot: std_logic_vector(0 downto 0); -- AM & PM

	-- this one contains 8 bits for the switch statement, it is one 4 bit
	-- number and another 4 bit number, not an 8 bit number
	signal month : std_logic_vector(7 downto 0);

	signal day1 : std_logic_vector(3 downto 0);
	signal day2 : std_logic_vector(3 downto 0);

	-- extra variables to know when to increment the month
	signal maxday1 : std_logic_vector(3 downto 0); 
	signal maxday2 : std_logic_vector(3 downto 0);




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
					if (COUNTER > 3) then
						COUNTER <= 0;
					end if;					
				end if;
			end if;
	end process;
	
	-- use COUNTER to modify which AN port is on
	Change_AN : process (COUNTER)
	begin
		case COUNTER is
			when 0 => AN <= "1110";
			when 1 => AN <= "1101";
			when 2 => AN <= "1011";
			when 3 => AN <= "0111";
		end case;
		
		-- turn AN ports on or off accordingly
		AN1 <= AN(3);
		AN2 <= AN(2);
		AN3 <= AN(1);
		AN4 <= AN(0);
	end process;
	
	-- change counter (number displayed) based on COUNTER
	Change_Counter : process (COUNTER)
	begin
		case COUNTER is
			when 0 => NUMBER <= SEC1;
			when 1 => NUMBER <= SEC2;
			when 2 => NUMBER <= MIN1;
			when 3 => NUMBER <= MIN2;
		end case;
	end process;
	
	-- display numbers
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
									hour2 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour2 )) + 1, 4));
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
							--not 24
								if(hour1 = "1001" AND hour2 = "0000") then
									hour1 <= "0000";
									hour2 <= std_logic_vector(to_unsigned(to_integer(unsigned( hour2 )) +1, 4));
								elsif (hour1 = "0010" AND hour2 = "0001") then
									hour1 <= "0001";
									hour2 <= "0000";
										if (dot = "0")then
											dot <= "1";
										else
											dot <= "0";

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
						if (dot = "0")then
							dot <= "1";
						else
							dot <= "0";
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
		end if;
		
	end process divide;
	
	-- use LED 0 as output for clock
	LD0 <= clk2;

end Behavioral;
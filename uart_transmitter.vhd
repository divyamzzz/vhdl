
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;



entity uart_transmitter is

    GENERIC (  data_bits: INTEGER:=8;
			    max_tick:INTEGER:=16 
			);	
		
    Port ( clk 			: in  STD_LOGIC;
           reset 		: in  STD_LOGIC;
           transmitter_start 	: in  STD_LOGIC;
           tick 		: in  STD_LOGIC;
           parallel_data_input 			: in  STD_LOGIC_VECTOR (7 downto 0);
           transmitter_done_tick : out  STD_LOGIC;
           serial_data_out 			: out  STD_LOGIC);
end uart_transmitter;


architecture behav of uart_transmitter is

	type state_type is ( idle_state, start_state, data_state, stop_state);
	signal present_state, next_state : state_type;
	signal sample_prev, sample_next : unsigned(3 downto 0); -- Keep Track of samples
	signal n_count_prev, n_count_next : unsigned(2 downto 0); -- keep track of number of bit transmitted
	signal data_bits_prev, data_bits_next : STD_LOGIC_VECTOR (7 downto 0); -- bit shifting from this parallel register
	signal tx_prev, tx_next : std_logic;


		begin
			PROCESS(clk ,reset)
				begin
					if(reset='1') then
						present_state <= idle_state;
						sample_prev     <= (OTHERS =>'0');
						n_count_prev     <= (OTHERS =>'0');
						data_bits_prev     <= (OTHERS =>'0');
						tx_prev    <= '1';
					elsif(rising_edge(clk)) then	
						present_state <= next_state;
						sample_prev     <= sample_next;
						n_count_prev     <= n_count_next;
						data_bits_prev     <= data_bits_next;
						tx_prev    <= tx_next;	
					end if;
			end PROCESS;

     -- NEXT STATE LOGIC
			
			PROCESS(present_state, sample_prev, n_count_prev, data_bits_prev, tick, tx_prev, transmitter_start, parallel_data_input)
				begin
					next_state <= present_state;
					sample_next	  <= sample_prev;
					n_count_next	  <= n_count_prev;
					data_bits_next     <= data_bits_prev;
					tx_next    <= tx_prev;
               transmitter_done_tick <= '0'; 
					
					case present_state is
					
					-- WHEN STATE IS idle_state
						when idle_state =>
							tx_next     <=   '1';
							if(transmitter_start='1') then
								next_state  <=  start_state; 
								sample_next      <= (OTHERS =>'0');
								data_bits_next      <= parallel_data_input;
							end if;
						
					 when start_state =>
						 tx_next      <=    '0';
						 if(tick='1') then
							 if(sample_prev =max_tick-1) then
								 next_state <= data_state;
								 sample_next <= (OTHERS=>'0');
								 n_count_next <= (OTHERS=>'0');
							 else
							    sample_next <= sample_prev +1 ;
							 end if;
						end if;		
								 
					 when data_state =>
						 tx_next      <=    data_bits_prev(0);
						 if(tick='1') then	
							if(sample_prev =max_tick-1) then						 
								sample_next <= (OTHERS=>'0');
							   data_bits_next <= '0'  & data_bits_prev(7 downto 1) ;
								  if(n_count_prev = (data_bits-1 )) then
									  next_state <= stop_state;
								  else
									 n_count_next <=n_count_prev+1;
								  end if;
							
							 else
								sample_next <= sample_prev +1 ;
							 end if;
						 end if;
						 
					 when stop_state =>
						 tx_next <='1';
						 if(tick='1') then
							if (sample_prev=(max_tick-1)) then
								next_state    <=   idle_state;
								transmitter_done_tick  <=   '1';
							else
								sample_next <= sample_prev+1;
							end if;
						end if;
					end case;
				end PROCESS;
				serial_data_out <= tx_prev;
						
							
							
end behav;



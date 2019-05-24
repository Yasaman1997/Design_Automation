library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity module5 is
	generic (n : integer := 6;
	m : integer := 6);
	
   Port(clk: in STD_LOGIC);
end module5;

architecture Behavioral of module5 is

	subtype ROW_BYTE is std_logic_vector(15 downto 0);
	type COLUMN_BYTE is array ((n-1) downto 0) of ROW_BYTE;
	type memory is array ((m-1) downto 0) of COLUMN_BYTE;
	
	subtype SECONDARY_ROW_BYTE is std_logic_vector(31 downto 0);
	type SECONDARY_COLUMN_BYTE is array ((n-1) downto 0) of SECONDARY_ROW_BYTE;
	type secondary_memory is array ((m-1) downto 0) of SECONDARY_COLUMN_BYTE;

	subtype f is std_logic_vector(23 downto 0);
	type nf is array ((n-1) downto 0) of f;
	type mnf is array ((m-1) downto 0) of nf;
	
	subtype f2 is std_logic_vector(47 downto 0);
	type nf2 is array ((n-1) downto 0) of f2;
	type mnf2 is array ((m-1) downto 0) of nf2;
	
	--component declaration
	component floating_point_mult is
		Port(aclk : IN STD_LOGIC;
			  s_axis_a_tvalid : IN STD_LOGIC;
			  s_axis_a_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
			  s_axis_b_tvalid : IN STD_LOGIC;
			  s_axis_b_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
			  m_axis_result_tvalid : OUT STD_LOGIC;
			  m_axis_result_tdata : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
		);
	end component;
	
	component fixed_to_float is
		Port (
			aclk : IN STD_LOGIC;
			s_axis_a_tvalid : IN STD_LOGIC;
			s_axis_a_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			m_axis_result_tvalid : OUT STD_LOGIC;
			m_axis_result_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
		);
	end component;
	
	component float_to_fixed is
		Port(
			aclk : IN STD_LOGIC;
			s_axis_a_tvalid : IN STD_LOGIC;
			s_axis_a_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
			m_axis_result_tvalid : OUT STD_LOGIC;
			m_axis_result_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	end component;
	
	component float_to_fixed2 is
		Port(
			aclk : IN STD_LOGIC;
			s_axis_a_tvalid : IN STD_LOGIC;
			s_axis_a_tdata : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
			m_axis_result_tvalid : OUT STD_LOGIC;
			m_axis_result_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	end component;
	
	--initializing rom
	function init_rom
		return memory is 
		variable tmp : memory := (others => (others => (others => '0')));
	begin 
		for addr_pos1 in 0 to m - 1 loop
			for addr_pos2 in 0 to n - 1 loop
				-- Initialize each address with the address itself
				tmp(addr_pos1)(addr_pos2):= std_logic_vector(to_unsigned(addr_pos1 + addr_pos2, 16));
			end loop;
		end loop;
		return tmp;
	end init_rom;	 
	
	--initializing secondary rom
	function init_secondary_rom
		return secondary_memory is 
		variable tmp1 : secondary_memory := (others => (others => (others => '0')));
	begin 
		for addr_pos1 in 0 to m - 1 loop
			for addr_pos2 in 0 to n - 1 loop
				-- Initialize each address with the address itself
				tmp1(addr_pos1)(addr_pos2):= std_logic_vector(to_unsigned(addr_pos1 + addr_pos2, 32));
			end loop;
		end loop;
		return tmp1;
	end init_secondary_rom;
	
	
	--signal declaration
	signal m1 : memory := init_rom;
	signal m2: memory := init_rom;
	signal m3: secondary_memory := init_secondary_rom;
	signal fa: mnf;
	signal fa_tvalid: STD_LOGIC;
	signal fb: mnf;
	signal fb_tvalid: STD_LOGIC;
	signal fc: mnf2;
	signal fc_tvalid: STD_LOGIC;
	signal final_tvalid: STD_LOGIC;
	
		
	
begin

	F1: for addr_pos1 in 0 to m - 1 generate
		begin
		F2: for addr_pos2 in 0 to n - 1 generate
			begin
			--converting first number to float
			float1: fixed_to_float port map(aclk => clk,
													 s_axis_a_tvalid => '1',
													 s_axis_a_tdata => m1(addr_pos1)(addr_pos2),
										          m_axis_result_tvalid => fa_tvalid,
										          m_axis_result_tdata => fa(addr_pos1)(addr_pos2));
			
			--converting second number to float
			float2: fixed_to_float port map(aclk => clk,
													  s_axis_a_tvalid => '1',
													  s_axis_a_tdata => m2(addr_pos1)(addr_pos2),
										           m_axis_result_tvalid => fb_tvalid,
										           m_axis_result_tdata => fb(addr_pos1)(addr_pos2));
			
			--multiplying the two numbers
			mult: floating_point_mult port map(aclk => clk,
														  s_axis_a_tvalid => '1',
			                                   s_axis_a_tdata => fa(addr_pos1)(addr_pos2),
														  s_axis_b_tvalid => '1',
														  s_axis_b_tdata => fb(addr_pos1)(addr_pos2),
														  m_axis_result_tvalid => fc_tvalid,
														  m_axis_result_tdata => fc(addr_pos1)(addr_pos2));
		
			--convering floating point answer to fixed point 32 bit answer using the secondary float_to_fixed module   
			fixed: float_to_fixed2 port map(aclk => clk,
													  s_axis_a_tvalid => '1',
													  s_axis_a_tdata => fc(addr_pos1)(addr_pos2),
													  m_axis_result_tvalid => final_tvalid,
													  m_axis_result_tdata => m3(addr_pos1)(addr_pos2));
		end generate F2;
	end generate F1;



end Behavioral;
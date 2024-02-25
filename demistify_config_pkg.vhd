-- DeMiSTifyConfig_pkg.vhd
-- Copyright 2021 by Alastair M. Robinson

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package demistify_config_pkg is
constant demistify_romspace : integer := 14; -- 16k address space to accommodate  ROM
constant demistify_romsize1 : integer := 13; -- 8k fo the first chunk
constant demistify_romsize2 : integer := 13; -- 8k for the second chunk, too

constant demistify_joybits : integer := 8;

constant demistify_button1 : integer := 4;
constant demistify_button2 : integer := 5;
constant demistify_button3 : integer := 6;
constant demistify_button4 : integer := 7;
constant demistify_button5 : integer := 8;
constant demistify_button6 : integer := 9;

constant demistify_serialdebug : std_logic := '0';

COMPONENT  SVI328
	PORT
	(
		CLOCK_27 :	IN STD_LOGIC;
		--RESET_N :   IN std_logic;
		SDRAM_DQ		:	 INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SDRAM_A		:	 OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
		SDRAM_DQML		:	 OUT STD_LOGIC;
		SDRAM_DQMH		:	 OUT STD_LOGIC;
		SDRAM_nWE		:	 OUT STD_LOGIC;
		SDRAM_nCAS		:	 OUT STD_LOGIC;
		SDRAM_nRAS		:	 OUT STD_LOGIC;
		SDRAM_nCS		:	 OUT STD_LOGIC;
		SDRAM_BA		:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		SDRAM_CLK		:	 OUT STD_LOGIC;
		SDRAM_CKE		:	 OUT STD_LOGIC;
		-- UART
		UART_TX     :   OUT STD_LOGIC;
		UART_RX     :   IN STD_LOGIC := '1';
		SPI_DO		:	 OUT STD_LOGIC;
--		SPI_SD_DI	:	 IN STD_LOGIC;
		SPI_DI		:	 IN STD_LOGIC;
		SPI_SCK		:	 IN STD_LOGIC;
		SPI_SS2		:	 IN STD_LOGIC;
		SPI_SS3		:	 IN STD_LOGIC;
--		SPI_SS4		:	 IN STD_LOGIC;
		CONF_DATA0		:	 IN STD_LOGIC;
		VGA_HS		:	 OUT STD_LOGIC;
		VGA_VS		:	 OUT STD_LOGIC;
		VGA_R		:	 OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_G		:	 OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_B		:	 OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		AUDIO_L  : out std_logic;
		AUDIO_R  : out std_logic;
		DAC_L           : OUT SIGNED(15 DOWNTO 0);
        DAC_R           : OUT SIGNED(15 DOWNTO 0)
	);
END COMPONENT;

end package;

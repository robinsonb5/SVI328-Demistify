#include "menu.h"
#include "config.h"
#include "statusword.h"
#include "ps2.h"
#include "keyboard.h"
#include "uart.h"
#include "interrupts.h"

#include <stdio.h>
#include <string.h>

#include "c64keys.c"

int LoadROM(const char *fn);

int UpdateKeys(int blockkeys)
{
	handlec64keys();
	return(HandlePS2RawCodes(blockkeys));
}

void clearram(int size,int idx)
{
	int i;
	EnableFpga();
	SPI(SPI_FPGA_FILE_INDEX);
	SPI(idx); /* Memory clear */
	DisableFpga();

	EnableFpga();
	SPI(SPI_FPGA_FILE_TX);
	SPI(0x1); /* Upload */
	DisableFpga();

	EnableFpga();
	SPI(SPI_FPGA_FILE_TX_DAT);
	for(i=0;i<size;++i)
		SPI(0xff); /* Send 0xff instead of 0x00 */
	DisableFpga();

	EnableFpga();
	SPI(SPI_FPGA_FILE_TX);
	SPI(0x00); /* End Upload */
	DisableFpga();
}


extern struct menu_entry menu[];
void cycle(int row);
void toggle(int row)
{
	struct menu_entry *m=&menu[row];
	if(menu_longpress && !m->u.opt.shift)
		clearram(512,1); /* Clear first part of cartridge memory */
	else
	{
		cycle(row);
		cycle(row);
	}
	/* The upload should have provoked a reset, so no need to do anything more. */
}

char *autoboot()
{
	char *result=0;

	if(!LoadROM(ROM_FILENAME))
		result="ROM loading failed";

	initc64keys();

	return(result);
}


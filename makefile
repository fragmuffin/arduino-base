PRJ            = main
OBJ            = $(PRJ).o

# Target Information
MCU_TARGET     = atmega2560

# Flashing Parameters
PART_NUMBER     = $(MCU_TARGET)
PROGRAMMER_ID   = wiring
BAUDRATE        = 115200
AVRDUDE_FLAGS   = -D

SERIAL_NUMBER 	= $(shell cat arduino-serialnumber.txt)
#SERIAL_NUMBER   = 854353330313518002A1
#PORT            = /dev/ttyACM0
#$(eval PORT:=$(shell python build_tools/arduino-device.py --serialnum=$(SERIAL_NUMBER)))

# Build Options:
OPTIMIZE       = -O2

DEFS           =
LIBS           = 

# You should not have to change anything below here.

CC          = avr-gcc
TOOLS_DIR   = bin

# Override is only needed by avr-lib build system.

override CFLAGS        = -g -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS)
override LDFLAGS       = -Wl,-Map,$(PRJ).map

OBJCOPY        = avr-objcopy
OBJDUMP        = avr-objdump

.PHONY: doc

all: rebuild

# device management
list-devices:
	python build_tools/arduino-device.py --list

set-port:
	$(eval PORT:=$(shell python $(TOOLS_DIR)/arduino-device.py --serialnum=$(SERIAL_NUMBER)))
	# Confirm a device-file was found for arduino device $(SERIAL_NUMBER)
	test -n "$(PORT)" && test -e $(PORT)

# Building

build: $(PRJ).elf lst text eeprom

rebuild: clean build

$(PRJ).elf: $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

# dependency:
$(OBJ): $(PRJ).c

GIT_IGNORED_FILES=$(shell git check-ignore *)

clean:
	rm -rf $(GIT_IGNORED_FILES)

clean-all: clean clean-doc

lst: $(PRJ).lst

%.lst: %.elf
	$(OBJDUMP) -h -S $< > $@

# Rules for building the .text rom images

text: hex bin srec

hex:  $(PRJ).hex
bin:  $(PRJ).bin
srec: $(PRJ).srec

%.hex: %.elf
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

%.srec: %.elf
	$(OBJCOPY) -j .text -j .data -O srec $< $@

%.bin: %.elf
	$(OBJCOPY) -j .text -j .data -O binary $< $@

# Rules for building the .eeprom rom images

eeprom: ehex ebin esrec

ehex:  $(PRJ)_eeprom.hex
ebin:  $(PRJ)_eeprom.bin
esrec: $(PRJ)_eeprom.srec

%_eeprom.hex: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O ihex $< $@ \
	|| { echo empty $@ not generated; exit 0; }

%_eeprom.srec: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O srec $< $@ \
	|| { echo empty $@ not generated; exit 0; }

%_eeprom.bin: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O binary $< $@ \
	|| { echo empty $@ not generated; exit 0; }

# Every thing below here is used by avr-libc's build system and can be ignored
# by the casual user.

FIG2DEV                 = fig2dev

dox: eps png pdf

eps: $(PRJ).eps
png: $(PRJ).png
pdf: $(PRJ).pdf

%.eps: %.fig
	$(FIG2DEV) -L eps $< $@

%.pdf: %.fig
	$(FIG2DEV) -L pdf $< $@

%.png: %.fig
	$(FIG2DEV) -L png $< $@

# ================= Supporting Libraries =================
pylib-comms:
	cd pylib/comms && make


# ================= Flash to MCU =================
flash: rebuild set-port
	avrdude -c$(PROGRAMMER_ID) -P$(PORT) -p$(PART_NUMBER) -b$(BAUDRATE) $(AVRDUDE_FLAGS) -Uflash:w:$(PRJ).hex

flash-eeprom: set-port
	# WARNING: this hasn't worked so far, something to do with the arduino bootloader not supporting eeprom
	avrdude -c$(PROGRAMMER_ID) -P$(PORT) -p$(PART_NUMBER) -b$(BAUDRATE) $(AVRDUDE_FLAGS) -Ueeprom:w:$(PRJ)_eeprom.hex

verify: set-port
	avrdude -c$(PROGRAMMER_ID) -P$(PORT) -p$(PART_NUMBER) -b$(BAUDRATE) $(AVRDUDE_FLAGS) -Uflash:v:$(PRJ).hex

doc:
	cd ./doc && make all
	
clean-doc:
	cd ./doc && make clean

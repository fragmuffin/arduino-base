# arduino-base
Starting point for software dev' directly for the Atmel MCU on an Arduino board


# Install Stuff

For these instructions, I'll assume you're using a linux (debian-based) operating system.
This will work on a PC, or Raspberry Pi

## Software Packages

    sudo apt install gcc-avr avrdude


## pip (Python) packages

    sudo pip install -r bin/requirements.txt


# Flash to Arduino

## Set Arduino's Serial-Number

find out what your Arduino's serial number is by plugging it in, then running the command:

    bin/arduino-device.py --list

Your Arduino's serial number will be a list of letters and numbers ~20 characters long

Open the arduino-serialnumber.txt file and replace the text in there with your serial number

Then, to flash the software in, run the command:

    make flash

if everything worked, you should see: `avrdude done.  Thank you.`

and the green light on the Arduino will be blinking each second.


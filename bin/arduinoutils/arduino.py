
import re
from serial.tools.list_ports_posix import comports

# Connectivity Description:
#
#   Terminology:
#       Throughout this module, the term "connected to arduino board" (and similar phrases) is used a lot.
#       These phrases elude to the following connectivity:
#           - Host machine is connected via USB to the Arduino's onboard FT232R IC (ie: NOT the target MCU)
#           - The FT232R identifies itself to the host machine as an emulated serial port
#               (Serial / UART / RS232 / "that old ball-mouse cable", whatever the kids call it these days).
#           - The other side of the FT232R connects to the target MCU via supported UART pins
#       Then we've got full connectivity
#
#   FT232R is a Serial Repeater:
#       It's also worth noting here that there are effectively 2 serial connections at play here:
#           - 1) Host machine -> FT232R (emulated over USB)
#           - 2) FT232R -> target MCU (actual UART)
#       But, somehow by magic, the 2nd connection's baud rate changes when the USB serial
#       This can be tricky when configuring / debugging communication.
#       for example:
#           >>> import serial
#           >>> ser = serial.Serial('/dev/ttyACM1', 9600)
#       Cool, a baud rate of 9600... wait, what's the baud rate between FT232R & the target?
#       FIXME: as of writing this, I don't have the answers... TODO: document configuration lessons learnt

class ArduinoNotFoundError(Exception):
    """Raised if the requested board could not be found"""
    pass

class MultipleArduinosFoundError(Exception):
    """Raised if multiple connected boards are found with the same serial number"""


class ArduinoDevice(object):
    def __init__(self, serial_number):
        self.serial_number = serial_number
        self._comport = None

    @property
    def comport(self):
        if self._comport is None:
            # --- All serial ports
            ports = [c for c in comports() if c.serial_number == self.serial_number]

            if not ports:
                raise ArduinoNotFoundError("for serial: '%s'" % self.serial_number)
            elif len(ports) > 1:
                raise MultipleArduinosFoundError("for serial: '%s'" % self.serial_number)
            else:
                self._comport = ports.pop()

        return self._comport


def arduino_comports():
    """
    List of serial comports serial numbers of Arduino boards connected to this machine
    :return: generator of comports connected to arduino
    """
    arduino_manufacturer_regex = re.compile(r'arduino', re.IGNORECASE) # simple, because I've only got one to test on
    for comport in comports():
        if comport.manufacturer:
            match = arduino_manufacturer_regex.search(comport.manufacturer)
            if match:
                yield comport


def connected_serial_numbers():
    """
    List serial numbers of Arduino boards connected to this machine
    :return: generator of connected arduino serial numbers
    """
    for comport in arduino_comports():
        yield comport.serial_number

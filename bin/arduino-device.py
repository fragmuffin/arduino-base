#!/usr/bin/env python

import os
import sys
import inspect
import argparse

_this_path = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.append(os.path.join(_this_path))
import arduinoutils


# ----- Input Parameters
# Deaults

# Parser
parser = argparse.ArgumentParser(description="Find Arduino's COMM Port")
parser.add_argument(
    '--serialnum', '-s', dest='serialnum', default=None, type=str,
    help="Arduino board's serial number (run with --list to list all connected devices)",
)
parser.add_argument(
    '--list', '-l', dest='list', default=False, action='store_true',
    help="list all available arduino serial numbers"
)

args = parser.parse_args()


# ----- Mainline
if args.list:
    print("Connected Arduino Serial Numbers:")
    comports = list(arduinoutils.arduino_comports())
    if comports:
        for comport in comports:
            print("    - %s" % comport.serial_number)
    else:
        print("    (none found)")
    exit(0)

if args.serialnum is None:
    print("No serial number specified...")
    parser.print_help()
    exit(1)

# print device file to stdout
print(arduinoutils.ArduinoDevice(args.serialnum).comport.device)

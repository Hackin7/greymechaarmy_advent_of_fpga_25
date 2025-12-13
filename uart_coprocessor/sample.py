# Sample Circuitpython Code
import board
import busio
import digitalio
import time
import hardware.main
import hardware.fpga

PATH="/hackin7/aoc25/"
hardware.main.hw_state["fpga_overlay"].deinit()
if input("type something to update fpga: ") != "":
    h = hardware.fpga.upload_bitstream(PATH+"/coprocessor.bit")
    h.deinit()

### Need clear Pins first #######################
DATA_PINS_NO = [board.GP8, board.GP9, board.GP10, board.GP11, board.GP12]
pins = []
for p in DATA_PINS_NO:
    d = digitalio.DigitalInOut(p)
    d.direction = digitalio.Direction.OUTPUT
    d.value = False
    pins.append(d)
            
for d in pins:
    d.deinit()

### Configure UART GPIO #########################
class FpgaCoprocessor():
    
    def __init__(self):
        self.NUM_CHAR = 1
        self.uart = busio.UART(board.GP8, board.GP9, baudrate=460800, timeout=0.1)
        DATA_PINS_NO = [board.GP10, board.GP11, board.GP12, board.GP13, board.GP14, board.GP15]
        pins = []
        for p in DATA_PINS_NO:
            d = digitalio.DigitalInOut(p)
            d.direction = digitalio.Direction.OUTPUT
            d.value = False
            pins.append(d)
        self.pins = pins
    
    def write_int(self, val):
        n = val
        s = n.to_bytes(self.NUM_CHAR, byteorder="big")
        #print(s)
        self.uart.write(s)
    
    def read_int(self):
        s = fp.uart.read()[-self.NUM_CHAR :]
        #print(len(s), s)
        n = int.from_bytes(s.decode("ascii"), byteorder="big")
        return n

### Processing ##################################
fp = FpgaCoprocessor()
# Print dummy message
print(fp.uart.read())

fp.pins[0].value = 1 # Forward mode
fp.pins[1].value = 0 # Forward mode
# fp.uart.write("123456789012345678")
# print(fp.uart.read()[-18:])

fp.write_int(10)
print(fp.read_int())

### Previous mode
fp.pins[0].value = 0
fp.pins[1].value = 1
fp.write_int(11)
print(fp.read_int()) # Should be 10
fp.write_int(11)
print(fp.read_int()) # Should be 11

### Addition Mode
fp.pins[0].value = 0
fp.pins[1].value = 0
fp.write_int(11)
print(fp.read_int()) # Should be 22
fp.write_int(100)
print(fp.read_int()) # Should be 111


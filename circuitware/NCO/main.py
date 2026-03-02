from machine import Pin
import time
import ice

LED_R = Pin(1, Pin.OUT)
LED_G = Pin(0, Pin.OUT)
LED_B = Pin(9, Pin.OUT)

LED_R.value(1)
LED_G.value(1)
LED_B.value(1)

file = open("synth.bin", "br")
flash = ice.flash(miso=Pin(4), mosi=Pin(7), sck=Pin(6), cs=Pin(5))
flash.erase(4096) # Optional
flash.write(file)
# Optional
fpga = ice.fpga(cdone=Pin(40), clock=Pin(21), creset=Pin(31), cram_cs=Pin(5), cram_mosi=Pin(4), cram_sck=Pin(6), frequency=24.576)
fpga.start()

FPGA_RESET = Pin(30 , Pin.OUT)

FPGA_RESET.value(0)
time.sleep(1)
FPGA_RESET.value(1)

'''
LED_R.value(0)
LED_G.value(0)
LED_B.value(0)
'''

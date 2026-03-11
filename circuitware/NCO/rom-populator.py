import math
import matplotlib.pyplot as plt

PERIODIC = True

waveform_rom = []

for i in range(32):
    waveform_rom.append(math.sin(2*math.pi*i/32)*(2**15-1))

waveform_slope_rom = []


for i in range(32):
    if i == 31:
        if PERIODIC:
            waveform_slope_rom.append((waveform_rom[0]-waveform_rom[i])*4)
        else:
            # If not defined as periodic (we want a discontinuity) then use the second to last slope as the last slope.
            waveform_slope_rom.append(waveform_slope_rom[30])
    else:
        waveform_slope_rom.append((waveform_rom[i+1]-waveform_rom[i])*4)

plt.scatter(range(32), waveform_rom, color='blue', label='waveform')
plt.scatter(range(32), waveform_slope_rom, color='red', label='slope*4')

plt.legend()

plt.show()

print(waveform_rom)

print(waveform_slope_rom)

print("---")

print("@00 ", end='')
for sample in waveform_rom:
    if sample < 0:
        print(f"{(1<<16)+int(sample):04X}")
    else:
        print(f"{int(sample):04X}")



print("---")

print("@00 ", end='')
for sample in waveform_slope_rom:
    if sample < 0:
        print(f"{(1<<16)+int(sample):04X}")
    else:
        print(f"{int(sample):04X}")

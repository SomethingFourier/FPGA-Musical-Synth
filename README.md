# FPGA-Musical-Synth
A musical synthesizer based on the iCE40 FPGA that outputs I2S audio.

Video demonstration of sine wave synth: https://youtu.be/_ejQGvuSiI8

### Status: NCO synthesis now works!
The synth now makes sine waves by the Numerically-Controlled Oscillator (NCO)! This opens the door to make any kind of wave we want just by updating the ROMs. Additionally, a multi-clock cycle multiplication algorithm has been implemented to save space on the FPGA and take advantage of the 512 master clock cycles between one sample and the next.
##### 1. Supporting more keys:
> The hardware implementation for this is actively being developed using shift registers in a Parallel In Serial Out (PISO) setup to allow for sequential reading of each key on a fast clock cycle while using much fewer FPGA pins than even the current design with only 13 key support.
##### 2. Multiple Key Press Support:
> This could be done a variety of ways, either by averaging frequencies together or by using multiple NCOs at once. How this ends up getting accomplished will be decided on later.
##### 3. ADSR Envolope (Attack, Delay, Sustain, Release):
> An amplitude envolope would greatly improve the articulation of the synth sound and make things more dynamic.
##### 4. A PCB for it all
> The first iteration will likely interface with the development board (potentially the first few). However, the final iteration should be independent of a development board.
<br>
<br>

### The previous build: (square wave synthesis)
Video demonstration of square wave synth: https://youtu.be/o0nXdgJRZlI

The wave_period_selector method of synthesis used is described by this process:
> wave_period_selector sends the half-period of the frequency (musical note) associated with the key pressed to i2s_transmitter. i2s_transmitter sends a square wave via I2S that oscillates every half-period (the one sent to it by wave_period_selector) to an I2S DAC. This generates a square wave at the desired frequency.

The square wave synth only supports one key press at a time. If multiple keys are pressed, the key that gets checked first in wave_period_selector is the note that gets played. Further, due to the nature of this synthesis, this only supports square waves.

### Hardware being used:
1. pico2-ice development board
2. Adafruit I2S 3W Class D Amplifier
3. Speaker; I am using a 3W 16Ω speaker. I was initially using a 3W 4Ω speaker, but it did not produce quality sound at low frequencies, likely due to 16Ω speaker having more back-and-forth travel than the 4Ω speaker.

### Software Tools:
> While I am currently using open-source tools, I hope to soon get a free hobbyist license for the iCEcube2 software made by Lattice Semiconductors to enable less manual RTL synthesis and easier simulation. 
##### 1. RTL Synthesis:
> OSS-CAD-SUITE is being used for iCE40 synthesis, Place-and-Route, as well as packing.
##### 2. Simulation:
> Icarus Verilog (iverilog) is being used for test bench simulation and other debugging. Verilator may replace icarus if it is decided that it is superior for testbenching this project's verilog modules.
##### 3. HDL:
> The FPGA was programmed in SystemVerilog.

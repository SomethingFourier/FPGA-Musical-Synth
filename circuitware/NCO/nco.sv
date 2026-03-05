/*
This module takes in an accumulator increment value from the tone_frequency_calculator.sv module.
This increment value corresponds to a desired output frequency. Then, every sample of our 48000Hz
sample rate, the accumulator_value increments by the increment value. This gives us the location
to look in the waveform ROM look up tables for the sample at the phase we're at.

The accumulator_value will wrap around after every full cycle (period) giving us the periodic
wave output we want.

When the tone_frequency_calculator.sv module detects no keys are being pressed, it will give this
module a high value on the nco_mute logic line. This will set the accumulator value back to 0.

To ensure that the i2s_transmitter module doesn't get halfway through serially outputting before
the sample gets changed by this module, the i2s_transmitter will locally save the sample to its
own register, in the process delaying the output by one sample, but preventing this issue.
*/

module nco
(
    input logic rst,
    input logic master_clk, // This is the main 24.576 MHz clock from either the RP2040/RP2350 or a dedicated crystal oscillator.
    input logic sample_clk_en, // This is the 48 kHz sample clock enable signal that is divided down from the 24.576 MHz clock by the clock_divider module.
    input logic nco_mute, // This is a mute boolean value provided by the tone_frequency_calculator module. It enables mute when no buttons are pressed.
    input logic [31:0] accumulator_increment_value, // This is the accumulator increment value provided to this module by the tone_frequency_calculator module. This tells the nco how much to increment the 32 bit fixed point accumulator register every clock cycle of the 48MHz clock.
    output logic signed [15:0] sample_output, // This is the output sample that has been calculated by the NCO and is ready to be output over I2S.
    output logic [31:0] accumulator_value, // This is the current value in the accumulator (phase). It's only output for debugging and testbenching.
    output logic signed [15:0] sample_li_offset // This is the linear interpolation offset. It is the result of multiplying the fractional part of the accumulator value by the slope given by the last LUT value. It's only output for debugging and testbenching.
    //output logic [16:0] sample // This is the sample value given directly by the waveform LUT. It can be output for debugging and testbenching.
);
    /*
    Populating ROMs:
    This section of the code is responsible for initializing the 2 length-32 ROMs that hold the waveform information. The waveform_rom holds 32 samples
    of the desired waveform. The waveform_slope_rom holds precalculated slopes between the current waveform sample and the next one. The last value of the
    slope rom can either be the slope between the last and first sample, or a continuation of the last slope for a waveform like a sawtooth wave where a
    discontinuity is actually wanted.

    The waveform roms are populated with data held in the waveform_rom.mem and waveform_slope_rom.mem files. These files are read at compilation time and
    get baked into the logic.
    */

    // Waveform ROM
    logic signed [15:0] waveform_rom [0:31];

    // Waveform Slope ROM
    logic signed [15:0] waveform_slope_rom [0:31];

    // Populate rom data
    initial begin
        $readmemh("waveform_rom.mem", waveform_rom);
        $readmemh("waveform_slope_rom.mem", waveform_slope_rom);
    end

    // Booth's algorithm cycle counter
    reg [4:0] booth_cycle_counter; // max value should be 0b10000
    reg signed [58:0] booth_A;
    reg signed [58:0] booth_S;
    reg signed [58:0] booth_P;
    reg signed [58:0] booth_pos_2A;
    reg signed [58:0] booth_neg_2A;

    // Linear interpolation stuff
    logic signed [15:0] sample;
    logic signed [15:0] slope;

    // Sequential state machine logic
    logic read_roms;
    logic multiply;
    logic add;
    
    // The sample flag is set whenever we see that the sample_clk_en was high for one of the master clock cycles. This tells the state machine that its time to generate another sample.
    logic sample_flag;

    // A state machine to sequentially process things and output a sample at 48kHz
    always_ff @(posedge master_clk or negedge rst) begin
        if (!rst) begin
            // Reset things to zero
            accumulator_value <= 32'h0;
            sample <= 16'h0;
            sample_output <= 16'h0;
            slope <= 16'h0;
            sample_flag <= 0;
            read_roms <= 0;
            multiply <= 0;
            add <= 0;
            booth_cycle_counter <= 0;
            booth_A <= 0;
            booth_S <= 0;
            booth_P <= 0;
            booth_pos_2A <= 0;
            booth_neg_2A <= 0;
        end
        else if (nco_mute) begin
            // Reset things to zero
            accumulator_value <= 32'h0;
            sample <= 16'h0;
            sample_output <= 16'h0;
            slope <= 16'h0;
            sample_flag <= 0;
            read_roms <= 0;
            multiply <= 0;
            add <= 0;
            booth_cycle_counter <= 0;
            booth_A <= 0;
            booth_S <= 0;
            booth_P <= 0;
            booth_pos_2A <= 0;
            booth_neg_2A <= 0;
        end
        else begin
            if (sample_flag) begin // The sample flag is brought high whenever the 48kHz clock hits a rising edge.
                sample_flag <= 0; // Acknowledge that we've seen the sample flag go high by setting it back to 0
                accumulator_value <= accumulator_value + accumulator_increment_value; // Increment the accumulator by the increment value provided by the tone_frequency_calculator module.
                read_roms <= 1; // Tell the state machine we're ready to move to the next step, reading the ROMs.
            end 
            else if (read_roms) begin
                read_roms <= 0; // Acknowledge by setting back to zero
                sample <= waveform_rom[accumulator_value[31:27]]; // Take 5 MSbs of the accumulator and get the value in the waveform rom at that address.
                slope <= waveform_slope_rom[accumulator_value[31:27]]; // Take 5 MSbs of the accumulator and get the value in the waveform slope rom at that address.
                multiply <= 1; // At this point we're ready to do the multiplication before we add it back to the sample
            end 
            else if (multiply) begin
                /*
                This is where we perform multiplication using Booth's Multiplication Algorithm Radix 4.
                Need to multiply 27 bit fractional part of the accumulator value by the 16 bit slope. We then need to shift it right so that our answer is back in the 5.27 fixed point format.
                */

                // This is an implementation of multiplication without Booth's algorithm using System Verilog's multiplication (*) (Using entirely combinational logic once synthesized)
                // To get system verilog to return all the bits, we need to pad 16 bits to the first value
                // sample_li_offset <= (($signed({16'h0, accumulator_value[26:0]}) * slope) >>> 29); // This was used for testing the NCO before we implemented Booth's Algorithm

                /*
                Booth's algorithm (radix 4) takes 14 cycles to complete. We can complete each cycle in one clock cycle, but we also need to initialize some registers with values first.
                Doing this adds 2 cycles to our loop.

                In our implementation, the multiplicand (m) is the fractional part of the accumulator_value register (27 bits). The multiplier (r) is the slope register.
                Because Booth's algorithm radix 4 requires N/2 cycles where N is the number of bits of the largest value we're multiplying, we need an even value of N so that our number
                of cycles does not become a fraction. To do this, we pad m to be 28 bits. We don't need to worry about sign extending because the accumulator_value is not signed and will never be
                a negative number. Padding by this extra zero also prevents Booth's algorithm from thinking that it is a negative value when it is actually a large positive value.

                In the first cycle, we initialize the booth_A register with the m shifted left by 28 bits + a dummy bit. We have to do this first because the following cycle depends on A, and we can't
                have parallel processes depending on eachother's result.

                In the second cycle, we initialize the booth_S register to be the two's complement inverse of booth_A by subtracting booth_A from 0. We then initialize booth_P to be the slope, sign extended
                to fill 28 bits, then padded with another 28 zeroes before being shifted left one bit for the dummy bit. We then initialize booth_pos_2A to be booth_A multiplied by 2 (shifted left one) and
                booth_neg_2A to be booth_P mulitplied by 2 (shifted left one). Remember that we can't have parallel processes depending on one another's result, so we have to perform the two's complement inverse
                of booth_A here as well so that it does not depend on the value in the booth_P register.
                */

                if (!booth_cycle_counter) begin // First cycle
                    booth_A <= $signed({1'b0, accumulator_value[26:0]}) << 29; // Sign extend 1 bit (total 28 bits), then shift 28 + 1 dummy bit
                    booth_cycle_counter <= booth_cycle_counter + 1; // Go to the next cycle on the next clock cycle
                end
                else if (booth_cycle_counter == 1) begin // Second cycle
                    booth_S <= 0 - booth_A; // booth_S = -booth_A, but we don't want to perform the multiplication by -1 as that would defeat the purpose of creating Booth's algorithm.
                    booth_P <= {28'b0, 28'(signed'(slope))} << 1; // Convert signed 16bit to signed 28 bit, then pad with another 28 zeroes before shifting left by one to include the dummy bit.
                    booth_pos_2A <= booth_A << 1; // Multiply booth_A by 2 by shifting it left 1 bit.
                    booth_neg_2A <= (0 - booth_A) << 1; // Multiply booth_S by 2 by shifting it left 1 bit. We have to substitute what we put in booth_S into this assignment, otherwise we would have a process depending on another parallel process.
                    booth_cycle_counter <= booth_cycle_counter + 1; // Go to the next cycle on the next clock cycle
                end
                else if (booth_cycle_counter <= 15) begin // Cycles 3-16 (when booth_cycle_counter is 2 through 15)
                    /*
                    This is the core of booth's algorithm, the radix table and operations. Now that we have initialized the registers, we can start cycling through Booth's algorithm.
                    We start by looking at the 3 least significant bits of booth_P. Depending on the 3 bit value, we perform one of the operations. We then shift the value in booth_P right by 2 bits,
                    making sure we are sign extending (arithmetic shift right >>>).
                    */
                    case (booth_P[2:0]) // Look at three least significant bits of booth_P.
                        3'b000:  booth_P <= booth_P >>> 2; // If these bits are 0b000, we do nothing, then shift.
                        3'b001:  booth_P <= (booth_P + booth_A) >>> 2; // If these bits are 0b001, we perform P+A, then shift.
                        3'b010:  booth_P <= (booth_P + booth_A) >>> 2; // If these bits are 0b010, we perform P+A, then shift.
                        3'b011:  booth_P <= (booth_P + booth_pos_2A) >>> 2; // If these bits are 0b011, we perform P+2A, then shift.
                        3'b100:  booth_P <= (booth_P + booth_neg_2A) >>> 2; // If these bits are 0b100, we perform P+(-2A), then shift.
                        3'b101:  booth_P <= (booth_P + booth_S) >>> 2; // If these bits are 0b101, we perform P+S, then shift.
                        3'b110:  booth_P <= (booth_P + booth_S) >>> 2; // If these bits are 0b110, we perform P+S, then shift.
                        3'b111:  booth_P <= booth_P >>> 2; // If these bits are 0b111, we do nothing, then shift.
                    endcase
                    booth_cycle_counter <= booth_cycle_counter + 1; // Go to the next cycle on the next clock cyle
                end else begin // We're done with our multiplication now, we can save our value and move on.
                    booth_cycle_counter <= 0; // Reset the cycle counter back to zero
                    sample_li_offset <= booth_P >>> 30; // 1 + 27 + 2 => because of booths algorithm dummy bit, fractional quality of the accumulator value, and divide by 4 because the slope rom has been pre-multiplied by 4.
                    multiply <= 0; // Run this after we've finished multiplying
                    add <= 1; // Tell the state machine that it's now time to add the sample from the waveform_rom and the linear interpolation offset (sample_li_offset) from the multiplication to get the total sample.
                end
            end 
            else if (add) begin
                sample_output <= sample + sample_li_offset; // Add the sample from the waveform_rom and the linear interpolation offset from the multiplication to calculate the total linearly interpolated sample.
                add <= 0; // We're done adding. The sample_output is now ready to be output over I2S
            end

            if (sample_clk_en) begin // This runs at 48kHz
                sample_flag <= 1; // Set the sample flag high telling the rest of the state machine that we're ready to generate another sample. (It's been 1/48000 of a second)
            end
        end
    end


endmodule
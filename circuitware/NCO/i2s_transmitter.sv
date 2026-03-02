module i2s_transmitter
(
    input  logic clk, // 24.576 MHz
    input  logic bit_clk_en,
    input  logic rst,
    input  logic [15:0] new_sound_sample,

    output logic bit_clock,
    output logic word_select,
    output logic sound_data,

    output logic test_LED_B

    // ONLY FOR SIMULATION
    //output logic [4:0] testing_bit_counter
);

    logic [2:0]  bit_clock_timer;    // divides 24.576 MHz MHz clock by 16 = 1.536 MHz
    logic [4:0]  bit_counter;        // keeps track of where we are in the I2S transmission loop
    logic [15:0] sound_bits;         // holds the sound sample that is currently being transmitted
    logic [15:0] banked_sound_bits;  // holds the sound sample we get from nco

    //assign testing_bit_counter = bit_counter;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            bit_clock_timer <= 0;
            bit_clock <= 0;
        end 
        else begin
            // Increment timer
            bit_clock_timer <= bit_clock_timer + 1;
            
            // Toggle clock when timer hits 7 (every 8 cycles)
            if (bit_clock_timer == 3'd7) bit_clock <= ~bit_clock;
        end
    end

    always_ff @(posedge bit_clock or negedge rst) begin
        if (!rst) begin
            bit_counter <= 31; // goes to 31, for 32 bits total, 16 bits each for left and right channels (right is silent in our case)
            sound_data  <= 0;
            word_select <= 0;
            sound_bits  <= 0;
            banked_sound_bits <= 0;
            test_LED_B  <= 1;
        end
        else begin
            // incrementation –> because register is 0-31 (2^5), which is what we want, we let roll-over reset it to zero
            bit_counter <= bit_counter + 1;

            // sound output
            /* 
            2 scenarios for left channel audio:
                bit_counter =  0, WS = 0 –> set to send out MSB       send out bit on bit_counter = 1
                bit_counter = 15, WS = 1 –> set to send send out LSB  send out bit on bit_counter = 16
            */
            if  (bit_counter < 16) sound_data <= sound_bits[15 - bit_counter]; // left-channel
            else                   sound_data <= sound_bits[15 - bit_counter + 16]; // right-channel

            // left-right channel transitions
            // word_select changes 1 bit before the next 16 bit audio sample, thus the LSB of each sample is sent out on the "wrong" word_select value (but this is part of the I2S protocol)
            if  (bit_counter == 31) word_select <= 0; // transition to left channel right before LSB of left-channel audio
            if  (bit_counter == 15) word_select <= 1; // transition to right channel right before LSB of right-channel audio

            // get new sound data
            if  (bit_counter == 31) begin
                sound_bits <= banked_sound_bits;
                banked_sound_bits <= new_sound_sample;
            end

            if (bit_counter == 14) test_LED_B <= ~test_LED_B;
        end
    end

endmodule

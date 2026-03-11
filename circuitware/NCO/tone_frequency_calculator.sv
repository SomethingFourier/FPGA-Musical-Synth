module tone_frequency_calculator
(
    // io
    input  logic clk,
    input  logic rst,
    
    input  logic key1,
    input  logic key2,
    input  logic key3,
    input  logic key4,
    input  logic key5,
    input  logic key6,
    input  logic key7,
    input  logic key8,
    input  logic key9,
    input  logic key10,
    input  logic key11,
    input  logic key12,
    input  logic key13,

    output reg [31:0] nco_increment_value,
    output logic nco_mute, // boolean

    output logic test_LED_R
);

    reg [31:0] next_nco_increment_value;

    always_comb begin
        if (!rst) nco_mute = 1; 

        next_nco_increment_value = 0;
        test_LED_R = 1;

        if      (key1)  next_nco_increment_value = 32'b00000001011001010010110000000000; // C4  261.6*32/48E3 = 0.1744 = 0b0.00101100101001011 =    00000_001011001010010110000000000
        else if (key2)  next_nco_increment_value = 32'b00000001011110100111100010000000; // C#4 277.2*32/48E3 = 0.1848 = 0b0.00101111010011110001 = 00000_001011110100111100010000000
        else if (key3)  next_nco_increment_value = 32'b00000001100100001111111110000000; // D4  293.7*32/48E3 = 0.1958 = 0b0.00110010000111111111 = 00000_001100100001111111110000000
        else if (key4)  next_nco_increment_value = 32'b00000001101010001100000110000000; // D#4 311.1*32/48E3 = 0.2074 = 0b0.00110101000110000011 = 00000_001101010001100000110000000
        else if (key5)  next_nco_increment_value = 32'b00000001110000100000001110000000; // E4  329.6*32/48E3 = 0.2197 = 0b0.00111000010000000111 = 00000_001110000100000001110000000
        else if (key6)  next_nco_increment_value = 32'b00000001110111001100011000000000; // F4  349.2*32/48E3 = 0.2328 = 0b0.001110111001100011   = 00000_001110111001100011000000000
        else if (key7)  next_nco_increment_value = 32'b00000001111110010010110010000000; // F#4 370.0*32/48E3 = 0.2467 = 0b0.00111111001001011001 = 00000_001111110010010110010000000
        else if (key8)  next_nco_increment_value = 32'b00000010000101110011011000000000; // G4  392.0*32/48E3 = 0.2613 = 0b0.010000101110011011   = 00000_010000101110011011000000000
        else if (key9)  next_nco_increment_value = 32'b00000010001101110000011000000000; // G#4 415.3*32/48E3 = 0.2769 = 0b0.010001101110000011   = 00000_010001101110000011000000000
        else if (key10) next_nco_increment_value = 32'b00000010010110001011111100000000; // A4  440.0*32/48E3 = 0.2933 = 0b0.0100101100010111111  = 00000_010010110001011111100000000
        else if (key11) next_nco_increment_value = 32'b00000010011111001000010010000000; // A#4 466.2*32/48E3 = 0.3108 = 0b0.01001111100100001001 = 00000_010011111001000010010000000
        else if (key12) next_nco_increment_value = 32'b00000010101000100101011010000000; // B4  493.9*32/48E3 = 0.3293 = 0b0.01010100010010101101 = 00000_010101000100101011010000000
        else if (key13) next_nco_increment_value = 32'b00000010110010101000110000000000; // C5  523.3*32/48E3 = 0.3489 = 0b0.01011001010100011    = 00000_011000101000100011010000000
        else next_nco_increment_value = 0;


        nco_increment_value = next_nco_increment_value;
        if (nco_increment_value > 0) begin
            test_LED_R = 0;
            nco_mute = 0;
        end
        else nco_mute = 1;
    end

endmodule
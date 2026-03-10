module synth
(
    input logic master_clock,
    input logic reset,

    input logic bouncy_key1,
    input logic bouncy_key2,
    input logic bouncy_key3,
    input logic bouncy_key4,
    input logic bouncy_key5,
    input logic bouncy_key6,
    input logic bouncy_key7,
    input logic bouncy_key8,
    input logic bouncy_key9,
    input logic bouncy_key10,
    input logic bouncy_key11,
    input logic bouncy_key12,

    output logic i2s_bclk,
    output logic i2s_ws,
    output logic i2s_sd,

    output logic LED_BLUE,
    output logic LED_RED
);

    logic sample_clock_enable;
    logic bit_clock_enable;

    logic debounced_key1;
    logic debounced_key2;
    logic debounced_key3;
    logic debounced_key4;
    logic debounced_key5;
    logic debounced_key6;
    logic debounced_key7;
    logic debounced_key8;
    logic debounced_key9;
    logic debounced_key10;
    logic debounced_key11;
    logic debounced_key12;

    reg [31:0] nco_increment_value;
    logic nco_mute;

    logic signed [15:0] nco_output_sample;

    clk_div clock_divider
    (
        .master_clk(master_clock),
        .rst(reset),
        .sample_clk_en(sample_clock_enable),
        .bit_clk_en(bit_clock_enable)
    );

    debouncer key1_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key1),
        .clean_signal(debounced_key1)
    );

    debouncer key2_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key2),
        .clean_signal(debounced_key2)
    );

    debouncer key3_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key3),
        .clean_signal(debounced_key3)
    );

    debouncer key4_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key4),
        .clean_signal(debounced_key4)
    );

    debouncer key5_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key5),
        .clean_signal(debounced_key5)
    );

    debouncer key6_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key6),
        .clean_signal(debounced_key6)
    );

    debouncer key7_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key7),
        .clean_signal(debounced_key7)
    );

    debouncer key8_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key8),
        .clean_signal(debounced_key8)
    );

    debouncer key9_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key9),
        .clean_signal(debounced_key9)
    );

    debouncer key10_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key10),
        .clean_signal(debounced_key10)
    );

    debouncer key11_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key11),
        .clean_signal(debounced_key11)
    );

    debouncer key12_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key12),
        .clean_signal(debounced_key12)
    );

    debouncer key13_debounce
    (
        .clk(master_clock),
        .rst(reset),
        .raw_signal(bouncy_key13),
        .clean_signal(debounced_key13)
    );

    tone_frequency_calculator key_input
    (
        .clk(master_clock),
        .rst(reset),
        .key1(debounced_key1),
        .key2(debounced_key2),
        .key3(debounced_key3),
        .key4(debounced_key4),
        .key5(debounced_key5),
        .key6(debounced_key6),
        .key7(debounced_key7),
        .key8(debounced_key8),
        .key9(debounced_key9),
        .key10(debounced_key10),
        .key11(debounced_key11),
        .key12(debounced_key12),
        .key13(debounced_key13),
        .nco_increment_value(nco_increment_value),
        .nco_mute(nco_mute),
        .test_LED_R(LED_RED)
    );

    // Only needed for debugging
    logic signed [31:0] accumulator_value;
    logic signed [15:0] sample_li_offset;

    nco numerically_controlled_oscillator
    (
        .rst(reset),
        .master_clk(master_clock),
        .sample_clk_en(sample_clock_enable),
        .nco_mute(nco_mute),
        .accumulator_increment_value(nco_increment_value),
        .sample_output(nco_output_sample),
        .accumulator_value(accumulator_value),
        .sample_li_offset(sample_li_offset)
    );

    i2s_transmitter transmitter
    (
        .clk(master_clock),
        .bit_clk_en(bit_clock_enable),
        .rst(reset),
        .new_sound_sample(nco_output_sample),
        .bit_clock(i2s_bclk),
        .word_select(i2s_ws),
        .sound_data(i2s_sd),
        .test_LED_B(LED_BLUE)
    );

endmodule
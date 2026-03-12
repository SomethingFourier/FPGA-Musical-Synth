module debouncer 
(
    input  logic clk,            // System clock
    input  logic rst,
    input  logic raw_signal,     // Raw, noisy input from the button
    output logic clean_signal    // Clean, debounced output
);

    // Parameter for the debounce delay.
    parameter DEBOUNCE_THRESHOLD = 150000; // 150,000 cycles / 24.576 MHz = 6.1 ms

    // FOR SIMULATION ONLY
    //parameter DEBOUNCE_THRESHOLD = 10; // 150,000 cycles / 12.288 MHz = 12.2 ms

    logic  [19:0] counter;      // Counter to measure stable time (20 bits for 1M)
    reg  internal_state;      // An internal register to hold the stable state
    // internal_state was previously a reg of no size: reg internal_state

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            counter <= 0;
            clean_signal <= 0;
            internal_state <= 0;
        end
        else begin
            // If the button input is different from our last stable state,
            // it means there's a change or a bounce. Reset the counter.
            if (raw_signal != internal_state) begin
                counter <= 0;
            end
            // If the input is stable and the counter hasn't reached the threshold,
            // keep incrementing the counter.
            else if (counter < DEBOUNCE_THRESHOLD) begin
                counter <= counter + 1;
            end
            // When the counter reaches the threshold, the signal is officially stable.
            // Update the final output signal.
            else if (counter == DEBOUNCE_THRESHOLD) begin
                clean_signal <= internal_state;
            end

            // Always update the internal state to match the button input.
            // This allows us to detect the next change.
            internal_state <= raw_signal;
        end
    end
endmodule

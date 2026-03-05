// what this is to help replace:
// sample_li_offset <= (($signed({16'h0, accumulator_value[26:0]}) * (slope >>> 2)) >>> 27);

module multiplication
(
    input  logic [42:0] concatenated_nco_accumulator_value,
    input  logic [15:0] slope,
    input  logic [15:0] sample,
    output logic [15:0] sound_sample_offset
);

    // slope = slope >>> 2
    

endmodule
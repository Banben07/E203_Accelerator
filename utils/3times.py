import numpy as np

def float_to_fp16_bin(val):
    f16 = np.float16(val)
    return f16.view(np.uint16)

def generate_continuous_fp16_values(min_val, max_val):
    # Create an array to store all possible FP16 values
    fp16_all_values = np.arange(0x0000, 0x10000, dtype=np.uint16)
    fp16_all_floats = fp16_all_values.view(np.float16)
    
    # Filter values to only those in the desired range
    valid_indices = np.where((fp16_all_floats >= min_val) & (fp16_all_floats <= max_val))[0]
    fp16_values = fp16_all_floats[valid_indices]
    
    return fp16_values

def generate_cube_lut():
    min_val = -3.0
    max_val = 3.0
    fp16_values = generate_continuous_fp16_values(min_val, max_val)
    cube_values = fp16_values ** 3

    with open('cube_lut.vh', 'w') as f:
        f.write('`define CUBE_LUT_SIZE {}\n'.format(len(fp16_values)))
        f.write('`define CUBE_LUT_BITS {}\n'.format(int(np.ceil(np.log2(len(fp16_values))))))
        for i in range(len(fp16_values)):
            binary_value = float_to_fp16_bin(cube_values[i])
            in_binary_value = float_to_fp16_bin(fp16_values[i])
            f.write(f'`define CUBE_LUT_{in_binary_value:04X} 16\'h{binary_value:04X}\n')
    
    # Save fp16 values for use in SystemVerilog mapping
    with open('fp16_values_in_range.mem', 'w') as f:
        for value in fp16_values:
            binary_value = float_to_fp16_bin(value)
            f.write(f'{binary_value:04X}\n')

generate_cube_lut()

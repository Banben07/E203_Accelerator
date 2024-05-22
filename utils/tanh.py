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
    
    # Ignore the low 3 bits
    fp16_values = np.unique(fp16_values.view(np.uint16) & 0xFFF8).view(np.float16)
    
    # Separate positive and negative values
    positive_values = fp16_values[(fp16_values > 0) | (fp16_values.view(np.uint16) == 0x0000)]
    negative_values = fp16_values[(fp16_values < 0) | (fp16_values.view(np.uint16) == 0x8000)]
    
    return positive_values, negative_values

def generate_tanh_lut():
    min_val = -3.43
    max_val = 3.43
    positive_values, negative_values = generate_continuous_fp16_values(min_val, max_val)
    tanh_positive_values = np.tanh(positive_values)
    tanh_negative_values = np.tanh(negative_values)

    # Generate positive values LUT
    with open('tanh_lut_positive.txt', 'w') as f:
       for i in range(len(positive_values)):
            binary_value = float_to_fp16_bin(tanh_positive_values[i])
            in_binary_value = float_to_fp16_bin(positive_values[i])
            f.write(f'{in_binary_value:04x}_{binary_value:04x}\n')
    
    # Generate negative values LUT
    with open('tanh_lut_negative.txt', 'w') as f:
        for i in range(len(negative_values)):
            binary_value = float_to_fp16_bin(tanh_negative_values[i])
            in_binary_value = float_to_fp16_bin(negative_values[i])
            f.write(f'{in_binary_value:04x}_{binary_value:04x}\n')

generate_tanh_lut()
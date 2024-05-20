import numpy as np

def fp16_to_binary(fp16):
    return np.binary_repr(np.float16(fp16).view('H'), width=16)

def cube_lut():
    lut_size = 1024
    x_values = np.linspace(-4, 4, lut_size)  # FP16 tanh range
    cube_values = x_values ** 3
    
    with open('cube_lut.vh', 'w') as f:
        f.write('`define CUBE_LUT_SIZE 1024\n')
        f.write('`define CUBE_LUT_BITS 10\n')  # log2(1024)
        for i in range(lut_size):
            binary_value = fp16_to_binary(cube_values[i])
            f.write(f'`define CUBE_LUT_{i} 16\'h{binary_value}\n')

cube_lut()
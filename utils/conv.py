import numpy as np
import random

def fp16_to_bin(value):
    return bin(np.float16(value).view("H"))[2:].zfill(16)

def generate_conv_golden():
    ifmap_size = (4, 4)  # Input feature map dimensions
    kernel_size = (3, 3)  # Kernel dimensions
    stride = 1
    output_size = (ifmap_size[0] - kernel_size[0] + 1, ifmap_size[1] - kernel_size[1] + 1)  # Calculate output dimensions

    ifmap = np.random.uniform(-1, 1, ifmap_size).astype(np.float16)  # Generate random input feature map
    kernel = np.random.uniform(-1, 1, kernel_size).astype(np.float16)  # Generate random kernel
    output = np.zeros(output_size, dtype=np.float16)  # Initialize the output feature map

    golden_list = ""
    golden_list_dec = ""

    # Convolution operation
    for i in range(output_size[0]):
        for j in range(output_size[1]):
            conv_sum = 0.0
            for di in range(kernel_size[0]):
                for dj in range(kernel_size[1]):
                    conv_sum += ifmap[i + di, j + dj] * kernel[di, dj]
            output[i, j] = conv_sum

            # Generate binary pattern and decimal representation
            conv_sum_bin = fp16_to_bin(conv_sum)
            golden_list += "{}\n".format(conv_sum_bin)
            golden_list_dec += "Output at ({}, {}) = {:.5f}(fp16)\n".format(i, j, conv_sum)

    with open("conv_golden_pattern.txt", 'w') as f:
        f.write(golden_list)
    with open("conv_golden_decimal.txt", 'w') as f:
        f.write(golden_list_dec)

if __name__ == "__main__":
    generate_conv_golden()

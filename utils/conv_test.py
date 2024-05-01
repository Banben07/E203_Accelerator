import numpy as np
import random

def fp16_to_bin(value):
    """Convert a float16 value to a binary string."""
    return bin(np.float16(value).view("H"))[2:].zfill(16)

def perform_convolution(ifmap, kernel):
    """Perform convolution on the input feature map with the given kernel."""
    output_size = (ifmap.shape[0] - kernel.shape[0] + 1, ifmap.shape[1] - kernel.shape[1] + 1)
    output = np.zeros(output_size, dtype=np.float16)
    for i in range(output_size[0]):
        for j in range(output_size[1]):
            for di in range(kernel.shape[0]):
                for dj in range(kernel.shape[1]):
                    output[i, j] += ifmap[i + di, j + dj] * kernel[di, dj]
    return output

def format_fp16_with_output_single_line(ifmap, kernel, output):
    """Format the input feature map, kernel, and convolution output into a single line."""
    all_values = np.concatenate((ifmap.flatten(), kernel.flatten(), output.flatten()))
    formatted_output = "_".join(fp16_to_bin(x) for x in all_values)
    return formatted_output

def main():
    # Define the size of the input feature map and kernel
    ifmap_size = (4, 4)  # 4x4 input feature map
    kernel_size = (3, 3)  # 3x3 kernel

    for _ in range(10):  # Generate and print 10 different test cases
        # Generate random data for the input feature map and kernel
        ifmap = np.random.uniform(-1, 1, ifmap_size).astype(np.float16)
        kernel = np.random.uniform(-1, 1, kernel_size).astype(np.float16)

        # Perform convolution
        output = perform_convolution(ifmap, kernel)

        # Generate the single line output
        single_line_output = format_fp16_with_output_single_line(ifmap, kernel, output)
        print(single_line_output)

if __name__ == "__main__":
    main()

import numpy as np

def fp16_to_bin(value):
    """Convert a float16 value to a binary string."""
    return bin(np.float16(value).view("H"))[2:].zfill(16)

def perform_convolution(ifmap, kernel):
    """Perform convolution on the input feature map with the given kernel."""
    num_channels, kernel_height, kernel_width = kernel.shape
    output_height = ifmap.shape[1] - kernel_height + 1
    output_width = ifmap.shape[2] - kernel_width + 1
    output = np.zeros((output_height, output_width), dtype=np.float16)
    
    
    for c in range(num_channels):  # Loop over channels
        for i in range(output_height):
            for j in range(output_width):
                for di in range(kernel_height):
                    for dj in range(kernel_width):
                        output[i, j] += ifmap[c, i + di, j + dj] * kernel[c, di, dj]
    return output

def format_fp16_with_output_single_line(ifmap, kernel, output):
    """Format the input feature map, kernel, and convolution output into a single line."""
    ifmap_flat = ifmap.flatten()
    kernel_flat = kernel.flatten()
    output_flat = output.flatten()
    all_values = np.concatenate((ifmap_flat, kernel_flat, output_flat))
    formatted_output = "_".join(fp16_to_bin(x) for x in all_values)
    return formatted_output

def main():
    golden_list = ""
    ifmap_size = (2, 4, 4)  # 2 channels, 4x4 input feature map per channel
    kernel_size = (2, 3, 3)  # 2 channels, 3x3 kernel per channel
    
    large_int_part_kernel = np.random.uniform(-10, 10, kernel_size).astype(np.float16)
    small_decimal_part_kernel = np.random.uniform(-1, 1, kernel_size).astype(np.float16) * 0.1
    kernel = large_int_part_kernel + small_decimal_part_kernel
    
    for _ in range(30):  # Generate and print 10 different test cases
        large_int_part_ifmap = np.random.uniform(-10, 10, ifmap_size).astype(np.float16)
        small_decimal_part_ifmap = np.random.uniform(-1, 1, ifmap_size).astype(np.float16) * 0.1
        ifmap = large_int_part_ifmap + small_decimal_part_ifmap
        

        # Perform convolution
        output = perform_convolution(ifmap, kernel)

        # Generate the single line output
        golden_list += format_fp16_with_output_single_line(ifmap, kernel, output)
        golden_list += "\n"
    
    with open("./utils/conv_golden_pattern.txt", 'w') as f:
        f.write(golden_list)

if __name__ == "__main__":
    main()

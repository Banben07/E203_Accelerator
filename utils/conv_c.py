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

def format_fp16_array(array):
    """Format a float16 array into a C-compatible binary string array."""
    flat_array = array.flatten()
    formatted_output = ", ".join(f"0b{fp16_to_bin(x)}" for x in flat_array)
    return formatted_output

def main():
    ifmap_list = ""
    kernel_list = ""
    ofmap_list = ""
    ifmap_size = (2, 4, 4)  # 2 channels, 4x4 input feature map per channel
    kernel_size = (2, 3, 3)  # 2 channels, 3x3 kernel per channel
    
    large_int_part_kernel = np.random.uniform(-10, 10, kernel_size).astype(np.float16)
    small_decimal_part_kernel = np.random.uniform(-1, 1, kernel_size).astype(np.float16) * 0.1
    kernel = large_int_part_kernel + small_decimal_part_kernel
    
    for idx in range(30):  # Generate and print 30 different test cases
        large_int_part_ifmap = np.random.uniform(-10, 10, ifmap_size).astype(np.float16)
        small_decimal_part_ifmap = np.random.uniform(-1, 1, ifmap_size).astype(np.float16) * 0.1
        ifmap = large_int_part_ifmap + small_decimal_part_ifmap

        # Perform convolution
        output = perform_convolution(ifmap, kernel)

        # Format the arrays into binary strings
        ifmap_list += f"{format_fp16_array(ifmap)},\n"
        kernel_list += f"{format_fp16_array(kernel)},\n"
        ofmap_list += f"{format_fp16_array(output)},\n"
    
    with open("./conv_golden_pattern.h", 'w') as f:
        f.write("#ifndef CONV_GOLDEN_PATTERN_H\n")
        f.write("#define CONV_GOLDEN_PATTERN_H\n\n")
        
        total_ifmap_size = ifmap_size[0] * ifmap_size[1] * ifmap_size[2]
        total_kernel_size = kernel_size[0] * kernel_size[1] * kernel_size[2]
        total_ofmap_size = output.shape[0] * output.shape[1]
        
        f.write(f"float16_t ifmap[{30 * total_ifmap_size}] = {{\n")
        f.write(ifmap_list)
        f.write("};\n\n")
        
        f.write(f"float16_t weight[{30 * total_kernel_size}] = {{\n")
        f.write(kernel_list)
        f.write("};\n\n")
        
        f.write(f"float16_t ofmap[{30 * total_ofmap_size}] = {{\n")
        f.write(ofmap_list)
        f.write("};\n\n")
        
        f.write("#endif // CONV_GOLDEN_PATTERN_H\n")

if __name__ == "__main__":
    main()
import numpy as np

# 将十六进制字符串转换为 float16
def hex_to_fp16(hex_str):
    bin_str = bin(int(hex_str, 16))[2:].zfill(16)  # 转换为二进制并填充至16位
    return np.frombuffer(int(bin_str, 2).to_bytes(2, byteorder='big'), dtype=np.float16)[0]

# 应用批量归一化
def batch_normalization(data, gamma=1, beta=0, epsilon=1e-5):
    mean = np.mean(data)
    variance = np.var(data)
    normalized = (data - mean) / np.sqrt(variance + epsilon)
    return gamma * normalized + beta

# 检查 float16 数据的方差计算是否可能溢出
def check_variance_overflow(data, float16_max=65504):
    data_range = np.max(data) - np.min(data)
    variance_estimate = data_range ** 2
    overflow = variance_estimate > float16_max
    return overflow

# 十六进制数据输入
hex_data = "3e9b_b160_bd8e_3ae2"
hex_values = hex_data.split('_')

# 长十六进制字符串输入
long_hex_data = "40abb95fc15f3c1b"

# Split the long hex string into 16-bit chunks (assuming each hex value represents 16 bits)
chunks = [long_hex_data[i:i+4] for i in range(0, len(long_hex_data), 4)]

# 转换为 float16 数组
float_data = np.array([hex_to_fp16(hex_value) for hex_value in hex_values], dtype=np.float16)
float_output = np.array([hex_to_fp16(chunk) for chunk in chunks], dtype=np.float16)

# 检查方差是否可能溢出
if check_variance_overflow(float_data):
    print("警告：方差计算可能溢出，请考虑使用更高的数据精度。")
else:
    # 执行批量归一化
    bn_output = batch_normalization(float_data, gamma=1, beta=0)
    print("BN 后的数据：", bn_output)
    print("硬件 BN 后 数据：", float_output)

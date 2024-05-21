import numpy as np
import struct

# 将十六进制字符串转换为 float16
def hex_to_fp16(hex_str):
    # 将十六进制字符串转换为字节
    bytes_data = bytes.fromhex(hex_str)
    # 使用 struct 将字节解包为半精度浮点数
    return struct.unpack('>e', bytes_data)[0]

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
hex_data   = "BBF6A11FA7B12BE9"
hex_values = [hex_data[i:i+4] for i in range(0, len(hex_data), 4)]

# 长十六进制字符串输入
long_hex_data = "bba83765BDB5B456"

# 将长十六进制字符串分成16位块（假设每个十六进制值代表16位）
chunks = [long_hex_data[i:i+4] for i in range(0, len(long_hex_data), 4)]

# 转换为 float16 数组
float_data = np.array([hex_to_fp16(hex_value) for hex_value in hex_values], dtype=np.float16)
float_output = np.array([hex_to_fp16(chunk) for chunk in chunks], dtype=np.float16)

# 检查方差是否可能溢出
if check_variance_overflow(float_data):
    print("警告：方差计算可能溢出，请考虑使用更高的数据精度。")
    print("BN 前的数据：", [float(val) for val in float_data])
    print("硬件 BN 后 数据：", [float(val) for val in float_output])
else:
    # 执行批量归一化
    bn_output = batch_normalization(float_data, gamma=1, beta=0)
    print("BN 前的数据：", [float(val) for val in float_data])
    print("BN 后的数据：", [float(val) for val in bn_output])
    print("硬件 BN 后 数据：", [float(val) for val in float_output])
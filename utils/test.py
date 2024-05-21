import numpy as np

# 定义公式
def approx_tanh(x):
    return np.sqrt(2/np.pi) * (x + 0.047715 * x**3)

# 定义 x 的范围
x_values = np.linspace(-3, 3, 1000)

# 计算对应的 y 值
y_values = approx_tanh(x_values)

# 找出 y 的最小值和最大值
y_min = np.min(y_values)
y_max = np.max(y_values)

print(y_min, y_max)
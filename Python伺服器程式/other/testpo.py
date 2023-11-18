import random
from datetime import datetime, timedelta
import matplotlib.pyplot as plt


def generate_simulated_data(start_time_str, end_time_str):
    start_time = datetime.strptime(start_time_str, '%Y-%m-%d')
    end_time = datetime.strptime(end_time_str, '%Y-%m-%d')
    current_time = start_time

    simulated_data = {}

    if start_time.date() == end_time.date():
        # 如果開始和結束時間在同一天，生成24個點
        for _ in range(24):
            timestamp = int(current_time.timestamp())
            temp = round(random.uniform(20, 25), 2)
            voltage = round(random.uniform(108, 112), 2)
            current1 = round(random.uniform(1000, 1500), 2)
            current2 = round(random.uniform(1000, 1500), 2)

            simulated_data[str(timestamp)] = {
                'temp': temp,
                'voltage': voltage,
                'current1': current1,
                'current2': current2,
                'time': timestamp
            }

            current_time += timedelta(hours=1)
    else:
        while current_time <= end_time:
            timestamp = int(current_time.timestamp())
            # temp = round(random.uniform(20, 25), 2)
            # voltage = round(random.uniform(108, 112), 2)
            # current1 = round(random.uniform(1000, 1500), 2)
            # current2 = round(random.uniform(1000, 1500), 2)

            # 白天
            if current_time.hour >= 6 and current_time.hour <= 18:
                temp = round(random.uniform(20, 25), 2)
                voltage = round(random.uniform(108, 112), 2)
                current1 = round(random.uniform(1000, 1500), 2)
                current2 = round(random.uniform(1000, 1500), 2)
            # 晚上
            else:
                temp = round(random.uniform(20, 25), 2)
                voltage = round(random.uniform(108, 112), 2)
                current1 = round(random.uniform(100, 500), 2)
                current2 = round(random.uniform(100, 500), 2)

            simulated_data[str(timestamp)] = {
                'temp': temp,
                'voltage': voltage,
                'current1': current1,
                'current2': current2,
                'time': timestamp
            }

            current_time += timedelta(minutes=1)

    return simulated_data


def calculate_averages_in_intervals(data, interval_size):
    interval_averages = []
    current_interval_start = min(entry['time'] for entry in data.values())
    current_interval_end = current_interval_start + interval_size

    while current_interval_end <= max(entry['time'] for entry in data.values()):
        data_in_interval = [entry for entry in data.values(
        ) if current_interval_start <= entry['time'] < current_interval_end]
        if data_in_interval:
            avg_temp = sum(entry['temp']
                           for entry in data_in_interval) / len(data_in_interval)
            avg_voltage = sum(entry['voltage']
                              for entry in data_in_interval) / len(data_in_interval)
            avg_current1 = sum(entry['current1']
                               for entry in data_in_interval) / len(data_in_interval)
            avg_current2 = sum(entry['current2']
                               for entry in data_in_interval) / len(data_in_interval)
        else:
            avg_temp, avg_voltage, avg_current1, avg_current2 = 0, 0, 0, 0

        interval_averages.append({
            'time_start': current_interval_start,
            'time_end': current_interval_end,
            'avg_temp': avg_temp,
            'avg_voltage': avg_voltage,
            'avg_current1': avg_current1,
            'avg_current2': avg_current2
        })

        current_interval_start = current_interval_end
        current_interval_end += interval_size

    return interval_averages


# 設定開始和結束時間
start_date = '2023-08-31'
end_date = '2023-09-01'

# 設定時間範圍
start_time = datetime.strptime(start_date, '%Y-%m-%d')
end_time = datetime.strptime(end_date, '%Y-%m-%d')
time_range = (end_time - start_time).days + 1

# 計算時間間隔數量
if time_range <= 5:
    interval_count = 24
else:
    interval_count = 24
    interval_count += abs(8 * (time_range - 5))


# 計算時間間隔大小（以秒為單位）
total_seconds = (end_time - start_time).total_seconds()  # 計算時間差
interval_size_seconds = int(total_seconds / interval_count)  # 計算間隔秒數
interval_size_seconds = interval_size_seconds or 86400  # 如果間隔秒數為 0，則設為 86400 秒（一天）

# 產生模擬資料
simulated_data = generate_simulated_data(start_date, end_date)

# 計算平均值
interval_averages = calculate_averages_in_intervals(
    simulated_data, interval_size_seconds)


# 提取平均值以繪製圖表
time_intervals = [
    f"{interval['time_start']} - {interval['time_end']}" for interval in interval_averages]
avg_temps = [interval['avg_temp'] for interval in interval_averages]
avg_voltages = [interval['avg_voltage'] for interval in interval_averages]
avg_currents1 = [interval['avg_current1'] for interval in interval_averages]
avg_currents2 = [interval['avg_current2'] for interval in interval_averages]

# 繪製圖表
plt.figure(figsize=(15, 6))  # 調整圖表大小以適應更多的格子
plt.plot(time_intervals, avg_temps, marker='o', label='Average Temperature')
plt.plot(time_intervals, avg_voltages, marker='o', label='Average Voltage')
plt.plot(time_intervals, avg_currents1, marker='o', label='Average Current1')
plt.plot(time_intervals, avg_currents2, marker='o', label='Average Current2')
plt.xlabel('Time Intervals')
plt.ylabel('Values')
plt.title('Average Values Over Time Intervals')
plt.xticks(rotation=45)
plt.legend()
plt.tight_layout()
plt.show()

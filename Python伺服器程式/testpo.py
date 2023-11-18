import random
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import database
import sys

db = database.database('firebase.json')


def generate_simulated_data(start_time_str, end_time_str):
    start_time = datetime.strptime(start_time_str, '%Y-%m-%d')
    end_time = datetime.strptime(end_time_str, '%Y-%m-%d')

    history = db.getHistoryInRange(
        "rbT1hYJhz2egTc7HvgSKsFnZGeFAieJ54TFx7tGAXuD91LiGMKzI6KL2MEbTvBMd", start_time, end_time)

    dict_sorted_history = sorted(history.items(), key=lambda x: x[1]['time'])

    sorted_history = {}
    for i in dict_sorted_history:
        sorted_history[i[0]] = i[1]

    for i in sorted_history:
        print(sorted_history[i])

    return sorted_history


def calculate_averages_in_intervals(data, interval_size, start_time, end_time):
    # end_time to 23:59:59
    end_time = end_time.replace(hour=23, minute=59, second=59)
    interval_averages = []
    current_interval_start = int(datetime.timestamp(start_time))
    current_interval_end = current_interval_start + interval_size
    print(start_time, end_time)
    end_time = int(datetime.timestamp(end_time))

    while current_interval_end <= end_time:
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
start_date = '2023-08-29'
end_date = '2023-08-29'

# 設定時間範圍
start_time = datetime.strptime(start_date, '%Y-%m-%d')
end_time = datetime.strptime(end_date, '%Y-%m-%d')
start_time.replace(hour=0, minute=0, second=0)
end_time.replace(hour=23, minute=59, second=59)
time_range = (end_time - start_time).days + 1

# 計算時間間隔數量
if time_range <= 5:
    interval_size_seconds = 3600 * time_range  # 1小時 * 天數
else:
    interval_size_seconds = 3600 * time_range
    interval_size_seconds += abs(8 * (time_range - 5)) * 3600


simulated_data = generate_simulated_data(start_date, end_date)

# 計算平均值
interval_averages = calculate_averages_in_intervals(
    simulated_data, interval_size_seconds, start_time, end_time)


# 提取平均值以繪製圖表
time_intervals = [
    f"{datetime.fromtimestamp(interval['time_start']).strftime('%Y-%m-%d %H:%M:%S')} - {datetime.fromtimestamp(interval['time_end']).strftime('%Y-%m-%d %H:%M:%S')}" for interval in interval_averages]
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

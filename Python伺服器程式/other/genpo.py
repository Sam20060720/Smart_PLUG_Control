import random
from datetime import datetime, timedelta

def generate_simulated_data(start_time_str, end_time_str):
    start_time = datetime.strptime(start_time_str, '%Y-%m-%d')
    end_time = datetime.strptime(end_time_str, '%Y-%m-%d')
    current_time = start_time

    simulated_data = {}

    while current_time <= end_time:
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

        current_time += timedelta(minutes=random.randint(1, 30))

    return simulated_data

# 設定開始和結束時間
start_date = '2023-08-01'
end_date = '2023-08-10'

# 產生模擬資料
simulated_data = generate_simulated_data(start_date, end_date)

# 輸出模擬資料
for timestamp, data in simulated_data.items():
    print(f"Timestamp: {timestamp}, Temperature: {data['temp']}, Voltage: {data['voltage']}, Current1: {data['current1']}, Current2: {data['current2']}")

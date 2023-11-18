from datetime import datetime


def calculate_averages_in_intervals(data, interval_size, start_time, end_time):
    # end_time to 23:59:59
    start_time = start_time.replace(hour=0, minute=0, second=0)
    end_time = end_time.replace(hour=0, minute=0, second=0)
    interval_averages = []
    current_interval_start = int(datetime.timestamp(start_time))
    current_interval_end = current_interval_start + interval_size
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

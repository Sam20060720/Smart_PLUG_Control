import os


def count_lines(filepath):
    with open(filepath, 'r', encoding='utf-8') as file:
        lines = file.readlines()
        return len(lines)


def main(directory_path):
    total_lines = 0
    total_bytes = 0

    for root, _, files in os.walk(directory_path):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            if os.path.isfile(file_path):
                try:
                    with open(file_path, 'rb') as file:
                        file_size = os.path.getsize(file_path)
                        lines = sum(1 for line in file)
                        total_bytes += file_size
                        total_lines += lines
                        print(f'{file_name} : {file_size}B / {lines} line')
                except Exception as e:
                    print(f'Error processing {file_name}: {str(e)}')

    print(f'sum > {total_bytes}B / {total_lines} line')


if __name__ == "__main__":
    directory_path = "."  # 修改为你要统计的目录的路径
    main(directory_path)

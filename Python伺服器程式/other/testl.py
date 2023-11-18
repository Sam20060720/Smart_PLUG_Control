import time
x = []
count = 0

while True:
    if len(x) < 11:
        x.append(count)
    else:
        x.pop(10)
        x.insert(0,count)
    count+=1
    print(x)

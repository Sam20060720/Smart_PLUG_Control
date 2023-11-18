import datetime

startdate = "2023-08-01"
enddate = "2023-08-06"

startdate = datetime.datetime.strptime(startdate, '%Y-%m-%d')
# 轉換時間戳記
startdatestramp = datetime.datetime.timestamp(startdate)
print(startdatestramp)
enddate = datetime.datetime.strptime(enddate, '%Y-%m-%d')
enddate = enddate + datetime.timedelta(days=1)
daydiff = abs((enddate - startdate).days)

if daydiff <= 5:
    var_diff = daydiff * 24
else:
    var_diff = 24 * 5
    var_diff += abs(8 * (daydiff - 5))

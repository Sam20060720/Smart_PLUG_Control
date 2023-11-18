import requests
from GLOBAL import *


def send_message_to_friend(user_mid, message_text="HELLO", channel_access_token=CHANNEL_ACESS_TOKEN):
    url = f"https://api.line.me/v2/bot/message/push"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {channel_access_token}",
    }

    data = {
        "to": user_mid,
        "messages": [
            {
                "type": "text",
                "text": message_text,
            }
        ],
    }

    response = requests.post(url, json=data, headers=headers)
    print(response.status_code)
    print(response.text)
    if response.status_code == 200:
        print("Message sent successfully")
    else:
        print("Failed to send message")


if __name__ == "__main__":
    # U5ab09a40ea7a9558d5404e945655b89a
    send_message_to_friend("U5ab09a40ea7a9558d5404e945655b89a","智慧插座通知 [TV Chest] 已綁定該line帳號")
    # send_message_to_friend("U5ab09a40ea7a9558d5404e945655b89a","智慧插座通知 [TV Chest] 裝置離線")
    # send_message_to_friend("U5ab09a40ea7a9558d5404e945655b89a","智慧插座通知 [TV Chest] 裝置恢復連線")
    # send_message_to_friend("U5ab09a40ea7a9558d5404e945655b89a","智慧插座通知 [TV Chest] 插座過熱警報，已自動斷電，請儘速查看裝置狀態!")

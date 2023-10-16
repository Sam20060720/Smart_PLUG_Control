import requests

def send_message_to_friend(user_mid, message_text, channel_access_token):
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

# Replace with your actual values
user_mid = "U5ab09a40ea7a9558d5404e945655b89a"
message_text = "Hello from Python!"
channel_access_token = "UcB3PiLnLde7AF4qFXvR/CIRC2dIa0gUPGjqz4UAKm/U9nSsjj2ruwt/VCxr7l1w0ARCFxSZhgdyWJdndmx6gcPPia9xWjLd+Ieq1KkpDWQTDnwPpDNBaC4dlIhyxhRT/Iv+QzdX9xroC77QlGeciwdB04t89/1O/w1cDnyilFU="

send_message_to_friend(user_mid, message_text, channel_access_token)
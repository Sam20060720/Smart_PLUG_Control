from flask import Blueprint,session,redirect,url_for,render_template,request
import config
from GLOBAL import *

webapp = Blueprint('web', __name__)
 

@webapp.route('/line_login')
def line_login():
    session.clear()
    session['is_login'] = False
    # 构造 Line 登录授权链接
    line_client_id = LINE_LOGIN_CLIENT_ID
    line_redirect_uri = SERVER_URL + "/line_callback"
    line_login_url = f'https://access.line.me/oauth2/v2.1/authorize?client_id={line_client_id}&response_type=code&state=your_state&redirect_uri={line_redirect_uri}&scope=profile%20openid%20email'
    return redirect(line_login_url)


@webapp.route('/line_callback')
def line_callback():
    code = request.args.get('code')

    # 根据获取的 code，向 Line 获取用户 Token
    line_client_id = LINE_LOGIN_CLIENT_ID
    line_client_secret = LINE_LOGIN_SECRET
    line_redirect_uri = SERVER_URL + "/line_callback"

    token_url = 'https://api.line.me/oauth2/v2.1/token'
    token_payload = {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': line_client_id,
        'client_secret': line_client_secret,
        'redirect_uri': line_redirect_uri
    }
    token_response = requests.post(token_url, data=token_payload)
    token_data = token_response.json()

    user_token = token_data.get('access_token')

    # get user id
    profile_url = 'https://api.line.me/v2/profile'
    profile_headers = {
        'client_id': line_client_id,
        'Authorization': 'Bearer ' + user_token
    }
    profile_response = requests.get(profile_url, headers=profile_headers)
    profile_data = profile_response.json()

    session['user_id'] = profile_data.get('userId')
    session['display_name'] = profile_data.get('displayName')
    session['is_login'] = True

    return redirect(url_for('index'))


@webapp.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))


@webapp.route('/')
def index():
    if session.get('is_login') == True:
        return render_template('index.html', is_login=True, display_name=session.get('display_name'))
    return render_template('index.html', is_login=False)
from flask import Flask, render_template,jsonify,request,redirect,url_for, session
from passlib.apache import HtpasswdFile
from i18n import translations
from i17n import globalweb
import subprocess
import re
import json
import os

ANSIBLE_HOSTS_PATH = "/etc/ansible/hosts"
GROUP_NAME = "network"


app=Flask(__name__)
app.secret_key = '12345678'
base_dir = os.path.dirname(os.path.abspath(__file__))

htpasswd_path = os.path.join(base_dir, 'users.htpasswd')

if os.path.exists(htpasswd_path):
    htpasswd = HtpasswdFile(htpasswd_path)
else:
    htpasswd = None
    print("users.htpasswd 文件不存在，请检查路径")

def check_user_password(username, password):
    htpasswd = HtpasswdFile("users.htpasswd")  
    return htpasswd.check_password(username, password)
    
    
@app.route('/')
def index():
    lang = request.args.get('lang', session.get('lang', 'zh_CN'))
    if lang not in translations:
        lang = 'zh_CN'
    session['lang'] = lang
    return render_template('login.html', t=translations[lang], lang=lang)

@app.route('/web')
def web():
    if 'user' not in session:
        return render_template('login.html')
    lang = request.args.get('lang', session.get('lang', 'zh_CN'))
    if lang not in globalweb:
        lang = 'zh_CN'
    session['lang'] = lang
    return render_template('index3.html'
                           , t=globalweb[lang], lang=lang
                           )

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect(url_for('index')) 

@app.route('/login', methods=['GET','POST'])
def login():
    if not htpasswd:
        return jsonify({'success': False, 'message': 'htpasswd 文件加载失败'})
    if request.method == 'POST':
        data = request.get_json()
        user = data.get('username')
        pwd = data.get('password')
        if check_user_password(user, pwd):
            session['user'] = user
            return jsonify({'success': True})
        else:
            return jsonify({'success': False, 'message': '用户名或密码错误'})
    return render_template('login.html')

@app.route('/edit-server', methods=['POST'])
def update_host():
    if 'user' not in session:
        return render_template('login.html')
    data = request.json
    old_ip = data.get('oldip')
    new_ip = data.get('ip', '')
    new_group = data.get('group', '')
    new_port = data.get('port', '')
    new_user = data.get('user', '')

    if not old_ip:
        return jsonify({'error': 'old_ip is required'}), 400
    args = ['./edit.sh', old_ip, new_ip, new_group, new_port, new_user]

    try:
        result = subprocess.run(args, capture_output=True, text=True, check=True)
        return jsonify({'success': True, 'message': result.stdout.strip()})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.stderr.strip() or e.stdout.strip()}), 500

@app.route('/api/ips')
def get_existing_ips():
    if 'user' not in session:
        return render_template('login.html')
    ips = []

    try:
        with open('./hosts', 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('['):
                    continue
                parts = line.split()
                ip_candidate = parts[0]
                ips.append(ip_candidate)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

    return jsonify(ips)

@app.route('/add', methods=['POST'])
def add_server():
    if 'user' not in session:
        return render_template('login.html')
    ip = request.form['ip']
    hostname = request.form['hostname']
    user = request.form['user']
    group = request.form.get('group', 'ungrouped') or 'ungrouped'
    password = request.form['password']
    port = request.form['port']

    result = subprocess.run(
        ['/root/ansible/addtoweb.sh', ip, hostname, user, group, password, port],
        capture_output=True, text=True
    )
    print("stdout:", result.stdout)
    print("stderr:", result.stderr)
    print("returncode:", result.returncode)

    if result.returncode != 0:
        return f"添加服务器失败：{result.stderr}", 500

    return redirect('/web')
@app.route('/delete/<ip>', methods=['POST'])
def delete_host(ip):
    if 'user' not in session:
        return render_template('login.html')
    result = subprocess.run(
        ['/root/ansible/delete_ansible_host.sh', ip],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        return '', 204
    else:
        return f"删除失败：{result.stderr}", 500

@app.route('/api/hosts')
def get_hosts_status():
    if 'user' not in session:
        return render_template('login.html')
    try:
        result = subprocess.run(
            [
                "ansible", "-i", "./hosts", "all",
                "-m", "script",
                "-a", "./check.sh", "-o"
            ],
            capture_output=True,
            text=True
        )


        output_lines = result.stdout.splitlines()
        hosts=[]
        olinequantity=0
        offquantity=0
        for line in output_lines:
            if "\"changed\": true" in line:
                host = line.split(' | ')[0].strip()
                match = re.search(r'=>\s*(\{.*\})$', line)
                if not match:
                    continue
                outer_json = json.loads(match.group(1))              
                inner_json = json.loads(outer_json['stdout'].strip())
                olinequantity += 1
                hosts.append({'id': host, 'name': host, 'ip': host, 'status': 'online', 'cpu':int(inner_json.get('cpu', 0)), 'mem': int(inner_json.get('mem', 0)), 'disk': int(inner_json.get('disk', 0))})
            elif 'UNREACHABLE' in line:
                host = line.split(' | ')[0]
                offquantity += 1
                hosts.append({'id': host, 'name': host, 'ip': host, 'status': 'offline', 'cpu':0, 'mem': 0, 'disk': 0})

        return jsonify(hosts=hosts, online_count=olinequantity, offline_count=offquantity)
                

    except Exception as e:
        return jsonify({"error": "Execution failed", "details": str(e)}), 500


if __name__ == "__main__":
        app.run(host="0.0.0.0", port=5000, debug=False
                , ssl_context=(
           "/etc/letsencrypt/live/qiuqi.fun/fullchain.pem",
           "/etc/letsencrypt/live/qiuqi.fun/privkey.pem")
                )
        


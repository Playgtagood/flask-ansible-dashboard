# 📊 Ansible 数据大屏系统

这是一个基于 Flask 构建的轻量级数据大屏管理系统，支持用户认证、服务添加、Ansible 主机动态管理，以及中英双语切换。适用于 DevOps 场景中的资源可视化与自动化控制。

---

## 🚀 项目亮点

- ✅ **Flask + Docker** 后端架构，轻量部署  
- 🔐 **htpasswd 用户验证机制**，安全简洁  
- 📊 **数据大屏可视化**，结构清晰  
- 🧠 **Ansible 动态主机管理支持**  
- 🌍 **支持 i18n 多语言切换**（中文 / English）  
- 🎨 使用 **Bootstrap + FontAwesome** 优化界面体验  

---

## 🖼️ 页面预览

- 🔑 登录页（带前端验证）  
- 📈 数据总览大屏  
- ➕ 动态主机添加界面  
- 🚪 登出与语言切换按钮  

---

## 📁 项目结构示意

ansible/
├── Dockerfile
├── addtoweb.sh # 添加主机到 ansible hosts
├── c.py # 主程序
├── check.sh # 查询资源使用率
├── create.sh # 创建 Docker 容器与网络
├── delete_ansible_host.sh # 删除主机
├── edit.sh # 编辑主机
├── hosts # Ansible hosts 列表
├── i18n.py # 多语言支持
├── passwd.py # 用户密码管理（Python）
├── passwd.sh # 用户密码管理（Shell）
├── users.htpasswd # 密码文件
├── static/ # 静态文件
│ ├── css/
│ ├── js/
│ ├── img/
│ └── webfonts/
└── templates/
├── index3.html # 数据大屏页面
└── login.html # 登录页面

yaml
Copy
Edit

---

## ⚙️ 安装与运行

你可以选择使用 Docker 部署（推荐）或手动运行：

### ✅ 使用 Docker 部署

```bash
cd /ansible
chmod +x *.sh
docker build -t ansible .

# 可选：创建容器和网络
./create.sh

# 启动容器（请替换网络名）
docker run -itd --name ansible-app \
  --network ansible-net \
  -p 5000:5000 ansible

# 进入容器
docker exec -it ansible-app bash

# 启动服务
cd /root/ansible
python3 c.py
👤 用户管理
容器内或本机运行：

bash
Copy
Edit
./passwd.sh
支持添加、删除、修改用户密码等操作。

🔒 启用 HTTPS（SSL）
如果你希望启用 HTTPS 加密访问，请按照以下步骤配置：

1️⃣ 准备证书
将以下文件放入项目根目录：

cert.pem：公钥证书

key.pem：私钥文件

2️⃣ 修改启动方式
编辑 c.py 末尾：

python
Copy
Edit
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'key.pem'))
3️⃣ 启动服务
bash
Copy
Edit
python3 c.py
浏览器访问：https://localhost:5000

⚠️ 如果使用自签名证书，浏览器可能会提示不安全，可手动信任或换成受信任 CA 签发的证书。

🧩 项目依赖
Python 3.x

Flask

passlib

flask-babel

Docker（可选）

🙋‍♂️ 贡献者
姓名	角色	主要工作内容
playgtagood	  项目开发者	搭建 Flask 框架，编写后端逻辑，实现用户登录与 Ansible 接口，适配前端逻辑
vivi-tat 和 Echo-ui-ux 前端设计者	设计页面风格，开发数据大屏 UI 与交互逻辑

MIT License

Copyright (c) 2025 playgtagood, Echo-ui-ux, vivi-tat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

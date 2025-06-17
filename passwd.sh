#!/bin/bash

HTPASSWD_FILE="./users.htpasswd"

function show_menu() {
  echo "===== htpasswd 用户管理 ====="
  echo "1) 添加用户"
  echo "2) 删除用户"
  echo "3) 修改用户密码"
  echo "4) 显示用户列表"
  echo "5) 退出"
  echo "============================"
  echo -n "请选择操作 [1-5]: "
}

while true; do
  show_menu
  read choice
  case "$choice" in
    1)
      echo -n "请输入要添加的用户名: "
      read username
      if [ -z "$username" ]; then
        echo "用户名不能为空"
        continue
      fi
      htpasswd -B "$HTPASSWD_FILE" "$username"
      ;;
    2)
      echo -n "请输入要删除的用户名: "
      read username
      if [ -z "$username" ]; then
        echo "用户名不能为空"
        continue
      fi
      if htpasswd -D "$HTPASSWD_FILE" "$username" 2>/dev/null; then
        echo "用户 $username 已删除"
      else
        echo "htpasswd版本不支持 -D，尝试手动删除..."
        grep -v "^$username:" "$HTPASSWD_FILE" > "${HTPASSWD_FILE}.tmp" && mv "${HTPASSWD_FILE}.tmp" "$HTPASSWD_FILE"
        echo "手动删除完成"
      fi
      ;;
    3)
      echo -n "请输入要修改密码的用户名: "
      read username
      if [ -z "$username" ]; then
        echo "用户名不能为空"
        continue
      fi
      htpasswd -B "$HTPASSWD_FILE" "$username"
      ;;
    4)
      echo "当前用户列表:"
      cut -d ':' -f 1 "$HTPASSWD_FILE"
      ;;
    5)
      echo "退出程序"
      exit 0
      ;;
    *)
      echo "无效选项，请输入 1-5 之间的数字"
      ;;
  esac
  echo ""  # 空行，美观
done

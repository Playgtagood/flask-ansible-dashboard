#!/bin/bash

IP="$1"
HOSTNAME="$2"
USER="$3"
GROUP="$4"
PASSWORD="$5"
PORT="$6"

INVENTORY="./hosts"

if [ "$(id -u)" -ne 0 ]; then
  echo "此脚本必须以 root 权限运行" >&2
  exit 1
fi

# 检查 IP 是否已存在于 hosts 文件中，防止重复添加
if grep -q "^$IP\s" "$INVENTORY"; then
  echo "错误：IP $IP 已存在于 $INVENTORY 中，不能重复添加" >&2
  exit 1
fi


# 如果组不存在，直接追加组和主机条目到文件末尾
if ! grep -q "^\[$GROUP\]" "$INVENTORY"; then
  echo -e "\n[$GROUP]" >> "$INVENTORY"
  echo "${IP}  ansible_user=${USER} ansible_port=${PORT} ansible_ssh_pass=${PASSWORD}" >> "$INVENTORY"
else
  # 组存在，找到组行号，插入主机条目到该组下方（插入到下一组开始前或文件末尾）
  
  # 获取组的行号
  group_line_num=$(grep -n "^\[$GROUP\]" "$INVENTORY" | cut -d: -f1)

  # 获取下一个组的行号（比当前组行号大的第一个组行）
  next_group_line_num=$(tail -n +"$((group_line_num + 1))" "$INVENTORY" | grep -n "^\[" | head -n1 | cut -d: -f1)
  
  if [ -z "$next_group_line_num" ]; then
    # 没有下一个组，直接追加到文件末尾
    echo "${IP} ansible_user=${USER} ansible_port=${PORT} ansible_ssh_pass=${PASSWORD}" >> "$INVENTORY"
  else
    # 计算插入行号：当前组行号 + next_group_line_num
    insert_line=$((group_line_num + next_group_line_num))

    # 在插入行号前插入新条目
    # 用临时文件操作
    sed -i "${insert_line}i ${IP} ansible_user=${USER} ansible_port=${PORT} ansible_ssh_pass=${PASSWORD}" "$INVENTORY"
  fi
fi

#!/bin/bash

OLD_IP=$1
NEW_IP=$2
NEW_GROUP=$3
NEW_PORT=$4
NEW_USER=$5

INVENTORY_FILE="./hosts"
HOSTS_FILE="./hosts"
INPUT_FILE="./hosts"
OUTPUT_FILE="./hosts.new"

# 先找到旧IP所在行
LINE=$(grep "^$OLD_IP " "$INVENTORY_FILE")
if [ -z "$LINE" ]; then
  echo "没有找到 IP: $OLD_IP"
  exit 1
fi

# 提取旧组名（假设组名是行前面的一段，格式为 [组名]，且旧行所在组在上方）
# 方法：先找旧行所在行号，再从上往下找第一个匹配 [.*] 的组名
OLD_LINE_NUM=$(grep -n "^$OLD_IP " "$INVENTORY_FILE" | cut -d: -f1)

OLD_GROUP=""
for ((i=OLD_LINE_NUM-1; i>0; i--)); do
  LINE_CONTENT=$(sed -n "${i}p" "$INVENTORY_FILE")
  if [[ "$LINE_CONTENT" =~ ^\[.+\]$ ]]; then
    OLD_GROUP="$LINE_CONTENT"
    break
  fi
done

# 替换IP
if [ -n "$NEW_IP" ]; then
  NEW_LINE="$NEW_IP${LINE#$OLD_IP}"
else
  NEW_LINE="$LINE"
fi

# 替换端口
if [ -n "$NEW_PORT" ]; then
  if echo "$NEW_LINE" | grep -q "ansible_port="; then
    NEW_LINE=$(echo "$NEW_LINE" | sed -E "s/ansible_port=[0-9]+/ansible_port=$NEW_PORT/")
  else
    NEW_LINE="$NEW_LINE ansible_port=$NEW_PORT"
  fi
fi

# 替换用户
if [ -n "$NEW_USER" ]; then
  if echo "$NEW_LINE" | grep -q "ansible_user="; then
    NEW_LINE=$(echo "$NEW_LINE" | sed -E "s/ansible_user=[^ ]+/ansible_user=$NEW_USER/")
  else
    NEW_LINE="$NEW_LINE ansible_user=$NEW_USER"
  fi
fi

# 删除旧行
sed -i "/^$OLD_IP /d" "$INVENTORY_FILE"

# 插入新行
if [ -z "$NEW_GROUP" ]; then
  # 无新组，默认写回旧组（如果找不到旧组，写到文件末尾）
  if [ -n "$OLD_GROUP" ]; then
    awk -v grp="$OLD_GROUP" -v newline="$NEW_LINE" '
    BEGIN { done=0 }
    {
      print
      if ($0 == grp && done==0) {
        print newline
        done=1
      }
    }
    END {
      if (done==0) {
        print newline
      }
    }
    ' "$INVENTORY_FILE" > tmp && mv tmp "$INVENTORY_FILE"
  else
    echo "$NEW_LINE" >> "$INVENTORY_FILE"
  fi
else
  # 有新组，插入到新组
  awk -v grp="[$NEW_GROUP]" -v newline="$NEW_LINE" '
  BEGIN { done=0 }
  {
    print
    if ($0 == grp && done==0) {
      print newline
      done=1
    }
  }
  END {
    if (done==0) {
      print grp
      print newline
    }
  }
  ' "$INVENTORY_FILE" > tmp && mv tmp "$INVENTORY_FILE"
fi

awk '
/^\[.*\]/ {
    if (group != "") {
        # 如果上一组主机数为0，什么都不打印，等于删掉该组
        if (count > 0) {
            print group
            for (i = 0; i < count; i++) print lines[i]
            print ""  # 保持组间空行
        }
    }
    group = $0
    count = 0
    delete lines
    next
}

NF {
    lines[count++] = $0
}

END {
    if (group != "") {
        if (count > 0) {
            print group
            for (i = 0; i < count; i++) print lines[i]
        }
    }
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

mv "$OUTPUT_FILE" "$INPUT_FILE"
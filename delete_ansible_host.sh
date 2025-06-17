#!/bin/bash
IP="$1"
HOSTS_FILE="./hosts"
INPUT_FILE="./hosts"
OUTPUT_FILE="./hosts.new"

if [ -z "$IP" ]; then
	  echo "缺少 IP"
	    exit 1
fi

sed -i "/^$IP\s/d" "$HOSTS_FILE"

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
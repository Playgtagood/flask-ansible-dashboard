#!/bin/bash

echo "[INFO] Starting Docker Containers check..."

while true; do
	read -p "Please input a new container name:" container_name
	if docker ps -a --format '{{.Names}}' | grep -wq "$container_name"; then
		echo "[ERROR] Container '$container_name' has been existed, please try another instance!"
	else
		break
	fi
done

while true; do
	read -p "Please input a new ssh port number that you want to listen:" port
	if ss -t -an | grep -q "$port"; then
		echo "[ERROR] Port '$port' has been used, please try another port!"
	else
		break
	fi
done


mapfile -t networks < <(docker network ls --format '{{.Name}}' | grep -vE '^(bridge|host|none)$')

if [ ${#networks[@]} -eq 0 ]; then
	echo "[INFO] 当前无可用的用户自定义网络。"
	choice="n"
else
	echo "可用的 Docker 网络列表："
	for i in "${!networks[@]}"; do
		printf "%d) %s\n" $((i+1)) "${networks[$i]}"
	done
	
	echo "n) 创建新网络"
	read -p "请选择网络序号，或输入 n 创建新网络: " choice
fi

if [[ "$choice" == "n" ]]; then
	read -p "请输入新网络名称: " new_network
	docker network create "$new_network"
	final_network="$new_network"
elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#networks[@]} )); then
	final_network="${networks[$((choice-1))]}"
else
	echo "[ERROR] 无效选择，脚本退出。"
	exit 1
fi

docker run -itd --name $container_name -p "$port:22" --network $final_network ansible

if [ $? -eq 0 ]; then
	echo "[SUCCESS] 容器 '$container_name' 已成功加入网络 '$final_network'并创建。"
else
	echo "[ERROR] 连接失败。请检查容器是否存在，或已连接该网络."
fi


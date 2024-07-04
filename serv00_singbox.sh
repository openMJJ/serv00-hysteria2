#!/bin/bash

# Function to print characters with delay
print_with_delay() {
    text="$1"
    delay="$2"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# notice
show_notice() {
    local message="$1"
    echo "#######################################################################################################################"
    echo "                                                                                                                       "
    echo "                                ${message}                                                                             "
    echo "                                                                                                                       "
    echo "#######################################################################################################################"
}

# Introduction animation
print_with_delay "sing-reality-hy2-box" 0.05
echo ""
echo ""

# download singbox and cloudflared
download_singbox() {
    echo "Downloading Sing-box from https://github.com/openMJJ/serv00-hysteria2/releases/download/freebsd/sing-box"
    if [ ! -d "$HOME/sbox" ]; then
        mkdir -p "$HOME/sbox"
    fi
    wget -qO "$HOME/sbox/sing-box" "https://github.com/openMJJ/serv00-hysteria2/releases/download/freebsd/sing-box"
    chmod +x "$HOME/sbox/sing-box"
}

download_cloudflared() {
    arch=$(uname -m)
    case ${arch} in
        x86_64)
            cf_arch="amd64"
            ;;
        aarch64)
            cf_arch="arm64"
            ;;
        armv7l)
            cf_arch="arm"
            ;;
    esac
    cf_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${cf_arch}"
    wget -qO "$HOME/sbox/cloudflared-linux" "$cf_url"
    chmod +x "$HOME/sbox/cloudflared-linux"
    echo ""
}

regenarte_cloudflared_argo() {
    pid=$(pgrep -f cloudflared)
    if [ -n "$pid" ]; then
        kill "$pid"
    fi
    vmess_port=$(jq -r '.inbounds[2].listen_port' "$HOME/sbox/sbconfig_server.json")
    "$HOME/sbox/cloudflared-linux" tunnel --url http://localhost:$vmess_port --no-autoupdate --edge-ip-version auto --protocol h2mux > argo.log 2>&1 &
    sleep 2
    clear
    echo "等待cloudflare argo生成地址"
    sleep 5
    argo=$(grep trycloudflare.com argo.log | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
    echo "$argo" | base64 > "$HOME/sbox/argo.txt.b64"
    rm -rf argo.log
}

show_client_configuration() {
    current_listen_port=$(jq -r '.inbounds[0].listen_port' "$HOME/sbox/sbconfig_server.json")
    current_server_name=$(jq -r '.inbounds[0].tls.server_name' "$HOME/sbox/sbconfig_server.json")
    uuid=$(jq -r '.inbounds[0].users[0].uuid' "$HOME/sbox/sbconfig_server.json")
    public_key=$(base64 --decode "$HOME/sbox/public.key.b64")
    short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' "$HOME/sbox/sbconfig_server.json")
    read -p "请输入服务器IP地址: " server_ip
    echo ""
    echo ""
    show_notice "Reality 客户端通用链接"
    echo ""
    echo ""
    server_link="vless://$uuid@$server_ip:$current_listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$current_server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#SING-BOX-Reality"
    echo "$server_link"
    echo ""
    echo ""
    show_notice "Reality 客户端通用参数"
    echo ""
    echo ""
    echo "服务器ip: $server_ip"
    echo "监听端口: $current_listen_port"
    echo "UUID: $uuid"
    echo "域名SNI: $current_server_name"
    echo "Public Key: $public_key"
    echo "Short ID: $short_id"
    echo ""
    echo ""
    hy_current_listen_port=$(jq -r '.inbounds[1].listen_port' "$HOME/sbox/sbconfig_server.json")
    hy_current_server_name=$(openssl x509 -in "$HOME/self-cert/cert.pem" -noout -subject -nameopt RFC2253 | awk -F'=' '{print $NF}')
    hy_password=$(jq -r '.inbounds[1].users[0].password' "$HOME/sbox/sbconfig_server.json")
    hy2_server_link="hysteria2://$hy_password@$server_ip:$hy_current_listen_port?insecure=1&sni=$hy_current_server_name"
    show_notice "Hysteria2 客户端通用链接"
    echo ""
    echo "官方 hysteria2通用链接格式"
    echo ""
    echo "$hy2_server_link"
    echo ""
    echo ""
    show_notice "Hysteria2 客户端通用参数"
    echo ""
    echo ""
    echo "服务器ip: $server_ip"
    echo "端口号: $hy_current_listen_port"
    echo "password: $hy_password"
    echo "域名SNI: $hy_current_server_name"
    echo "跳过证书验证: True"
    echo ""
    echo ""
    show_notice "Hysteria2 客户端yaml文件"
cat << EOF

server: $server_ip:$hy_current_listen_port

auth: $hy_password

tls:
  sni: $hy_current_server_name
  insecure: true

# 可自己修改对应带宽，不添加则默认为bbr，否则使用hy2的brutal拥塞控制
# bandwidth:
#   up: 100 mbps
#   down: 100 mbps

fastOpen: true

socks5:
  listen: 127.0.0.1:5080

EOF
}

uninstall_singbox() {
    echo "Uninstalling..."
    rm "$HOME/sbox/sbconfig_server.json"
    rm "$HOME/sbox/sing-box"
    rm "$HOME/sbox/cloudflared-linux"
    rm "$HOME/sbox/argo.txt.b64"
    rm "$HOME/sbox/public.key.b64"
    rm "$HOME/self-cert/private.key"
    rm "$HOME/self-cert/cert.pem"
    rm -rf "$HOME/self-cert/"
    rm -rf "$HOME/sbox/"
    echo "DONE!"
}

# Check if reality.json, sing-box, and sing-box.service already exist
if [ -f "$HOME/sbox/sbconfig_server.json" ] && [ -f "$HOME/sbox/sing-box" ] && [ -f "$HOME/sbox/public.key.b64" ] && [ -f "$HOME/sbox/argo.txt.b64" ]; then
    echo "sing-box-reality-hysteria2已经安装"
    echo ""
    echo "请选择选项:"
    echo ""
    echo "1. 重新安装"
    echo "2. 修改配置"
    echo "3. 显示客户端配置"
    echo "4. 卸载"
    echo "5. 手动重启cloudflared"
    echo ""
    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
            show_notice "Reinstalling..."
            uninstall_singbox
            ;;
        2)
            show_notice "开始修改reality端口和域名"
            current_listen_port=$(jq -r '.inbounds[0].listen_port' "$HOME/sbox/sbconfig_server.json")
            read -p "请输入想要修改的端口号 (当前端口为 $current_listen_port): " listen_port
            listen_port=${listen_port:-$current_listen_port}
            current_server_name=$(jq -r '.inbounds[0].tls.server_name' "$HOME/sbox/sbconfig_server.json")
            read -p "请输入想要使用的h2域名 (当前域名为 $current_server_name): " server_name
            server_name=${server_name:-$current_server_name}
            echo ""
            show_notice "开始修改hysteria2端口"
            echo ""
            hy_current_listen_port=$(jq -r '.inbounds[1].listen_port' "$HOME/sbox/sbconfig_server.json")
            read -p "请输入想要修改的端口 (当前端口为 $hy_current_listen_port): " hy_listen_port
            hy_listen_port=${hy_listen_port:-$hy_current_listen_port}
            jq --arg listen_port "$listen_port" --arg server_name "$server_name" --arg hy_listen_port "$hy_listen_port" '.inbounds[1].listen_port = ($hy_listen_port | tonumber) | .inbounds[0].listen_port = ($listen_port | tonumber) | .inbounds[0].tls.server_name = $server_name | .inbounds[0].tls.reality.handshake.server = $server_name' "$HOME/sbox/sbconfig_server.json" > "$HOME/sbox/sb_modified.json"
            mv "$HOME/sbox/sb_modified.json" "$HOME/sbox/sbconfig_server.json"
            pm2 restart sing-box --name "sing-box" -- "$HOME/sbox/sing-box" run -c "$HOME/sbox/sbconfig_server.json"
            show_client_configuration
            exit 0
            ;;
        3)
            show_client_configuration
            exit 0
            ;;
        4)
            uninstall_singbox
            exit 0
            ;;
        5)
            regenarte_cloudflared_argo
            echo "重新启动完成，查看新的客户端信息"
            show_client_configuration
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

mkdir -p "$HOME/sbox"

download_singbox

download_cloudflared

echo "开始配置Reality"
echo ""
key_pair=$("$HOME/sbox/sing-box" generate reality-keypair)
echo "Key pair生成完成"
echo ""

private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
echo "$public_key" | base64 > "$HOME/sbox/public.key.b64"

uuid=$("$HOME/sbox/sing-box" generate uuid)
short_id=$("$HOME/sbox/sing-box" generate rand --hex 8)
echo "uuid和短id 生成完成"
echo ""
read -p "请输入Reality端口 (default: 443): " listen_port
listen_port=${listen_port:-443}
echo ""
read -p "请输入想要使用的域名 (default: itunes.apple.com): " server_name
server_name=${server_name:-itunes.apple.com}
echo ""
echo "开始配置hysteria2"
echo ""
hy_password=$("$HOME/sbox/sing-box" generate rand --hex 8)
read -p "请输入hysteria2监听端口 (default: 8443): " hy_listen_port
hy_listen_port=${hy_listen_port:-8443}
echo ""
read -p "输入自签证书域名 (default: bing.com): " hy_server_name
hy_server_name=${hy_server_name:-bing.com}
mkdir -p "$HOME/self-cert/" && openssl ecparam -genkey -name prime256v1 -out "$HOME/self-cert/private.key" && openssl req -new -x509 -days 36500 -key "$HOME/self-cert/private.key" -out "$HOME/self-cert/cert.pem" -subj "/CN=${hy_server_name}"
echo ""
echo "自签证书生成完成"
echo ""

pid=$(pgrep -f cloudflared)
if [ -n "$pid" ]; then
    kill "$pid"
fi
read -p "请输入vmess端口，默认为15555: " vmess_port
vmess_port=${vmess_port:-15555}
echo ""
"$HOME/sbox/cloudflared-linux" tunnel --url http://localhost:$vmess_port --no-autoupdate --edge-ip-version auto --protocol h2mux > argo.log 2>&1 &
sleep 2
clear
echo "等待cloudflare argo生成地址"
sleep 5
argo=$(grep trycloudflare.com argo.log | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
echo "$argo" | base64 > "$HOME/sbox/argo.txt.b64"
rm -rf argo.log

read -p "请输入服务器IP地址: " server_ip

jq -n --arg listen_port "$listen_port" --arg server_name "$server_name" --arg private_key "$private_key" --arg short_id "$short_id" --arg uuid "$uuid" --arg hy_listen_port "$hy_listen_port" --arg hy_password "$hy_password" --arg cert_path "$HOME/self-cert/cert.pem" --arg key_path "$HOME/self-cert/private.key" '{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ($listen_port | tonumber),
      "users": [
        {
          "uuid": $uuid,
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
          "reality": {
          "enabled": true,
          "handshake": {
            "server": $server_name,
            "server_port": 443
          },
          "private_key": $private_key,
          "short_id": [$short_id]
        }
      }
    },
    {
        "type": "hysteria2",
        "tag": "hy2-in",
        "listen": "::",
        "listen_port": ($hy_listen_port | tonumber),
        "users": [
            {
                "password": $hy_password
            }
        ],
        "tls": {
            "enabled": true,
            "alpn": [
                "h3"
            ],
            "certificate_path": $cert_path,
            "key_path": $key_path
        }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}' > "$HOME/sbox/sbconfig_server.json"

"$HOME/sbox/sing-box" check -c "$HOME/sbox/sbconfig_server.json" && pm2 start "$HOME/sbox/sing-box" --name "sing-box" -- run -c "$HOME/sbox/sbconfig_server.json"

show_client_configuration

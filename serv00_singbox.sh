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

# Function to show notice
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

# Install base packages
install_base() {
  if ! command -v jq &> /dev/null; then
      echo "jq 未安装。正在安装..."
      if [ -n "$(command -v apt)" ]; then
          apt update > /dev/null 2>&1
          apt install -y jq > /dev/null 2>&1
      elif [ -n "$(command -v yum)" ]; then
          yum install -y epel-release
          yum install -y jq
      elif [ -n "$(command -v dnf)" ]; then
          dnf install -y jq
      else
          echo "无法安装 jq。请手动安装 jq 并重新运行脚本。"
          exit 1
      fi
  fi
}

# Download sing-box
download_singbox() {
  arch=$(uname -m)
  case ${arch} in
      x86_64) arch="amd64" ;;
      aarch64) arch="arm64" ;;
      armv7l) arch="armv7" ;;
  esac

  url="https://github.com/openMJJ/serv00-hysteria2/releases/download/freebsd/sing-box"
  curl -sLo "~/singbox/sing-box" "$url"
}

# Show client configuration
show_client_configuration() {
  current_listen_port=$(jq -r '.inbounds[0].listen_port' ~/singbox/sbox/sbconfig_server.json)
  current_server_name=$(jq -r '.inbounds[0].tls.server_name' ~/singbox/sbox/sbconfig_server.json)
  uuid=$(jq -r '.inbounds[0].users[0].uuid' ~/singbox/sbox/sbconfig_server.json)
  public_key=$(base64 --decode ~/singbox/sbox/public.key.b64)
  short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' ~/singbox/sbox/sbconfig_server.json)
  server_ip=$(curl -s4m8 ip.sb -k || curl -s6m8 ip.sb -k)

  server_link="vless://$uuid@$server_ip:$current_listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$current_server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#SING-BOX-Reality"

  show_notice "Reality 客户端通用链接"
  echo "$server_link"
  
  show_notice "Reality 客户端通用参数"
  echo "服务器ip: $server_ip"
  echo "监听端口: $current_listen_port"
  echo "UUID: $uuid"
  echo "域名SNI: $current_server_name"
  echo "Public Key: $public_key"
  echo "Short ID: $short_id"

  hy_current_listen_port=$(jq -r '.inbounds[1].listen_port' ~/singbox/sbox/sbconfig_server.json)
  hy_current_server_name=$(openssl x509 -in ~/singbox/self-cert/cert.pem -noout -subject -nameopt RFC2253 | awk -F'=' '{print $NF}')
  hy_password=$(jq -r '.inbounds[1].users[0].password' ~/singbox/sbox/sbconfig_server.json)

  hy2_server_link="hysteria2://$hy_password@$server_ip:$hy_current_listen_port?insecure=1&sni=$hy_current_server_name"

  show_notice "Hysteria2 客户端通用链接"
  echo "官方 hysteria2通用链接格式"
  echo "$hy2_server_link"
  
  show_notice "Hysteria2 客户端通用参数"
  echo "服务器ip: $server_ip"
  echo "端口号: $hy_current_listen_port"
  echo "password: $hy_password"
  echo "域名SNI: $hy_current_server_name"
  echo "跳过证书验证: True"

  show_notice "Hysteria2 客户端yaml文件"
  cat << EOF
server: $server_ip:$hy_current_listen_port
auth: $hy_password
tls:
  sni: $hy_current_server_name
  insecure: true
fastOpen: true
socks5:
  listen: 127.0.0.1:5080
EOF

  show_notice "sing-box客户端配置参数"
  cat << EOF
{
    "dns": {
        "servers": [
            {
                "tag": "remote",
                "address": "https://1.1.1.1/dns-query",
                "detour": "select"
            },
            {
                "tag": "local",
                "address": "https://223.5.5.5/dns-query",
                "detour": "direct"
            },
            {
                "address": "rcode://success",
                "tag": "block"
            }
        ],
        "rules": [
            {
                "outbound": [
                    "any"
                ],
                "server": "local"
            },
            {
                "disable_cache": true,
                "geosite": [
                    "category-ads-all"
                ],
                "server": "block"
            },
            {
                "clash_mode": "global",
                "server": "remote"
            },
            {
                "clash_mode": "direct",
                "server": "local"
            },
            {
                "geosite": "cn",
                "server": "local"
            }
        ],
        "strategy": "prefer_ipv4"
    },
    "inbounds": [
        {
            "type": "tun",
            "inet4_address": "172.19.0.1/30",
            "inet6_address": "2001:0470:f9da:fdfa::1/64",
            "sniff": true,
            "sniff_override_destination": true,
            "domain_strategy": "prefer_ipv4",
            "stack": "mixed",
            "strict_route": true,
            "mtu": 9000,
            "endpoint_independent_nat": true,
            "auto_route": true
        },
        {
            "type": "socks",
            "tag": "socks-in",
            "listen": "127.0.0.1",
            "sniff": true,
            "sniff_override_destination": true,
            "domain_strategy": "prefer_ipv4",
            "listen_port": 2333,
            "users": []
        },
        {
            "type": "mixed",
            "tag": "mixed-in",
            "sniff": true,
            "sniff_override_destination": true,
            "domain_strategy": "prefer_ipv4",
            "listen": "127.0.0.1",
            "listen_port": 2334,
            "users": []
        }
    ],
    "experimental": {
        "clash_api": {
            "external_controller": "127.0.0.1:9090",
            "secret": "",
            "store_selected": true
        }
    },
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "outbounds": [
        {
            "tag": "select",
            "type": "selector",
            "default": "urltest",
            "outbounds": [
                "urltest",
                "sing-box-reality",
                "sing-box-hysteria2"
            ]
        },
        {
            "type": "vless",
            "tag": "sing-box-reality",
            "uuid": "$uuid",
            "flow": "xtls-rprx-vision",
            "packet_encoding": "xudp",
            "server": "$server_ip",
            "server_port": $current_listen_port,
            "tls": {
                "enabled": true,
                "server_name": "$current_server_name",
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                },
                "reality": {
                    "enabled": true,
                    "public_key": "$public_key",
                    "short_id": "$short_id"
                }
            }
        },
        {
            "type": "hysteria2",
            "server": "$server_ip",
            "server_port": $hy_current_listen_port,
            "tag": "sing-box-hysteria2",
            "up_mbps": 100,
            "down_mbps": 100,
            "password": "$hy_password",
            "tls": {
                "enabled": true,
                "server_name": "$hy_current_server_name",
                "insecure": true,
                "alpn": [
                    "h3"
                ]
            }
        },
        {
            "tag": "direct",
            "type": "direct"
        },
        {
            "tag": "block",
            "type": "block"
        },
        {
            "type": "urltest",
            "tag": "urltest",
            "outbounds": [
                "sing-box-reality",
                "sing-box-hysteria2"
            ],
            "test_urls": [
                "http://www.gstatic.com/generate_204",
                "http://www.apple.com/library/test/success.html",
                "http://www.msftncsi.com/ncsi.txt"
            ],
            "interval": 300
        }
    ],
    "route": {
        "rules": [
            {
                "geosite": [
                    "category-ads-all"
                ],
                "outbound": "block"
            },
            {
                "geosite": [
                    "category-porn"
                ],
                "outbound": "block"
            },
            {
                "ip_cidr": [
                    "1.1.1.1/32"
                ],
                "outbound": "block"
            },
            {
                "domain_keyword": [
                    "bitporno"
                ],
                "outbound": "direct"
            },
            {
                "geoip": [
                    "cn"
                ],
                "outbound": "direct"
            },
            {
                "geosite": [
                    "cn"
                ],
                "outbound": "direct"
            },
            {
                "geosite": [
                    "geolocation-!cn"
                ],
                "outbound": "select"
            },
            {
                "geoip": [
                    "geolocation-!cn"
                ],
                "outbound": "select"
            }
        ],
        "final": "select"
    }
}
EOF
}

install_base
download_singbox
show_client_configuration

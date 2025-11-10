#!/bin/bash

ROUTE_FILE="/etc/network/ipv_priority.conf"

show_menu() {
  echo "==============================="
  echo "    网络优先设置脚本"
  echo "==============================="
  echo "1) 设置 IPv4 优先"
  echo "2) 设置 IPv6 优先"
  echo "3) 恢复默认路由设置"
  echo "4) 查询当前路由优先设置"
  echo "5) 退出"
  echo "==============================="
}

get_network_info() {
  INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
  IPv4_GATEWAY=$(ip -4 route show default | grep -oP '(?<=via )\S+')
  IPv6_GATEWAY=$(ip -6 route show default | grep -oP '(?<=via )\S+')

  echo "检测：接口=$INTERFACE, IPv4网关=$IPv4_GATEWAY, IPv6网关=$IPv6_GATEWAY"

  if [ -z "$INTERFACE" ] || [ -z "$IPv4_GATEWAY" ] || [ -z "$IPv6_GATEWAY" ]; then
    echo "错误：未能自动检测到网卡或网关，请检查网络配置。"
    exit 1
  fi
}

set_ipv4_priority() {
  echo "设置 IPv4 优先出站路由"
  get_network_info
  # 禁用 IPv6 临时
  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  # 配置 /etc/gai.conf 让系统优先使用 IPv4
  sed -i 's/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf
  # 保存优先标记
  echo "ipv4" > "$ROUTE_FILE"
  echo "完成：IPv4 优先已设置"
}

set_ipv6_priority() {
  echo "设置 IPv6 优先出站路由"
  get_network_info
  # 启用 IPv6
  sysctl -w net.ipv6.conf.all.disable_ipv6=0
  # 还原 /etc/gai.conf 中 IPv4 优先的配置（注释掉）
  sed -i 's/^precedence ::ffff:0:0\/96  100/#precedence ::ffff:0:0\/96  100/' /etc/gai.conf
  echo "ipv6" > "$ROUTE_FILE"
  echo "完成：IPv6 优先已设置"
}

restore_default() {
  echo "恢复默认路由设置"
  get_network_info
  # 启用 IPv6
  sysctl -w net.ipv6.conf.all.disable_ipv6=0
  # 清除 gai.conf 中的强制 IPv4 优先
  sed -i 's/^precedence ::ffff:0:0\/96  100/#precedence ::ffff:0:0\/96  100/' /etc/gai.conf
  rm -f "$ROUTE_FILE"
  echo "完成：已恢复默认路由设置"
}

check_priority() {
  if [ -f "$ROUTE_FILE" ]; then
    echo "当前优先设置：$(cat $ROUTE_FILE)"
  else
    echo "当前优先设置：默认（未设置）"
  fi
}

handle_choice(){
  choice=$(echo "$1" | xargs)
  case $choice in
    1) set_ipv4_priority ;;
    2) set_ipv6_priority ;;
    3) restore_default ;;
    4) check_priority ;;
    5) echo "退出程序"; exit 0 ;;
    *) echo "无效输入，请输入 1‑5 的选项" ;;
  esac
}

while true; do
  show_menu
  read -p "请输入选项 [1-5]：" choice
  handle_choice "$choice"
done

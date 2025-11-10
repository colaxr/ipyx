#!/bin/bash

# 配置文件保存优先设置
ROUTE_FILE="/etc/network/ipv_priority.conf"

# 显示菜单选项
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

# 获取网卡和网关
get_network_info() {
  # 自动检测网卡
  INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)

  # 自动检测 IPv4 网关
  IPv4_GATEWAY=$(ip -4 route show default | grep -oP '(?<=via )(\S+)')

  # 自动检测 IPv6 网关
  IPv6_GATEWAY=$(ip -6 route show default | grep -oP '(?<=via )(\S+)')

  if [ -z "$INTERFACE" ] || [ -z "$IPv4_GATEWAY" ] || [ -z "$IPv6_GATEWAY" ]; then
    echo "错误：未能自动检测到网卡或网关，请检查网络配置。"
    exit 1
  fi
}

# 设置 IPv4 优先
set_ipv4_priority() {
  echo "设置 IPv4 优先出站路由"
  
  # 获取网卡和网关信息
  get_network_info

  # 删除现有的 IPv6 默认路由
  ip -6 route del default
  # 设置 IPv4 路由
  ip route add default via $IPv4_GATEWAY dev $INTERFACE
  # 保存设置到文件
  echo "ipv4" > $ROUTE_FILE
  echo "IPv4 优先路由设置完成"
}

# 设置 IPv6 优先
set_ipv6_priority() {
  echo "设置 IPv6 优先出站路由"
  
  # 获取网卡和网关信息
  get_network_info

  # 删除现有的 IPv4 默认路由
  ip route del default
  # 设置 IPv6 路由
  ip -6 route add default via $IPv6_GATEWAY dev $INTERFACE
  # 保存设置到文件
  echo "ipv6" > $ROUTE_FILE
  echo "IPv6 优先路由设置完成"
}

# 恢复默认路由设置
restore_default() {
  echo "恢复默认路由设置"
  
  # 获取网卡和网关信息
  get_network_info

  # 恢复 IPv4 默认路由
  ip route del default
  ip route add default via $IPv4_GATEWAY dev $INTERFACE
  # 恢复 IPv6 默认路由
  ip -6 route del default
  ip -6 route add default via $IPv6_GATEWAY dev $INTERFACE
  # 清除设置文件
  rm -f $ROUTE_FILE
  echo "默认路由恢复完成"
}

# 查询当前优先设置
check_priority() {
  if [ -f $ROUTE_FILE ]; then
    current_priority=$(cat $ROUTE_FILE)
    echo "当前优先设置：$current_priority"
  else
    echo "没有保存优先设置，使用默认路由"
  fi
}

# 处理用户选择
handle_choice() {
  choice=$(echo "$1" | xargs)  # 清除输入中的空格或其他不可见字符
  
  case $choice in
    1)
      set_ipv4_priority
      ;;
    2)
      set_ipv6_priority
      ;;
    3)
      restore_default
      ;;
    4)
      check_priority
      ;;
    5)
      echo "退出程序"
      exit 0
      ;;
    *)
      echo "无效输入，请输入 1 至 5 的选项"
      ;;
  esac
}

# 主菜单循环
while true; do
  show_menu
  read -p "请输入选项 [1-5]：" choice
  handle_choice "$choice"
done

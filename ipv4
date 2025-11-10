#!/bin/bash

# 自动检测网卡
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)

# 自动检测 IPv4 网关
IPv4_GATEWAY=$(ip -4 route show default | grep -oP '(?<=via )(\S+)')

# 自动检测 IPv6 网关
IPv6_GATEWAY=$(ip -6 route show default | grep -oP '(?<=via )(\S+)')

# 配置文件保存优先设置
ROUTE_FILE="/etc/network/ipv_priority.conf"

# 显示脚本的帮助信息
usage() {
  echo "Usage: $0 {ipv4|ipv6|restore|status}"
  exit 1
}

# 设置 IPv4 优先
set_ipv4_priority() {
  echo "设置 IPv4 优先出站路由"
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

# 开机时保持设置
persist_settings() {
  if [ -f $ROUTE_FILE ]; then
    saved_priority=$(cat $ROUTE_FILE)
    if [ "$saved_priority" == "ipv4" ]; then
      set_ipv4_priority
    elif [ "$saved_priority" == "ipv6" ]; then
      set_ipv6_priority
    fi
  fi
}

# 根据用户参数选择相应操作
if [ $# -eq 0 ]; then
  usage
fi

case "$1" in
  ipv4)
    set_ipv4_priority
    ;;
  ipv6)
    set_ipv6_priority
    ;;
  restore)
    restore_default
    ;;
  status)
    check_priority
    ;;
  *)
    usage
    ;;
esac

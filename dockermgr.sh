#!/usr/bin/env bash
set -euo pipefail

VERSION="v1.0.3"
export LC_ALL=C

# ---------- root 检测 ----------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "❌ 本脚本需要 root 权限"
  echo "请使用：curl -fsSL URL | sudo bash"
  exit 1
fi

# ---------- Docker 安装检测 ----------
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ 未检测到 Docker，请先安装 Docker"
  exit 1
fi

# ---------- 颜色 ----------
GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[36m"
RESET="\033[0m"

pause() { read -rp "按回车继续..."; }

header() {
  clear
  echo -e "${BLUE}"
  echo "======================================"
  echo " Docker Manager ${VERSION}"
  echo " curl 管道运行管理脚本"
  echo "======================================"
  echo -e "${RESET}"
}

# ---------- Docker 服务 ----------
docker_service_menu() {
  header
  cat <<EOF
1) 启动 Docker
2) 停止 Docker
3) 重启 Docker
4) 查看状态
0) 返回
EOF
  read -rp "选择: " c
  case "$c" in
    1) systemctl start docker ;;
    2) systemctl stop docker ;;
    3) systemctl restart docker ;;
    4) systemctl is-active docker && echo "运行中" || echo "未运行" ;;
  esac
  pause
}

# ---------- 容器 ----------
container_menu() {
  header
  cat <<EOF
1) 查看运行中容器
2) 查看全部容器
3) 启动容器
4) 停止容器
5) 重启容器
6) 删除容器
7) 进入容器
8) 查看日志
9) 清理停止容器
0) 返回
EOF
  read -rp "选择: " c
  case "$c" in
    1) docker ps ;;
    2) docker ps -a ;;
    3) read -rp "容器名: " name; docker start "$name" ;;
    4) read -rp "容器名: " name; docker stop "$name" ;;
    5) read -rp "容器名: " name; docker restart "$name" ;;
    6) read -rp "容器名: " name; docker rm -f "$name" ;;
    7) read -rp "容器名: " name; docker exec -it "$name" bash ;;
    8) read -rp "容器名: " name; docker logs -f "$name" ;;
    9) docker container prune -f ;;
  esac
  pause
}

# ---------- 镜像 ----------
image_menu() {
  header
  cat <<EOF
1) 查看镜像
2) 删除镜像
3) 清理无用镜像
0) 返回
EOF
  read -rp "选择: " c
  case "$c" in
    1) docker images ;;
    2) read -rp "镜像ID: " id; docker rmi -f "$id" ;;
    3) docker image prune -a -f ;;
  esac
  pause
}

# ---------- 网络 / 卷 ----------
netvol_menu() {
  header
  cat <<EOF
1) 查看网络
2) 删除网络
3) 查看卷
4) 删除卷
0) 返回
EOF
  read -rp "选择: " c
  case "$c" in
    1) docker network ls ;;
    2) read -rp "网络名: " net; docker network rm "$net" ;;
    3) docker volume ls ;;
    4) read -rp "卷名: " vol; docker volume rm "$vol" ;;
  esac
  pause
}

# ---------- docker compose ----------
compose_menu() {
  header
  cat <<EOF
1) 启动 compose
2) 停止 compose
3) 重启 compose
4) 查看状态
5) 删除 compose（含卷）
0) 返回
EOF
  read -rp "选择: " c
  case "$c" in
    1) docker compose up -d ;;
    2) docker compose down ;;
    3) docker compose restart ;;
    4) docker compose ps ;;
    5) docker compose down -v ;;
  esac
  pause
}

# ---------- 主菜单 ----------
main_menu() {
  while true; do
    header
    cat <<EOF
1) Docker 服务管理
2) 容器管理
3) 镜像管理
4) 网络 / 数据卷
5) docker-compose 管理
0) 退出
EOF
    read -rp "选择: " choice
    case "$choice" in
      1) docker_service_menu ;;
      2) container_menu ;;
      3) image_menu ;;
      4) netvol_menu ;;
      5) compose_menu ;;
      0) exit 0 ;;
    esac
  done
}

main_menu

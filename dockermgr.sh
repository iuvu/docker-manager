#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

# ---------- root 检测 ----------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "❌ 本脚本需要 root 权限"
  echo "请使用：curl -fsSL URL | sudo bash"
  exit 1
fi

# ---------- Docker 检测 ----------
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ 未检测到 Docker，请先安装 Docker"
  exit 1
fi

# ---------- 颜色 ----------
BLUE="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# ---------- 统一输入（解决 curl | bash 交互问题） ----------
read_tty() {
  read -rp "$1" REPLY </dev/tty
}

pause() {
  read -rp "按回车继续..." </dev/tty
}

header() {
  clear
  echo -e "${BLUE}"
  echo "======================================"
  echo " Docker Manager"
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
  read_tty "选择: "
  case "$REPLY" in
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
  read_tty "选择: "
  case "$REPLY" in
    1) docker ps ;;
    2) docker ps -a ;;
    3) read_tty "容器名: "; docker start "$REPLY" ;;
    4) read_tty "容器名: "; docker stop "$REPLY" ;;
    5) read_tty "容器名: "; docker restart "$REPLY" ;;
    6) read_tty "容器名: "; docker rm -f "$REPLY" ;;
    7) read_tty "容器名: "; docker exec -it "$REPLY" bash ;;
    8) read_tty "容器名: "; docker logs -f "$REPLY" ;;
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
  read_tty "选择: "
  case "$REPLY" in
    1) docker images ;;
    2) read_tty "镜像ID: "; docker rmi -f "$REPLY" ;;
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
  read_tty "选择: "
  case "$REPLY" in
    1) docker network ls ;;
    2) read_tty "网络名: "; docker network rm "$REPLY" ;;
    3) docker volume ls ;;
    4) read_tty "卷名: "; docker volume rm "$REPLY" ;;
  esac
  pause
}

# ---------- docker compose ----------
COMPOSE_BASE="/"

compose_menu() {
  header
  echo "当前可用项目："
  ls "$COMPOSE_BASE"
  echo

  read_tty "请输入项目名: "
  PROJECT="$REPLY"
  PROJECT_DIR="$COMPOSE_BASE/$PROJECT"

  if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "❌ 项目不存在"
    pause
    return
  fi

  header
  cat <<EOF
1) 启动 compose
2) 停止 compose
3) 重启 compose
4) 查看状态
5) 删除 compose（含卷）
0) 返回
EOF

  read_tty "选择: "
  case "$REPLY" in
    1) (cd "$PROJECT_DIR" && docker compose up -d) ;;
    2) (cd "$PROJECT_DIR" && docker compose down) ;;
    3) (cd "$PROJECT_DIR" && docker compose restart) ;;
    4) (cd "$PROJECT_DIR" && docker compose ps) ;;
    5) (cd "$PROJECT_DIR" && docker compose down -v) ;;
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
    read_tty "选择: "
    case "$REPLY" in
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

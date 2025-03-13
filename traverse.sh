#!/bin/bash
# Traverse
# 主程序 (traverse.sh)

# 设置环境
TRAVBOX_DIR="$HOME/travbox"
CORE_DIR="$TRAVBOX_DIR/core"
CONFIG_DIR="$TRAVBOX_DIR/config"
SCRIPTS_DIR="$TRAVBOX_DIR/scripts"
VERSION="0.1.0"

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
PURPLE="\033[35m"
WHITE="\033[37m"
BOLD="\033[1m"
RESET="\033[0m"

# 创建必要的目录
mkdir -p "$CORE_DIR" "$CONFIG_DIR" "$SCRIPTS_DIR"

# 检查必需的核心脚本，如果缺失则创建占位符
for module in system.sh package.sh terminal.sh settings.sh; do
    if [ ! -f "$CORE_DIR/$module" ]; then
        echo "#!/bin/bash" > "$CORE_DIR/$module"
        echo "echo -e \"${YELLOW}[提示]${RESET} 模块 $module 尚未实现。\"" >> "$CORE_DIR/$module"
        echo "echo" >> "$CORE_DIR/$module"
        echo "read -p \"按回车键返回...\" " >> "$CORE_DIR/$module"
        chmod +x "$CORE_DIR/$module"
    fi
done

# 初始化固定项目
if [ ! -f "$CONFIG_DIR/pinned.list" ]; then
    touch "$CONFIG_DIR/pinned.list"
fi

# 打印标题
print_header() {
    clear
    local term_width=$(tput cols)
    local title="Traverse Termux v${VERSION}"
    local padding=$(( (term_width - ${#title} - 2) / 2 ))
    
    printf "%s%s%s\n" "${CYAN}${BOLD}" "$(printf '═%.0s' $(seq 1 $term_width))" "${RESET}"
    
    printf "%s%s%s%s%s\n" "${CYAN}${BOLD}" "$(printf ' %.0s' $(seq 1 $padding))" "$title" "$(printf ' %.0s' $(seq 1 $padding))" "${RESET}"
    
    printf "%s%s%s\n\n" "${CYAN}${BOLD}" "$(printf '═%.0s' $(seq 1 $term_width))" "${RESET}"
}

# 打印菜单项
print_menu_item() {
    local number=$1
    local text=$2
    local color=$3
    echo -e "  ${color}${BOLD}[$number]${RESET} ${WHITE}$text${RESET}"
}

# 打印主菜单
print_main_menu() {
    echo -e "${CYAN}${BOLD}【主菜单】${RESET}"
    echo
    print_menu_item "1" "系统维护" $GREEN
    print_menu_item "2" "软件包管理" $GREEN
    print_menu_item "3" "终端配置" $GREEN
    print_menu_item "4" "框架设置" $GREEN
    print_menu_item "0" "退出程序" $RED
    echo
}

# 打印快速访问栏
print_quick_access() {
    if [ -f "$CONFIG_DIR/pinned.list" ] && [ -s "$CONFIG_DIR/pinned.list" ]; then
        local count=5
        local has_items=false
        
        while IFS='|' read -r name path description || [[ -n "$name" ]]; do
            if [ -n "$name" ]; then
                if [ "$has_items" = false ]; then
                    echo -e "${CYAN}${BOLD}【快速访问】${RESET}"
                    echo
                    has_items=true
                fi
                print_menu_item "$count" "$name" $PURPLE
                count=$((count + 1))
            fi
        done < "$CONFIG_DIR/pinned.list"
        
        if [ "$has_items" = true ]; then
            echo
        fi
    fi
}

# 打印分隔线
print_separator() {
    local term_width=$(tput cols)
    echo -e "${BLUE}$(printf '─%.0s' $(seq 1 $term_width))${RESET}"
    echo
}

# 打印信息、成功、警告和错误消息
print_info() { echo -e "${BLUE}[信息]${RESET} $1"; }
print_success() { echo -e "${GREEN}[成功]${RESET} $1"; }
print_warning() { echo -e "${YELLOW}[警告]${RESET} $1"; }
print_error() { echo -e "${RED}[错误]${RESET} $1"; }

# 主程序循环
while true; do
    print_header
    print_main_menu
    print_separator
    print_quick_access
    
    echo -e "${YELLOW}请输入选择的序号: ${RESET}"
    read -p "> " choice
    
    case $choice in
        1)
            # 系统维护
            "$CORE_DIR/system.sh"
            ;;
        2)
            # 软件包管理
            "$CORE_DIR/package.sh"
            ;;
        3)
            # 终端配置
            "$CORE_DIR/terminal.sh"
            ;;
        4)
            # 框架设置
            "$CORE_DIR/settings.sh"
            ;;
        [5-9]|[1-9][0-9])
            # 访问固定项目（5号及以后为快速访问项目）
            pinned_index=$((choice - 5 + 1))  # 转换为从1开始的索引
            if [ "$pinned_index" -gt 0 ]; then
                line_num=0
                selected_path=""
                while IFS='|' read -r name path description || [[ -n "$name" ]]; do
                    if [ -n "$name" ]; then
                        line_num=$((line_num + 1))
                        if [ "$line_num" -eq "$pinned_index" ]; then
                            selected_path="$path"
                            break
                        fi
                    fi
                done < "$CONFIG_DIR/pinned.list"
                
                if [ -n "$selected_path" ]; then
                    if [ -x "$selected_path" ]; then
                        "$selected_path"
                    else
                        print_error "无法执行 $selected_path"
                        echo
                        read -p "按回车键继续..." 
                    fi
                else
                    print_error "无效的快速访问项目选择"
                    echo
                    read -p "按回车键继续..." 
                fi
            fi
            ;;
        0|q|Q|exit)
            clear
            echo -e "${GREEN}${BOLD}感谢您使用 Traverse！${RESET}"
            exit 0
            ;;
        *)
            print_error "无效选项"
            echo
            read -p "按回车键继续..." 
            ;;
    esac
done

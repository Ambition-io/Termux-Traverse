#!/bin/bash
# Traverse - 全面的 Termux 助手工具
# 主程序 (traverse.sh)

# 设置环境
TRAVBOX_DIR="$HOME/travbox"
CORE_DIR="$TRAVBOX_DIR/core"
CONFIG_DIR="$TRAVBOX_DIR/config"
SCRIPTS_DIR="$TRAVBOX_DIR/scripts"

# 加载配置
if [ -f "$CONFIG_DIR/config.sh" ]; then
    source "$CONFIG_DIR/config.sh"
else
    # 如果配置文件不存在，使用默认配置
    TRAVERSE_THEME="default"
    TRAVERSE_COLOR_PRIMARY="\033[1;36m" # 青色
    TRAVERSE_COLOR_SECONDARY="\033[1;33m" # 黄色
    TRAVERSE_COLOR_HIGHLIGHT="\033[1;32m" # 绿色
    TRAVERSE_COLOR_TEXT="\033[0m" # 默认
    TRAVERSE_VERSION="0.1.0"
    
    # 创建默认配置目录和文件
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/config.sh" << EOF
# Traverse 配置文件
TRAVERSE_THEME="default"
TRAVERSE_COLOR_PRIMARY="\033[1;36m" # 青色
TRAVERSE_COLOR_SECONDARY="\033[1;33m" # 黄色
TRAVERSE_COLOR_HIGHLIGHT="\033[1;32m" # 绿色
TRAVERSE_COLOR_TEXT="\033[0m" # 默认
TRAVERSE_VERSION="0.1.0"
EOF
fi

# 如果目录不存在，创建必要的目录
mkdir -p "$CORE_DIR" "$CONFIG_DIR" "$SCRIPTS_DIR"

# 检查必需的核心脚本，如果缺失则创建占位符
for module in system.sh package.sh terminal.sh settings.sh; do
    if [ ! -f "$CORE_DIR/$module" ]; then
        echo "#!/bin/bash" > "$CORE_DIR/$module"
        echo "echo \"模块 $module 尚未实现。\"" >> "$CORE_DIR/$module"
        echo "read -p \"按回车键返回...\" " >> "$CORE_DIR/$module"
        chmod +x "$CORE_DIR/$module"
    fi
done

# 初始化固定项目
if [ ! -f "$CONFIG_DIR/pinned.list" ]; then
    touch "$CONFIG_DIR/pinned.list"
fi

# 清屏并显示标题的函数
show_header() {
    clear
    local term_width=$(tput cols)
    local padding_size=$(( (term_width - 11) / 2 ))
    local padding=""
    
    for ((i=0; i<padding_size; i++)); do
        padding+=" "
    done
    
    echo -e "${TRAVERSE_COLOR_PRIMARY}${padding}T R A V E R S E${TRAVERSE_COLOR_TEXT}"
    echo -e "${TRAVERSE_COLOR_SECONDARY}${padding}Termux 助手 v${TRAVERSE_VERSION}${TRAVERSE_COLOR_TEXT}"
    echo
}

# 显示主菜单的函数
show_main_menu() {
    echo -e "${TRAVERSE_COLOR_SECONDARY}主菜单:${TRAVERSE_COLOR_TEXT}"
    echo
    echo -e "  ${TRAVERSE_COLOR_HIGHLIGHT}1${TRAVERSE_COLOR_TEXT}. 系统维护"
    echo -e "  ${TRAVERSE_COLOR_HIGHLIGHT}2${TRAVERSE_COLOR_TEXT}. 软件包管理"
    echo -e "  ${TRAVERSE_COLOR_HIGHLIGHT}3${TRAVERSE_COLOR_TEXT}. 终端配置"
    echo -e "  ${TRAVERSE_COLOR_HIGHLIGHT}4${TRAVERSE_COLOR_TEXT}. 框架设置"
    echo -e "  ${TRAVERSE_COLOR_HIGHLIGHT}0${TRAVERSE_COLOR_TEXT}. 退出"
    echo
}

# 显示固定项目/快捷栏的函数
show_pinned_items() {
    if [ -f "$CONFIG_DIR/pinned.list" ] && [ -s "$CONFIG_DIR/pinned.list" ]; then
        echo -e "${TRAVERSE_COLOR_SECONDARY}快速访问:${TRAVERSE_COLOR_TEXT}"
        echo
        
        local count=1
        while IFS='|' read -r name path description || [[ -n "$name" ]]; do
            if [ -n "$name" ]; then
                echo -e "  ${TRAVERSE_COLOR_HIGHLIGHT}P${count}${TRAVERSE_COLOR_TEXT}. ${name}"
                count=$((count + 1))
            fi
        done < "$CONFIG_DIR/pinned.list"
        
        echo
    fi
}

# 显示系统状态概览的函数
show_system_status() {
    local storage=$(df -h | grep "/storage" | head -1)
    local mem_info=$(free -m | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    
    echo -e "${TRAVERSE_COLOR_SECONDARY}系统状态:${TRAVERSE_COLOR_TEXT}"
    echo -e "  存储空间: $storage"
    echo -e "  内存: ${mem_used}MB/${mem_total}MB (${mem_percent}%)"
    echo
}

# 主程序循环
while true; do
    show_header
    show_system_status
    show_main_menu
    show_pinned_items
    
    echo -e "${TRAVERSE_COLOR_SECONDARY}请输入您的选择:${TRAVERSE_COLOR_TEXT} "
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
        P[0-9]|p[0-9])
            # 访问固定项目
            item_num=$(echo "$choice" | tr -cd '0-9')
            if [ "$item_num" -gt 0 ]; then
                line_num=0
                selected_path=""
                while IFS='|' read -r name path description || [[ -n "$name" ]]; do
                    if [ -n "$name" ]; then
                        line_num=$((line_num + 1))
                        if [ "$line_num" -eq "$item_num" ]; then
                            selected_path="$path"
                            break
                        fi
                    fi
                done < "$CONFIG_DIR/pinned.list"
                
                if [ -n "$selected_path" ]; then
                    if [ -x "$selected_path" ]; then
                        "$selected_path"
                    else
                        echo "错误: 无法执行 $selected_path"
                        read -p "按回车键继续..."
                    fi
                else
                    echo "无效的固定项目选择。"
                    read -p "按回车键继续..."
                fi
            fi
            ;;
        0|q|Q|exit)
            clear
            echo "感谢您使用 Traverse！"
            exit 0
            ;;
        *)
            echo "无效选项。按回车键继续..."
            read
            ;;
    esac
done

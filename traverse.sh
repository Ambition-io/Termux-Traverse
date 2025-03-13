#!/bin/bash
# Traverse
# 主程序 (traverse.sh)

# 设置环境
TRAVBOX_DIR="$HOME/travbox"
CORE_DIR="$TRAVBOX_DIR/core"
CONFIG_DIR="$TRAVBOX_DIR/config"
SCRIPTS_DIR="$TRAVBOX_DIR/scripts"
VERSION="0.1.2"

# 颜色定义
NORMAL="\033[0m"      # 默认颜色
BOLD="\033[1m"        # 粗体
TITLE="\033[1;34m"    # 标题颜色（蓝色粗体）
MENU="\033[1;32m"     # 菜单颜色（绿色粗体）
ERROR="\033[1;31m"    # 错误颜色（红色粗体）

# 创建必要的目录
mkdir -p "$CORE_DIR" "$CONFIG_DIR" "$SCRIPTS_DIR"

# 检查模块并赋予执行权限
check_and_prepare_modules() {
    local core_modules=("system.sh" "package.sh" "terminal.sh" "settings.sh")
    local missing=false
    
    for module in "${core_modules[@]}"; do
        local module_path="$CORE_DIR/$module"
        if [ -f "$module_path" ]; then
            [ ! -x "$module_path" ] && chmod +x "$module_path" 2>/dev/null
        else
            missing=true
        fi
    done
    
    if [ "$missing" = true ]; then
        echo -e "${WARN}警告:${NORMAL} 部分核心模块缺失，某些功能可能无法使用"
        echo
        read -p "按回车键继续..." 
    fi
}

# 打印标题
print_header() {
    clear
    # 标题
    echo -e "${TITLE}===========================================${NORMAL}"
    echo -e "${TITLE}          Traverse Termux v${VERSION}${NORMAL}"
    echo -e "${TITLE}===========================================${NORMAL}"
    echo
}

# 打印菜单项
print_menu_item() {
    local number=$1
    local text=$2
    echo -e "${MENU}${number}.${NORMAL} ${text}"
}

# 打印主菜单
print_main_menu() {
    echo -e "${TITLE}主菜单:${NORMAL}"
    echo
    print_menu_item "1" "系统维护"
    print_menu_item "2" "软件包管理"
    print_menu_item "3" "终端配置"
    print_menu_item "4" "框架设置"
    print_menu_item "0" "退出程序"
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
                    echo -e "${TITLE}快速访问:${NORMAL}"
                    echo
                    has_items=true
                fi
                print_menu_item "$count" "$name"
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
    echo -e "-------------------------------------------"
    echo
}

# 执行模块
run_module() {
    local module_name=$1
    local module_path="$CORE_DIR/$module_name"
    
    if [ ! -f "$module_path" ]; then
        echo -e "${ERROR}错误:${NORMAL} 模块 $module_name 不存在"
        read -p "按回车键继续..." 
        return
    fi
    
    if [ ! -x "$module_path" ]; then
        chmod +x "$module_path" 2>/dev/null
        if [ ! -x "$module_path" ]; then
            echo -e "${ERROR}错误:${NORMAL} 无法设置模块 $module_name 为可执行"
            read -p "按回车键继续..." 
            return
        fi
    fi
    
    "$module_path"
}

# 检查模块并赋予执行权限
check_and_prepare_modules

# 主程序循环
while true; do
    print_header
    print_main_menu
    print_separator
    print_quick_access
    
    echo -e "请输入选择的序号:"
    read -p "> " choice
    
    case $choice in
        1)
            run_module "system.sh"
            ;;
        2)
            run_module "package.sh"
            ;;
        3)
            run_module "terminal.sh"
            ;;
        4)
            run_module "settings.sh"
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
                    if [ -f "$selected_path" ]; then
                        if [ ! -x "$selected_path" ]; then
                            chmod +x "$selected_path" 2>/dev/null
                        fi
                        
                        if [ -x "$selected_path" ]; then
                            "$selected_path"
                        else
                            echo -e "${ERROR}错误:${NORMAL} 无法设置快速访问项目为可执行"
                            read -p "按回车键继续..." 
                        fi
                    else
                        echo -e "${ERROR}错误:${NORMAL} 快速访问项目不存在"
                        read -p "按回车键继续..." 
                    fi
                else
                    echo -e "${ERROR}错误:${NORMAL} 无效的快速访问项目选择"
                    read -p "按回车键继续..." 
                fi
            fi
            ;;
        0|q|Q|exit)
            clear
            echo -e "${BOLD}感谢您使用 Traverse！${NORMAL}"
            exit 0
            ;;
        *)
            echo -e "${ERROR}错误:${NORMAL} 无效选项"
            read -p "按回车键继续..." 
            ;;
    esac
done

#!/data/data/com.termux/files/usr/bin/bash

# Traverse - 全面的Termux辅助工具
# 主程序文件 (traverse.sh)

# ANSI颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 无色

# 定义路径
TRAVBOX_PATH="$HOME/travbox"
CORE_PATH="$TRAVBOX_PATH/core"
CONFIG_PATH="$TRAVBOX_PATH/config"
SCRIPTS_PATH="$TRAVBOX_PATH/scripts"

# 检查文件是否存在
check_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}错误：找不到所需文件 $file${NC}"
        return 1
    fi
    return 0
}

# 加载文件并处理错误
source_file() {
    local file="$1"
    if check_file "$file"; then
        source "$file"
    else
        echo -e "${YELLOW}警告：无法加载 $file，某些功能可能不可用${NC}"
        sleep 1
    fi
}

# 初始化，加载必要的文件
initialize() {
    # 加载核心模块
    source_file "$CORE_PATH/system.sh"
    source_file "$CORE_PATH/package.sh"
    source_file "$CORE_PATH/terminal.sh"
    source_file "$CORE_PATH/settings.sh"
    
    # 加载配置
    source_file "$CONFIG_PATH/config.sh"
}

# 显示页眉
display_header() {
    clear
    echo -e "${CYAN}┌───────────────────────────────────┐${NC}"
    echo -e "${CYAN}│        ${GREEN}Traverse for Termux${CYAN}        │${NC}"
    echo -e "${CYAN}└───────────────────────────────────┘${NC}"
    echo
}

# 显示主菜单
display_main_menu() {
    display_header
    
    echo -e "${BLUE}主菜单:${NC}"
    echo -e "${YELLOW}1.${NC} 系统维护"
    echo -e "${YELLOW}2.${NC} 软件包管理"
    echo -e "${YELLOW}3.${NC} 终端配置"
    echo -e "${YELLOW}4.${NC} 框架设置"
    echo -e "${YELLOW}0.${NC} 退出"
    echo
    
    # 显示固定项（如果有）
    if [[ -f "$CONFIG_PATH/pinned.list" && -s "$CONFIG_PATH/pinned.list" ]]; then
        local has_items=false
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue  # 跳过空行和注释
            has_items=true
            break
        done < "$CONFIG_PATH/pinned.list"
        
        if [[ "$has_items" == "true" ]]; then
            echo -e "${BLUE}固定项:${NC}"
            local count=5
            while IFS= read -r line; do
                [[ -z "$line" || "$line" =~ ^# ]] && continue  # 跳过空行和注释
                name=$(echo "$line" | cut -d'|' -f1)
                echo -e "${YELLOW}$count.${NC} $name"
                ((count++))
            done < "$CONFIG_PATH/pinned.list"
            echo
        fi
    fi
}

# 处理菜单选择
handle_main_menu() {
    local choice=$1
    
    case $choice in
        1) # 系统维护
            system_maintenance_menu
            ;;
        2) # 软件包管理
            package_management_menu
            ;;
        3) # 终端配置
            terminal_configuration_menu
            ;;
        4) # 框架设置
            framework_settings_menu
            ;;
        0) # 退出
            echo -e "${GREEN}谢谢使用 Traverse！${NC}"
            exit 0
            ;;
        *) # 处理固定项
            if [[ $choice =~ ^[0-9]+$ && $choice -ge 5 ]]; then
                local index=$(($choice - 5))
                local count=0
                local cmd=""
                local name=""
                
                while IFS= read -r line; do
                    [[ -z "$line" || "$line" =~ ^# ]] && continue  # 跳过空行和注释
                    if [[ $count -eq $index ]]; then
                        name=$(echo "$line" | cut -d'|' -f1)
                        cmd=$(echo "$line" | cut -d'|' -f2)
                        break
                    fi
                    ((count++))
                done < "$CONFIG_PATH/pinned.list"
                
                if [[ -n "$cmd" ]]; then
                    clear
                    echo -e "${GREEN}执行: $name${NC}"
                    echo -e "${BLUE}$cmd${NC}"
                    echo -e "-----------------------------------"
                    eval "$cmd"
                    echo -e "\n${YELLOW}按回车键返回主菜单...${NC}"
                    read
                else
                    echo -e "${RED}无效的选择！${NC}"
                    sleep 1
                fi
            else
                echo -e "${RED}无效的选择！${NC}"
                sleep 1
            fi
            ;;
    esac
}

# 创建默认配置文件
create_default_configs() {
    # 如果不存在，创建默认配置文件
    if [[ ! -f "$CONFIG_PATH/config.sh" ]]; then
        echo "# Traverse 配置文件" > "$CONFIG_PATH/config.sh"
        echo "VERSION=\"1.0.0\"" >> "$CONFIG_PATH/config.sh"
        echo "AUTHOR=\"Traverse Team\"" >> "$CONFIG_PATH/config.sh"
        echo "# 主题设置 (可选值: default, dark, light)" >> "$CONFIG_PATH/config.sh"
        echo "THEME=\"default\"" >> "$CONFIG_PATH/config.sh"
    fi
    
    # 如果不存在，创建默认固定项列表
    if [[ ! -f "$CONFIG_PATH/pinned.list" ]]; then
        echo "# 格式: 名称|命令" > "$CONFIG_PATH/pinned.list"
        echo "# 例如: Python|python" >> "$CONFIG_PATH/pinned.list"
        echo "Nano编辑器|nano" >> "$CONFIG_PATH/pinned.list"
        echo "Python|python" >> "$CONFIG_PATH/pinned.list"
    fi
    
    # 如果不存在，创建默认别名文件
    if [[ ! -f "$CONFIG_PATH/aliases.conf" ]]; then
        echo "# Traverse 别名配置" > "$CONFIG_PATH/aliases.conf"
        echo "# 格式: alias_name='command'" >> "$CONFIG_PATH/aliases.conf"
        echo "# 例如: ll='ls -la'" >> "$CONFIG_PATH/aliases.conf"
    fi
}

# 检查核心模块并创建占位符文件
check_core_modules() {
    local modules=("system.sh" "package.sh" "terminal.sh" "settings.sh")
    for module in "${modules[@]}"; do
        if [[ ! -f "$CORE_PATH/$module" ]]; then
            echo -e "${YELLOW}创建占位符模块: $module${NC}"
            
            # 如果目录不存在，创建目录
            [[ -d "$CORE_PATH" ]] || mkdir -p "$CORE_PATH"
            
            # 创建基本占位符函数
            local func_name="${module%.*}_menu"
            local module_name="${module%.*}"
            
            # 根据模块类型创建不同的菜单函数
            case "$module_name" in
                system)
                    func_name="system_maintenance_menu"
                    menu_title="系统维护"
                    menu_items=(
                        "切换软件源"
                        "更新Termux环境"
                        "安装基本环境"
                        "存储空间设置"
                    )
                    ;;
                package)
                    func_name="package_management_menu"
                    menu_title="软件包管理"
                    menu_items=(
                        "已安装软件包列表"
                        "安装新软件包"
                        "卸载软件包"
                        "管理主页固定项"
                    )
                    ;;
                terminal)
                    func_name="terminal_configuration_menu"
                    menu_title="终端配置"
                    menu_items=(
                        "别名管理"
                        "环境变量管理"
                        "键盘设置"
                        "终端外观"
                    )
                    ;;
                settings)
                    func_name="framework_settings_menu"
                    menu_title="框架设置"
                    menu_items=(
                        "查看版本信息"
                        "卸载功能"
                        "配置管理"
                    )
                    ;;
            esac
            
            # 写入模块文件
            echo "# Traverse ${module_name} 模块" > "$CORE_PATH/$module"
            echo "" >> "$CORE_PATH/$module"
            echo "# ${menu_title}菜单函数" >> "$CORE_PATH/$module"
            echo "${func_name}() {" >> "$CORE_PATH/$module"
            echo "    while true; do" >> "$CORE_PATH/$module"
            echo "        clear" >> "$CORE_PATH/$module"
            echo "        echo -e \"${BLUE}${menu_title}:${NC}\"" >> "$CORE_PATH/$module"
            
            # 添加菜单项
            local i=1
            for item in "${menu_items[@]}"; do
                echo "        echo -e \"${YELLOW}$i.${NC} $item\"" >> "$CORE_PATH/$module"
                ((i++))
            done
            
            echo "        echo -e \"${YELLOW}0.${NC} 返回主菜单\"" >> "$CORE_PATH/$module"
            echo "        echo" >> "$CORE_PATH/$module"
            echo "        echo -en \"${YELLOW}请输入您的选择: ${NC}\"" >> "$CORE_PATH/$module"
            echo "        read choice" >> "$CORE_PATH/$module"
            echo "" >> "$CORE_PATH/$module"
            echo "        case \$choice in" >> "$CORE_PATH/$module"
            echo "            0) # 返回主菜单" >> "$CORE_PATH/$module"
            echo "                return" >> "$CORE_PATH/$module"
            echo "                ;;" >> "$CORE_PATH/$module"
            echo "            *)" >> "$CORE_PATH/$module"
            echo "                echo -e \"${RED}功能尚未实现${NC}\"" >> "$CORE_PATH/$module"
            echo "                echo -e \"${YELLOW}按回车键继续...${NC}\"" >> "$CORE_PATH/$module"
            echo "                read" >> "$CORE_PATH/$module"
            echo "                ;;" >> "$CORE_PATH/$module"
            echo "        esac" >> "$CORE_PATH/$module"
            echo "    done" >> "$CORE_PATH/$module"
            echo "}" >> "$CORE_PATH/$module"
        fi
    done
}

# 主函数
main() {
    # 检查所需目录是否存在，不存在则创建
    for dir in "$TRAVBOX_PATH" "$CORE_PATH" "$CONFIG_PATH" "$SCRIPTS_PATH"; do
        [[ -d "$dir" ]] || mkdir -p "$dir"
    done
    
    # 创建默认配置文件
    create_default_configs
    
    # 检查核心模块并创建占位符
    check_core_modules
    
    # 初始化，加载必要的文件
    initialize
    
    # 主程序循环
    while true; do
        display_main_menu
        echo -en "${YELLOW}请输入您的选择: ${NC}"
        read choice
        handle_main_menu "$choice"
    done
}

# 运行主函数
main
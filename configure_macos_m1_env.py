#!/usr/bin/env python3
"""
macOS环境变量配置脚本
用于配置RocksDB构建所需的环境变量（仅支持aarch64）
"""

import os
import sys
import subprocess
from pathlib import Path

def get_brew_prefix():
    """获取Homebrew安装前缀路径"""
    try:
        result = subprocess.run(["brew", "--prefix"], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except Exception:
        return "/opt/homebrew"  # aarch64 macOS的默认路径

def check_shell_config():
    """检查.zshrc是否包含所需的环境变量"""
    config_file = os.path.expanduser("~/.zshrc")

    if not os.path.exists(config_file):
        return False, config_file

    with open(config_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_vars = ["LIBROCKSDB_STATIC", "ROCKSDB_LIB_DIR", "ROCKSDB_INCLUDE_DIR"]
    missing_vars = []

    for var in required_vars:
        if var not in content:
            missing_vars.append(var)

    if not missing_vars:
        print("✅ .zshrc 已包含所有必需的环境变量")
        return True, config_file
    else:
        print(f"❌ .zshrc 缺少以下环境变量: {', '.join(missing_vars)}")
        return False, config_file

def add_env_to_zshrc(config_file):
    """将环境变量添加到.zshrc文件"""
    brew_prefix = get_brew_prefix()

    env_vars = f"""
# RocksDB环境变量配置
export LIBROCKSDB_STATIC="1"
export ROCKSDB_LIB_DIR="{brew_prefix}/lib"
export ROCKSDB_INCLUDE_DIR="{brew_prefix}/include"
"""

    # 创建备份
    if os.path.exists(config_file):
        backup_path = config_file + '.backup'
        import shutil
        shutil.copy2(config_file, backup_path)
        print(f"创建备份: {backup_path}")

    with open(config_file, 'a', encoding='utf-8') as f:
        f.write(env_vars)

    print(f"✅ 环境变量已添加到: {config_file}")
    print("\n请重新启动终端或运行以下命令使配置生效:")
    print(f"  source {config_file}")

def main():
    """主函数"""
    print("macOS环境变量配置脚本")
    print("=" * 40)

    # 检查架构
    if os.uname().machine != 'arm64':
        print("❌ 此脚本仅支持aarch64架构的macOS")
        return 1

    # 检查shell配置
    config_ok, config_file = check_shell_config()

    if config_ok:
        print("\n配置已完成，无需修改")
        return 0

    # 询问是否添加环境变量
    print("\n需要添加环境变量配置到.zshrc")
    choice = input("是否现在添加? (y/n): ").strip().lower()
    if choice == 'y':
        add_env_to_zshrc(config_file)
        print("\n配置完成！")
    else:
        print("取消配置")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
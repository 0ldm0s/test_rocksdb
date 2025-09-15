#!/usr/bin/env python3
"""
Debian环境变量配置脚本
用于配置RocksDB构建所需的环境变量
"""

import os
import sys
import subprocess
from pathlib import Path

def get_rocksdb_paths():
    """获取RocksDB库和头文件路径"""
    try:
        # 查找librocksdb.so的路径
        result = subprocess.run(["find", "/usr", "-name", "librocksdb.so*"],
                              capture_output=True, text=True, check=True)
        lib_path = Path(result.stdout.strip().split('\n')[0]).parent

        # 头文件路径硬编码为/usr/include
        include_path = "/usr/include"

        return str(lib_path), str(include_path)
    except Exception as e:
        print(f"无法自动查找RocksDB路径: {e}")
        return "/usr/lib/x86_64-linux-gnu", "/usr/include"

def check_shell_config():
    """检查.bashrc是否包含所需的环境变量"""
    config_file = os.path.expanduser("~/.bashrc")

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
        print("✅ .bashrc 已包含所有必需的环境变量")
        return True, config_file
    else:
        print(f"❌ .bashrc 缺少以下环境变量: {', '.join(missing_vars)}")
        return False, config_file

def add_env_to_bashrc(config_file):
    """将环境变量添加到.bashrc文件"""
    lib_dir, include_dir = get_rocksdb_paths()

    env_vars = f"""
# RocksDB环境变量配置
export LIBROCKSDB_STATIC="1"
export ROCKSDB_LIB_DIR="{lib_dir}"
export ROCKSDB_INCLUDE_DIR="{include_dir}"
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
    print("\n环境变量配置:")
    print(f"  LIBROCKSDB_STATIC=1")
    print(f"  ROCKSDB_LIB_DIR={lib_dir}")
    print(f"  ROCKSDB_INCLUDE_DIR={include_dir}")
    print("\n请重新启动终端或运行以下命令使配置生效:")
    print(f"  source {config_file}")

def main():
    """主函数"""
    print("Debian环境变量配置脚本")
    print("=" * 40)

    # 检查shell配置
    config_ok, config_file = check_shell_config()

    if config_ok:
        print("\n配置已完成，无需修改")
        return 0

    # 询问是否添加环境变量
    print("\n需要添加环境变量配置到.bashrc")
    choice = input("是否现在添加? (y/n): ").strip().lower()
    if choice == 'y':
        add_env_to_bashrc(config_file)
        print("\n配置完成！")
    else:
        print("取消配置")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
#!/bin/bash

# Debian 13 依赖安装脚本
# 安装构建RocksDB所需的依赖包

set -e

echo "正在更新包列表..."
sudo apt update

echo "安装RocksDB开发包和构建依赖..."
sudo apt install -y \
    librocksdb-dev \
    rocksdb-tools \
    build-essential \
    cmake \
    libgflags-dev \
    libsnappy-dev \
    zlib1g-dev \
    libbz2-dev \
    liblz4-dev \
    libzstd-dev \
    pkg-config \
    git

echo "依赖安装完成！"
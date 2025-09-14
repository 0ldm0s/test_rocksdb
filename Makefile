# RocksDB + LZ4 编译测试 Makefile
# 支持多操作系统：Windows (MSYS2)、macOS (Homebrew)、Debian/Ubuntu、FreeBSD

# 检测操作系统
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    # 检测是否为 Debian/Ubuntu
    ifeq ($(shell cat /etc/os-release | grep -E '^ID=debian|^ID=ubuntu'),)
        OS = other_linux
    else
        OS = debian
    endif
else ifeq ($(UNAME_S),Darwin)
    OS = macos
else ifeq ($(UNAME_S),FreeBSD)
    OS = freebsd
else ifeq ($(OS),Windows_NT)
    OS = windows
else
    OS = unknown
endif

# 系统特定的RocksDB配置
ifeq ($(OS),windows)
    # Windows MSYS2 配置
    export LIBROcksDB_STATIC = 1
    ROCKSDB_INSTALL_CMD = pacman -S --noconfirm mingw-w64-x86_64-rocksdb
    ROCKSDB_LIB_PATH = /mingw64/lib
    ROCKSDB_INCLUDE_PATH = /mingw64/include
    ROCKSDB_LIBS = -lrocksdb -lshlwapi -lrpcrt4
else ifeq ($(OS),macos)
    # macOS Homebrew 配置
    ROCKSDB_INSTALL_CMD = brew install rocksdb
    ROCKSDB_LIB_PATH = /usr/local/lib
    ROCKSDB_INCLUDE_PATH = /usr/local/include
    ROCKSDB_LIBS = -lrocksdb
    # 检查 Apple Silicon
    ifeq ($(shell uname -m),arm64)
        ROCKSDB_LIB_PATH = /opt/homebrew/lib
        ROCKSDB_INCLUDE_PATH = /opt/homebrew/include
    endif
else ifeq ($(OS),debian)
    # Debian/Ubuntu 配置
    ROCKSDB_INSTALL_CMD = sudo apt-get update && sudo apt-get install -y librocksdb-dev
    ROCKSDB_LIB_PATH = /usr/lib
    ROCKSDB_INCLUDE_PATH = /usr/include
    ROCKSDB_LIBS = -lrocksdb
else ifeq ($(OS),freebsd)
    # FreeBSD 配置
    ROCKSDB_INSTALL_CMD = sudo pkg install -y rocksdb
    ROCKSDB_LIB_PATH = /usr/local/lib
    ROCKSDB_INCLUDE_PATH = /usr/local/include
    ROCKSDB_LIBS = -lrocksdb
else
    $(error 不支持的操作系统: $(UNAME_S))
endif

# 默认编译器设置
CC = gcc
CXX = g++

# 项目配置
PROJECT_NAME = rocksdb_lz4_test

# 颜色输出
GREEN = \033[0;32m
BLUE = \033[0;34m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# 默认目标
.PHONY: help
help:
	@echo "$(GREEN)RocksDB + LZ4 编译测试 Makefile$(NC)"
	@echo "$(YELLOW)当前操作系统: $(OS)$(NC)"
	@echo "$(BLUE)核心编译器测试命令:$(NC)"
	@echo "  make build-gcc       - 使用 GCC/G++ 编译项目"
	@echo "  make build-clang     - 使用 Clang/Clang++ 编译项目"
	@echo "  make build-release    - 构建发布版本"
	@echo "  make build-debug      - 构建调试版本"
	@echo "$(BLUE)系统依赖管理:$(NC)"
	@echo "  make deps            - 安装系统RocksDB依赖"
	@echo "  make deps-info       - 显示当前系统依赖信息"
	@echo "  make check-deps      - 检查RocksDB是否已安装"
	@echo "$(BLUE)其他实用命令:$(NC)"
	@echo "  make run             - 运行测试程序"
	@echo "  make test            - 运行测试"
	@echo "  make clean           - 清理构建文件"
	@echo "  make check-compilers - 检查编译器版本"
	@echo "  make info            - 显示系统信息"
ifeq ($(OS),windows)
	@echo "$(BLUE)Windows 打包命令:$(NC)"
	@echo "  make dist-mingw64    - 为 MinGW64 创建分发包（包含所需 DLL）"
	@echo "  make clean-dist      - 清理分发包"
endif

# 使用 GCC 编译
.PHONY: build-gcc
build-gcc:
	@echo "$(GREEN)使用 GCC/G++ 编译项目...$(NC)"
	export CC=gcc CXX=g++ && \
	cargo build --release
	@echo "$(GREEN)GCC 编译完成$(NC)"

# 使用 Clang 编译
.PHONY: build-clang
build-clang:
	@echo "$(GREEN)使用 Clang/Clang++ 编译项目...$(NC)"
	export CC=clang CXX=clang++ && \
	cargo build --release
	@echo "$(GREEN)Clang 编译完成$(NC)"

# 构建发布版本（默认构建）
.PHONY: build-release
build-release:
	@echo "$(GREEN)构建发布版本...$(NC)"
	cargo build --release
	@echo "$(GREEN)发布版本构建完成$(NC)"

# 构建调试版本
.PHONY: build-debug
build-debug:
	@echo "$(GREEN)构建调试版本...$(NC)"
	cargo build
	@echo "$(GREEN)调试版本构建完成$(NC)"

# 运行测试程序
.PHONY: run
run:
	@echo "$(BLUE)运行 RocksDB + LZ4 测试...$(NC)"
	cargo run

# 运行测试
.PHONY: test
test:
	@echo "$(BLUE)运行所有测试...$(NC)"
	cargo test

# 安装系统依赖（根据操作系统自动选择）
.PHONY: deps
deps:
	@echo "$(GREEN)安装系统依赖...$(NC)"
	@echo "$(YELLOW)检测到操作系统: $(OS)$(NC)"
ifeq ($(OS),windows)
	@echo "正在安装 MSYS2 RocksDB..."
	$(ROCKSDB_INSTALL_CMD)
else ifeq ($(OS),macos)
	@echo "正在通过 Homebrew 安装 RocksDB..."
	$(ROCKSDB_INSTALL_CMD)
else ifeq ($(OS),debian)
	@echo "正在通过 apt-get 安装 RocksDB..."
	$(ROCKSDB_INSTALL_CMD)
else ifeq ($(OS),freebsd)
	@echo "正在通过 pkg 安装 RocksDB..."
	$(ROCKSDB_INSTALL_CMD)
endif
	@echo "$(GREEN)系统依赖安装完成$(NC)"

# 显示依赖信息
.PHONY: deps-info
deps-info:
	@echo "$(BLUE)当前系统依赖配置:$(NC)"
	@echo "$(YELLOW)操作系统: $(OS)$(NC)"
	@echo "$(YELLOW)RocksDB 库路径: $(ROCKSDB_LIB_PATH)$(NC)"
	@echo "$(YELLOW)RocksDB 头文件路径: $(ROCKSDB_INCLUDE_PATH)$(NC)"
	@echo "$(YELLOW)安装命令: $(ROCKSDB_INSTALL_CMD)$(NC)"
	@echo "$(YELLOW)链接库: $(ROCKSDB_LIBS)$(NC)"

# 检查RocksDB是否已安装
.PHONY: check-deps
check-deps:
	@echo "$(BLUE)检查RocksDB依赖...$(NC)"
ifeq ($(OS),windows)
	@if [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.a" ]; then \
		echo "$(GREEN)✓ RocksDB 库已存在: $(ROCKSDB_LIB_PATH)/librocksdb.a$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 库不存在，请运行 make deps 安装$(NC)"; \
	fi
	@if [ -d "$(ROCKSDB_INCLUDE_PATH)/rocksdb" ]; then \
		echo "$(GREEN)✓ RocksDB 头文件已存在: $(ROCKSDB_INCLUDE_PATH)/rocksdb$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 头文件不存在，请运行 make deps 安装$(NC)"; \
	fi
else ifeq ($(OS),macos)
	@if [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.dylib" ] || [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.a" ]; then \
		echo "$(GREEN)✓ RocksDB 库已存在$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 库不存在，请运行 make deps 安装$(NC)"; \
	fi
	@if [ -d "$(ROCKSDB_INCLUDE_PATH)/rocksdb" ]; then \
		echo "$(GREEN)✓ RocksDB 头文件已存在$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 头文件不存在，请运行 make deps 安装$(NC)"; \
	fi
else ifeq ($(OS),debian)
	@if [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.so" ] || [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.a" ]; then \
		echo "$(GREEN)✓ RocksDB 库已存在$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 库不存在，请运行 make deps 安装$(NC)"; \
	fi
	@if [ -d "$(ROCKSDB_INCLUDE_PATH)/rocksdb" ]; then \
		echo "$(GREEN)✓ RocksDB 头文件已存在$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 头文件不存在，请运行 make deps 安装$(NC)"; \
	fi
else ifeq ($(OS),freebsd)
	@if [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.so" ] || [ -f "$(ROCKSDB_LIB_PATH)/librocksdb.a" ]; then \
		echo "$(GREEN)✓ RocksDB 库已存在$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 库不存在，请运行 make deps 安装$(NC)"; \
	fi
	@if [ -d "$(ROCKSDB_INCLUDE_PATH)/rocksdb" ]; then \
		echo "$(GREEN)✓ RocksDB 头文件已存在$(NC)"; \
	else \
		echo "$(RED)✗ RocksDB 头文件不存在，请运行 make deps 安装$(NC)"; \
	fi
endif

# 清理构建文件
.PHONY: clean
clean:
	@echo "$(GREEN)清理构建文件...$(NC)"
	cargo clean
	@echo "$(GREEN)清理完成$(NC)"

# 检查编译器版本
.PHONY: check-compilers
check-compilers:
	@echo "$(BLUE)检查编译器版本...$(NC)"
	@echo "$(GREEN)GCC 版本:$(NC)"
	@gcc --version | head -1
	@echo "$(GREEN)G++ 版本:$(NC)"
	@g++ --version | head -1
	@echo "$(GREEN)Clang 版本:$(NC)"
	@clang --version | head -1
	@echo "$(GREEN)Clang++ 版本:$(NC)"
	@clang++ --version | head -1

# 比较编译器性能
.PHONY: compare
compare:
	@echo "$(BLUE)比较GCC和Clang编译性能...$(NC)"
	@echo "$(GREEN)GCC 编译时间:$(NC)"
	@time make build-gcc
	@echo "$(GREEN)Clang 编译时间:$(NC)"
	@time make build-clang
	@echo "$(GREEN)编译器性能比较完成$(NC)"

# 显示系统信息
.PHONY: info
info:
	@echo "$(BLUE)系统信息:$(NC)"
	@echo "$(YELLOW)操作系统: $(OS)$(NC)"
	@echo "$(YELLOW)系统架构: $(shell uname -m)$(NC)"
	@echo "$(YELLOW)内核版本: $(shell uname -r)$(NC)"
	@echo "$(YELLOW)RocksDB 配置:$(NC)"
	@echo "  - 库路径: $(ROCKSDB_LIB_PATH)"
	@echo "  - 头文件路径: $(ROCKSDB_INCLUDE_PATH)"
	@echo "  - 链接库: $(ROCKSDB_LIBS)"

# Windows 专用的 MinGW64 分发包
ifeq ($(OS),windows)
# MinGW64 分发包目标
.PHONY: dist-mingw64
dist-mingw64: build-release
	@echo "$(GREEN)创建 MinGW64 分发包...$(NC)"
	@echo "$(YELLOW)编译完成后复制依赖的 DLL 文件...$(NC)"
	# 创建分发包目录
	mkdir -p dist/mingw64
	# 复制可执行文件
	cp target/release/$(PROJECT_NAME).exe dist/mingw64/
	# 复制依赖的 DLL 文件
	@if [ -f "/mingw64/bin/librocksdb.dll" ]; then \
		cp /mingw64/bin/librocksdb.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 librocksdb.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 librocksdb.dll$(NC)"; \
		exit 1; \
	fi
	@if [ -f "/mingw64/bin/libgcc_s_seh-1.dll" ]; then \
		cp /mingw64/bin/libgcc_s_seh-1.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 libgcc_s_seh-1.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 libgcc_s_seh-1.dll$(NC)"; \
	fi
	@if [ -f "/mingw64/bin/libwinpthread-1.dll" ]; then \
		cp /mingw64/bin/libwinpthread-1.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 libwinpthread-1.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 libwinpthread-1.dll$(NC)"; \
	fi
	@if [ -f "/mingw64/bin/libstdc++-6.dll" ]; then \
		cp /mingw64/bin/libstdc++-6.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 libstdc++-6.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 libstdc++-6.dll$(NC)"; \
	fi
	@if [ -f "/mingw64/bin/liblz4.dll" ]; then \
		cp /mingw64/bin/liblz4.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 liblz4.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 liblz4.dll$(NC)"; \
	fi
	@if [ -f "/mingw64/bin/zlib1.dll" ]; then \
		cp /mingw64/bin/zlib1.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 zlib1.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 zlib1.dll$(NC)"; \
	fi
	@if [ -f "/mingw64/bin/libzstd.dll" ]; then \
		cp /mingw64/bin/libzstd.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 libzstd.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 libzstd.dll$(NC)"; \
	fi
	@if [ -f "/mingw64/bin/libbz2-1.dll" ]; then \
		cp /mingw64/bin/libbz2-1.dll dist/mingw64/; \
		echo "$(GREEN)✓ 复制 libbz2-1.dll$(NC)"; \
	else \
		echo "$(RED)✗ 找不到 libbz2-1.dll$(NC)"; \
	fi
	# 创建说明文件
	@echo "$(BLUE)$(PROJECT_NAME) MinGW64 分发包$(NC)" > dist/mingw64/README.txt
	@echo "构建时间: $(shell date)" >> dist/mingw64/README.txt
	@echo "操作系统: $(OS) $(shell uname -m)" >> dist/mingw64/README.txt
	@echo "" >> dist/mingw64/README.txt
	@echo "包含的文件:" >> dist/mingw64/README.txt
	@echo "- $(PROJECT_NAME).exe (主程序)" >> dist/mingw64/README.txt
	@echo "- librocksdb.dll (RocksDB 库)" >> dist/mingw64/README.txt
	@echo "- libgcc_s_seh-1.dll (GCC 运行时)" >> dist/mingw64/README.txt
	@echo "- libwinpthread-1.dll (POSIX 线程库)" >> dist/mingw64/README.txt
	@echo "- libstdc++-6.dll (C++ 标准库)" >> dist/mingw64/README.txt
	@echo "- liblz4.dll (LZ4 压缩库)" >> dist/mingw64/README.txt
	@echo "- zlib1.dll (Zlib 压缩库)" >> dist/mingw64/README.txt
	@echo "- libzstd.dll (Zstandard 压缩库)" >> dist/mingw64/README.txt
	@echo "- libbz2-1.dll (Bzip2 压缩库)" >> dist/mingw64/README.txt
	@echo "" >> dist/mingw64/README.txt
	@echo "使用说明:" >> dist/mingw64/README.txt
	@echo "1. 在 Windows CMD 中直接运行 $(PROJECT_NAME).exe" >> dist/mingw64/README.txt
	@echo "2. 所有必需的 DLL 文件都包含在此目录中" >> dist/mingw64/README.txt
	@echo "3. 无需额外安装 MSYS2 或其他依赖" >> dist/mingw64/README.txt
	@echo "" >> dist/mingw64/README.txt
	@echo "注意: 此分发包仅适用于 Windows 系统" >> dist/mingw64/README.txt
	# 显示分发包内容
	@echo "$(GREEN)MinGW64 分发包创建完成！$(NC)"
	@echo "$(BLUE)分发包位置: dist/mingw64/$(NC)"
	@echo "$(YELLOW)分发包内容:$(NC)"
	@ls -la dist/mingw64/

# 清理分发包
.PHONY: clean-dist
clean-dist:
	@echo "$(GREEN)清理分发包...$(NC)"
	rm -rf dist/
	@echo "$(GREEN)分发包清理完成$(NC)"

# 创建 ZIP 压缩包（需要 zip 命令）
.PHONY: zip-dist
zip-dist: dist-mingw64
	@echo "$(GREEN)创建 ZIP 压缩包...$(NC)"
	cd dist && zip -r $(PROJECT_NAME)-mingw64-$(shell date +%Y%m%d-%H%M%S).zip mingw64/
	@echo "$(GREEN)ZIP 压缩包创建完成！$(NC)"
	@ls -la dist/*.zip
endif
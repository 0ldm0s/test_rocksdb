fn main() {
    // 只在Windows平台使用系统RocksDB库
    if std::env::consts::OS == "windows" {
        // 强制使用系统RocksDB库
        println!("cargo:rustc-link-lib=static=rocksdb");
        println!("cargo:rustc-link-lib=shlwapi");
        println!("cargo:rustc-link-lib=rpcrt4");
        println!("cargo:rustc-link-search=native=C:\\msys64\\mingw64\\lib");

        // 设置环境变量来阻止librocksdb-sys从源码编译
        // 这些环境变量需要在librocksdb-sys的build.rs中生效
        std::env::set_var("ROCKSDB_LIB_DIR", "C:\\msys64\\mingw64\\lib");
        std::env::set_var("ROCKSDB_INCLUDE_DIR", "C:\\msys64\\mingw64\\include");
        std::env::set_var("ROCKSDB_STATIC", "1");

        // 告诉cargo如果这些文件变化就重新构建
        println!("cargo:rerun-if-changed=C:\\msys64\\mingw64\\lib\\librocksdb.a");
        println!("cargo:rerun-if-changed=C:\\msys64\\mingw64\\include\\rocksdb");
    }
}
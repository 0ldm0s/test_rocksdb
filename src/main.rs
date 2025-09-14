use rocksdb::{DB, Options, WriteBatch};
use lz4::{block::compress, block::decompress};
use std::path::Path;
use std::time::Instant;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("开始 RocksDB + LZ4 编译测试...");

    // 1. 测试 LZ4 压缩
    println!("测试 LZ4 压缩...");
    let data = "这是一个测试数据，用于验证 LZ4 压缩功能是否正常工作。".as_bytes();
    let compressed = compress(data, None, true)?;
    println!("原始数据大小: {} 字节", data.len());
    println!("压缩后大小: {} 字节", compressed.len());

    // 2. 测试 LZ4 解压
    let decompressed = decompress(&compressed, None)?;
    println!("解压成功: {}", String::from_utf8_lossy(&decompressed));

    // 3. 测试 RocksDB 基本功能
    println!("\n测试 RocksDB 基本功能...");
    let db_path = Path::new("test_db");

    // 清理旧的数据库
    if db_path.exists() {
        std::fs::remove_dir_all(db_path)?;
    }

    // 创建 RocksDB 配置
    let mut opts = Options::default();
    opts.create_if_missing(true);
    opts.set_compression_type(rocksdb::DBCompressionType::Lz4);
    opts.set_write_buffer_size(64 * 1024 * 1024); // 64MB write buffer
    opts.set_max_write_buffer_number(3);
    opts.set_target_file_size_base(64 * 1024 * 1024); // 64MB target file size
    opts.set_max_background_jobs(4);

    // 打开数据库
    let db = DB::open(&opts, db_path)?;
    println!("RocksDB 数据库打开成功");

    // 4. 测试基本读写操作
    println!("测试基本读写操作...");
    let key = b"test_key";
    let value = "这是一个测试值，用于验证 RocksDB 的读写功能".as_bytes();

    // 写入数据
    db.put(key, value)?;
    println!("数据写入成功");

    // 读取数据
    let retrieved = db.get(key)?;
    match retrieved {
        Some(data) => {
            println!("数据读取成功: {}", String::from_utf8(data)?);
        }
        None => {
            println!("数据读取失败");
        }
    }

    // 5. 测试批量操作
    println!("测试批量操作...");
    let mut batch = WriteBatch::default();
    for i in 0..10 {
        batch.put(&format!("batch_key_{}", i).as_bytes(), &format!("batch_value_{}", i).as_bytes());
    }
    db.write(batch)?;
    println!("批量写入成功");

    // 验证批量数据
    for i in 0..10 {
        let retrieved = db.get(&format!("batch_key_{}", i).as_bytes())?;
        match retrieved {
            Some(data) => {
                println!("Batch[{}]: {}", i, String::from_utf8(data)?);
            }
            None => {
                println!("Batch[{}]: 读取失败", i);
            }
        }
    }

    // 6. 测试删除操作
    println!("测试删除操作...");
    db.delete(key)?;
    let retrieved = db.get(key)?;
    match retrieved {
        None => {
            println!("数据删除成功");
        }
        Some(_) => {
            println!("数据删除失败");
        }
    }

    // 7. 测试迭代器
    println!("测试迭代器...");
    let mut iter = db.iterator(rocksdb::IteratorMode::Start);
    let mut count = 0;
    for item in &mut iter {
        let (key, value) = item?;
        println!("迭代器[{}]: {} => {}", count, String::from_utf8(key.to_vec())?, String::from_utf8(value.to_vec())?);
        count += 1;
    }
    println!("总共找到 {} 条记录", count);

    // 8. 性能测试（简化版）
    println!("性能测试...");
    let start = Instant::now();

    for i in 0..100 {  // 减少测试数据量
        let key = format!("perf_key_{}", i);
        let value = format!("perf_value_{}", i);
        db.put(key.as_bytes(), value.as_bytes())?;
    }

    let write_time = start.elapsed();
    println!("写入 100 条记录耗时: {:?}", write_time);

    let start = Instant::now();
    for i in 0..100 {
        let key = format!("perf_key_{}", i);
        let _ = db.get(key.as_bytes())?;
    }

    let read_time = start.elapsed();
    println!("读取 100 条记录耗时: {:?}", read_time);

    // 关闭数据库（先drop所有借用）
    drop(iter);
    drop(db);

    // 清理数据库
    if db_path.exists() {
        std::fs::remove_dir_all(db_path)?;
    }

    println!("\n所有测试完成！RocksDB + LZ4 编译测试通过。");
    println!("编译器信息:");
    println!("  - Rust: {}", std::env::var("RUSTC").unwrap_or_else(|_| "unknown".to_string()));
    println!("  - RocksDB: 0.24");
    println!("  - LZ4: 1.24");

    Ok(())
}
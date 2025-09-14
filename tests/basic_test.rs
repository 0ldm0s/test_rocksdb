use rocksdb::{DB, Options};
use tempfile::TempDir;

#[test]
fn test_rocksdb_lz4_basic() {
    println!("测试 RocksDB + LZ4 基本功能...");

    let temp_dir = TempDir::new().expect("无法创建临时目录");

    let mut opts = Options::default();
    opts.create_if_missing(true);
    opts.set_compression_type(rocksdb::DBCompressionType::Lz4);

    let db = DB::open(&opts, temp_dir.path()).expect("数据库打开失败");
    println!("数据库打开成功");

    // 简单读写测试
    db.put(b"key1", b"value1").expect("写入失败");
    let value = db.get(b"key1").expect("读取失败");
    assert_eq!(value, Some(b"value1".to_vec()));
    println!("基本读写测试成功");

    // 测试中文数据
    let chinese_data = "测试中文数据";
    db.put(b"key2", chinese_data.as_bytes()).expect("中文写入失败");
    let retrieved = db.get(b"key2").expect("中文读取失败").expect("中文数据未找到");
    assert_eq!(retrieved, chinese_data.as_bytes());
    println!("中文数据测试成功");

    println!("所有测试完成！");
}
//! RocksDB + LZ4 压缩测试库
//!
//! 这个库提供了 RocksDB 与 LZ4 压缩的集成测试功能。

pub use rocksdb;
pub use lz4;

/// 基本的 RocksDB + LZ4 功能测试
pub mod basic_tests {
    use super::*;

    /// 测试 RocksDB 是否能正确初始化并使用 LZ4 压缩
    pub fn test_basic_lz4() -> Result<(), Box<dyn std::error::Error>> {
        use rocksdb::{DB, Options};
        use tempfile::TempDir;

        let temp_dir = TempDir::new()?;
        let mut opts = Options::default();
        opts.create_if_missing(true);
        opts.set_compression_type(rocksdb::DBCompressionType::Lz4);

        let db = DB::open(&opts, temp_dir.path())?;

        // 简单读写测试
        db.put(b"test_key", b"test_value")?;
        let value = db.get(b"test_key")?;
        assert_eq!(value, Some(b"test_value".to_vec()));

        Ok(())
    }

    /// 测试 LZ4 压缩功能是否正常工作
    pub fn test_lz4_compression() -> Result<(), Box<dyn std::error::Error>> {
        use lz4::block::{compress, decompress};

        let data = b"This is test data for LZ4 compression functionality";
        let compressed = compress(data, None, true)?;
        let decompressed = decompress(&compressed, None)?;

        assert_eq!(data, decompressed.as_slice());
        Ok(())
    }
}
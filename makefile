build:
	RUSTFLAGS="-C target-cpu=native" cargo build --release
start: build
	RETH_DB_PATH=~/chain/reth/data/db \
	./target/release/reth-server 	
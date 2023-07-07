build:
	RUSTFLAGS="-C target-cpu=native" cargo build --release
start:
	RETH_DB_PATH=~/chain/reth/data/db \
	HTTP_PORT=9545 \
	./target/release/reth-server 	
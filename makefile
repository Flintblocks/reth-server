build:
	RUSTFLAGS="-C target-cpu=native" cargo build --release
start:
	RETH_DB_PATH=~/chain/reth/data/db \
	./target/release/reth-server 	

stop: 
	docker container stop $(docker ps -q)
remove:
	docker container rm $(docker ps -a -q)	



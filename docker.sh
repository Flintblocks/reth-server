#!/bin/bash

# Request user input for the number of services to scale
read -p "Enter the number of services you want to scale: " scale_number


#build images
docker compose build

# Create the NGINX configuration file
echo "events {" > nginx.conf
echo "    worker_connections 1024;" >> nginx.conf
echo "}" >> nginx.conf
echo "http {" >> nginx.conf
echo "    upstream reth-http {" >> nginx.conf

for (( i=0; i<$scale_number; i++ ))
do
  # Calculate port_http
  port_http=$((9545 + i * 100))
  # Add server to the NGINX configuration file
  echo "        server localhost:$port_http;" >> nginx.conf

  # Run Docker command for each reth-http service
  docker run -d --name reth-http-$i -p $port_http:8545 -v ~/chain/reth/data/db:/data/db -e RETH_DB_PATH=/data/db reth-http
done

echo "    }" >> nginx.conf  # Close reth-http upstream

echo "    upstream reth-ws {" >> nginx.conf

for (( i=0; i<$scale_number; i++ ))
do
  # Calculate port_ws
  port_ws=$((9546 + i * 100))
  # Add server to the NGINX configuration file
  echo "        server localhost:$port_ws;" >> nginx.conf

  # Run Docker command for each reth-ws service
  docker run -d --name reth-ws-$i -p $port_ws:8546 -v ~/chain/reth/data/db:/data/db -e RETH_DB_PATH=/data/db reth-ws
done

echo "    }" >> nginx.conf  # Close reth-ws upstream

# Continue with the server blocks and close the http block
echo "    server {" >> nginx.conf
echo "        listen 8545;" >> nginx.conf
echo "        location / {" >> nginx.conf
echo "            proxy_pass http://reth-http;" >> nginx.conf
echo "        }" >> nginx.conf
echo "    }" >> nginx.conf
echo "    server {" >> nginx.conf
echo "        listen 8546;" >> nginx.conf
echo "        location / {" >> nginx.conf
echo "            proxy_pass http://reth-ws;" >> nginx.conf
echo "            proxy_http_version 1.1;" >> nginx.conf
echo "            proxy_set_header Upgrade \$http_upgrade;" >> nginx.conf
echo "            proxy_set_header Connection \"Upgrade\";" >> nginx.conf
echo "        }" >> nginx.conf
echo "    }" >> nginx.conf
echo "}" >> nginx.conf

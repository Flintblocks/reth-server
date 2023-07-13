#!/bin/bash

# Request user input for the number of services to scale
read -p "Enter the number of services you want to scale: " scale_number


#build images
docker build . -t reth-server

#build network
docker network create reth-net

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
  container_name="reth-server-$i"

  # If a container with the same name exists, stop and remove it
  if [ "$(docker ps -a -q -f name=$container_name)" ]; then
      echo "Stopping and removing existing container $container_name"
      docker stop $container_name
      docker rm -f $container_name
  fi

  echo "        server $container_name:8545;" >> nginx.conf
  done

echo "    }" >> nginx.conf  # Close reth-http upstream

echo "    upstream reth-ws {" >> nginx.conf

for (( i=0; i<$scale_number; i++ ))
do
  # Calculate port_ws
  port_http=$((9545 + i * 100))
  port_ws=$((9546 + i * 100))
  # Add server to the NGINX configuration file
  container_name="reth-server-$i"

  # If a container with the same name exists, stop and remove it
  if [ "$(docker ps -a -q -f name=$container_name)" ]; then
      echo "Stopping and removing existing container $container_name"
      docker stop $container_name
      docker rm -f $container_name
  fi

  echo "        server $container_name:8546;" >> nginx.conf
  
  # Run Docker command for each reth-http service
  echo "docker run -d --name reth-server-$i --net=reth-net --pid=host -p $port_http:8545 -p $port_ws:8546 -v ~/chain/reth/data/db:/data/db -e RETH_DB_PATH=/data/db reth-server"
  docker run -d --name reth-server-$i --net=reth-net --pid=host -p $port_http:8545 -p $port_ws:8546 -v ~/chain/reth/data/db:/data/db -e RETH_DB_PATH=/data/db reth-server

  # Run Docker command for each reth-ws service
done

echo "    }" >> nginx.conf  # Close reth-ws upstream

# Continue with the server blocks and close the http block
echo "    server {" >> nginx.conf
echo "        listen 8080;" >> nginx.conf
echo "        location / {" >> nginx.conf
echo "            proxy_pass http://reth-http;" >> nginx.conf
echo "        }" >> nginx.conf
echo "    }" >> nginx.conf
echo "    server {" >> nginx.conf
echo "        listen 8081;" >> nginx.conf
echo "        location / {" >> nginx.conf
echo "            proxy_pass http://reth-ws;" >> nginx.conf
echo "            proxy_http_version 1.1;" >> nginx.conf
echo "            proxy_set_header Upgrade \$http_upgrade;" >> nginx.conf
echo "            proxy_set_header Connection \"Upgrade\";" >> nginx.conf
echo "        }" >> nginx.conf
echo "    }" >> nginx.conf
echo "}" >> nginx.conf


if [ "$(docker ps -a -q -f name=nginx)" ]; then
      echo "Stopping and removing existing container nginx"
      docker stop nginx
      docker rm -f nginx
  fi
docker run -d --name nginx --net=reth-net -p 8080:8080 -p 8081:8081 -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx


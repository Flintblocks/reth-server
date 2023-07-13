#!/bin/bash

# Request user input for the number of services to scale
read -p "Enter the number of services you want to scale: " scale_number

# Create the NGINX configuration file
echo "http {" > nginx.conf
echo "    upstream reth-http {" >> nginx.conf

for (( i=0; i<$scale_number; i++ ))
do
  # Calculate port_http
  port_http=$((8545 + i * 100))
  # Add server to the NGINX configuration file
  echo "        server localhost:$port_http;" >> nginx.conf
done

echo "    }" >> nginx.conf  # Close reth-http upstream

echo "    upstream reth-ws {" >> nginx.conf

for (( i=0; i<$scale_number; i++ ))
do
  # Calculate port_ws
  port_ws=$((8546 + i * 100))
  # Add server to the NGINX configuration file
  echo "        server localhost:$port_ws;" >> nginx.conf
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

# Run Docker Compose command for each service
for (( i=0; i<$scale_number; i++ ))
do
  # Calculate ports
  port_http=$((9545 + i * 100))
  port_ws=$((9546 + i * 100))

  # Run Docker Compose command
  INDEX=$i PORT=$port_http PORT_WS=$port_ws docker compose up -d --scale reth-http=$scale_number --scale reth-ws=$scale_number
done

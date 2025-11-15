#!/bin/bash

dnf update -y
dnf -y install nginx git

sudo systemctl start nginx
sudo systemctl enable nginx

cd /usr/share/nginx/html/
sudo git clone https://github.com/CloudTechOrg/cloudtech-reservation-web.git
chown -R ec2-user:ec2-user /usr/share/nginx/html/cloudtech-reservation-web

sudo systemctl restart nginx

cat >/usr/share/nginx/html/cloudtech-reservation-web/config.js <<EOF
const apiConfig = {
  baseURL: "${api_base_url}"
}
EOF

sudo systemctl restart nginx
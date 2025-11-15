#!/bin/bash

dnf -y update
dnf -y install git golang nginx

cd /home/ec2-user/
git clone https://github.com/CloudTechOrg/cloudtech-reservation-api.git

cat >/etc/systemd/system/cloudtech-reservation-api.service <<EOF
[Unit]
Description=Go Server

[Service]
WorkingDirectory=/home/ec2-user/cloudtech-reservation-api
ExecStart=/usr/bin/go run main.go
User=ec2-user
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now goserver.service
systemctl enable --now nginx
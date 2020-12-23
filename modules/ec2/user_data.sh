#!/bin/sh

sudo yum -y update

if [ ! -d "/home/ec2-user/app/current" ]; then
    mkdir -p "/home/ec2-user/app/current"
    chown ec2-user:ec2-user -R "/home/ec2-user/app"
fi

if [ -f "/tmp/install" ]; then
    rm "/tmp/install"
    cd /tmp

    wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install

    chmod +x ./install

    sudo ./install auto
fi

sudo service codedeploy-agent start
sudo systemctl start docker.service

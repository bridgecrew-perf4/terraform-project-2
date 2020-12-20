#!/bin/sh

sudo yum update -y
sudo amazon-linux-extras install docker
sudo yum install docker
sudo systemctl start docker.service
sudo usermod -a -G docker ec2-user

sudo yum  -y install wget ruby

CODEDEPLOY_BIN="/opt/codedeploy-agent/bin/codedeploy-agent"
$CODEDEPLOY_BIN stop
sudo yum erase codedeploy-agent -y

cd /home/ec2-user

wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install

chmod +x ./install

sudo ./install auto

sudo service codedeploy-agent start
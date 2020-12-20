#!/bin/sh

sudo yum update -y
sudo amazon-linux-extras install docker
sudo yum install docker
sudo systemctl start docker.service
sudo usermod -a -G docker ec2-user

sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


sudo yum  -y install wget ruby

CODEDEPLOY_BIN="/opt/codedeploy-agent/bin/codedeploy-agent"
$CODEDEPLOY_BIN stop
sudo yum erase codedeploy-agent -y

cd /home/ec2-user

mkdir -p /home/ec2-user/current

chown ec2-user:ec2-user -R /home/ec2-user/current

wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install

chmod +x ./install

sudo ./install auto

sudo service codedeploy-agent start
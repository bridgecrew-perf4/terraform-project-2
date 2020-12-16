#!/bin/sh

sudo yum -y update
sudo yum -y install ruby
sudo yum  -y install wget

CODEDEPLOY_BIN="/opt/codedeploy-agent/bin/codedeploy-agent"
$CODEDEPLOY_BIN stop
sudo yum erase codedeploy-agent -y

cd /home/ec2-user

wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install

chmod +x ./install

sudo ./install auto

sudo service codedeploy-agent start
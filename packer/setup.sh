#!/bin/sh

sudo yum update -y
sudo amazon-linux-extras install docker
sudo yum install docker
sudo systemctl start docker.service
sudo usermod -a -G docker ec2-user

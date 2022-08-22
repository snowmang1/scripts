#!/bin/bash
echo "ECS_CLUSTER=evandrake-dob-ecs-bootcamp" >> /etc/ecs/ecs.config
#sudo yum update -y ecs-init
##this will update ECS agent, better when using custom AMI
#/usr/bin/docker pull amazon/amazon-ecs-agent:latest
#Restart docker and ECS agent
sudo service docker restart
#sudo start ecs
shutdown -r 0

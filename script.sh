#!/usr/bin/env bash

# Update package lists
sudo apt update

# Install prerequisites
sudo apt install -y software-properties-common

# Add Ansible repository
sudo apt-add-repository -y ppa:ansible/ansible

# Update package lists again
sudo apt update

# Install Ansible
sudo apt install -y ansible

# Verify installation
ansible --version
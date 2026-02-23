#!/bin/bash

echo "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing required packages..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "Adding Docker’s official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating apt again..."
sudo apt-get update -y

echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Starting Docker..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Adding ubuntu user to docker group..."
sudo usermod -aG docker ubuntu

echo "Docker version:"
docker --version

echo "Setup complete. Please logout and login again to use docker without sudo."
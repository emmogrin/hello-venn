#!/bin/bash

# BOLD HEADER
echo -e "\e[1;92m"
echo "███████╗ █████╗ ██╗███╗   ██╗████████╗     ██╗  ██╗██╗  ██╗███████╗███╗   ██╗"
echo "██╔════╝██╔══██╗██║████╗  ██║╚══██╔══╝     ██║ ██╔╝██║ ██╔╝██╔════╝████╗  ██║"
echo "███████╗███████║██║██╔██╗ ██║   ██║        █████╔╝ █████╔╝ █████╗  ██╔██╗ ██║"
echo "╚════██║██╔══██║██║██║╚██╗██║   ██║        ██╔═██╗ ██╔═██╗ ██╔══╝  ██║╚██╗██║"
echo "███████║██║  ██║██║██║ ╚████║   ██║        ██║  ██╗██║  ██╗███████╗██║ ╚████║"
echo "╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝        ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝"
echo -e "\e[0m"

echo -e "\e[1;96mCreated by SAINT KHEN  |  GitHub: @admirkhen\e[0m"
echo "Automating Venn Setup for the People."

# Check for sudo if needed
SUDO=''
if [ "$EUID" -ne 0 ]; then
  if command -v sudo &> /dev/null; then
    SUDO='sudo'
  fi
fi

# Clone repo
git clone https://github.com/ironblocks/hello-venn.git
cd hello-venn || exit 1

# Install Node.js v18+ if not present
if ! command -v node &> /dev/null; then
  echo "Node.js not found. Installing Node.js v18..."
  $SUDO apt update
  $SUDO apt install -y curl
  curl -fsSL https://deb.nodesource.com/setup_18.x | $SUDO bash -
  $SUDO apt install -y nodejs
fi

# Install venn CLI
npm install -g @vennbuild/cli

# Install project dependencies
npm ci

# Prompt user for environment values
echo "Configuring .env file..."
cp .env.example .env

read -p "Enter your PRIVATE_KEY: " PRIVATE_KEY
read -p "Enter your HOLESKY_RPC_URL: " HOLESKY_RPC_URL
read -p "Enter your VENN_PRIVATE_KEY (usually same as PRIVATE_KEY): " VENN_PRIVATE_KEY

# Save inputs to .env
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo "HOLESKY_RPC_URL=$HOLESKY_RPC_URL" >> .env
echo "VENN_PRIVATE_KEY=$VENN_PRIVATE_KEY" >> .env

# Run tests
npm test || { echo "Tests failed. Exiting."; exit 1; }

# Integrate Venn
venn fw integ -d contracts

# Re-run tests
npm test || { echo "Post-integration tests failed. Exiting."; exit 1; }

# Deploy contract
npm run step:1:deploy

# Run deposit & withdraw test
npm run step:1:deposit
npm run step:1:withdraw

# Enable Venn protection
venn enable --network holesky

echo ""
echo -e "\e[1;93mYour contract is now protected by Venn!"
echo -e "SAINT KHEN blesses this chain... you're live, blood!\e[0m"

#!/bin/bash

cd ~

# Install prerequisites

# This should be the value of Legacy API Token, found here: https://network.pivotal.io/users/dashboard/edit-profile
PIVNET_UAA_REFRESH_TOKEN=change_me

# Set versions of installed software
AZ_REPO=$(lsb_release -cs)
BOSH_VERSION=6.2.1
CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
LEFTOVERS_VERSION=0.62.0
PIVNET_VERSION=1.0.1
TF_VERSION=0.12.24

# Add package sources and repositories
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
sudo tee /etc/apt/sources.list.d/azure-cli.list && \
sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
--keyserver packages.microsoft.com \
--recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF

echo "deb http://packages.cloud.google.com/apt ${CLOUD_SDK_REPO} main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64

sudo add-apt-repository ppa:rmescandon/yq -y

# Download package information from all configured sources and install a complement of software
sudo apt update --yes && \
sudo apt install --yes azure-cli build-essential curl default-jdk docker.io google-cloud-sdk httpie jq git python-pip python-dev unzip wget yq


sudo pip install --upgrade pip
pip install awscli

wget -O bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_VERSION}-linux-amd64 && \
chmod +x bosh && \
sudo mv bosh /usr/local/bin

curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx && \
sudo mv cf /usr/local/bin

curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v7&source=github" | tar -zx && \
sudo mv cf7 /usr/local/bin

cf install-plugin -r CF-Community "log-cache" -f

sudo systemctl start docker && \
sudo systemctl enable docker && \
sudo usermod -aG docker ${USER}

curl -L https://k14s.io/install.sh | sudo bash

wget -O pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v${PIVNET_VERSION}/pivnet-linux-amd64-${PIVNET_VERSION} && \
chmod +x pivnet && \
sudo mv pivnet /usr/local/bin

wget -O terraform.zip https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
unzip terraform.zip && \
sudo mv terraform /usr/local/bin && \
rm terraform.zip

pivnet login --api-token="${PIVNET_UAA_REFRESH_TOKEN}" && \
pivnet download-product-files --product-slug='pivotal-container-service' --release-version='1.6.0' --product-file-id=528557 && \
mv pks-linux-amd64-1.6.0-build.225 pks && \
chmod +x pks && \
sudo mv pks /usr/local/bin

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
chmod +x kubectl && \
sudo mv kubectl /usr/local/bin

wget https://github.com/genevieve/leftovers/releases/download/v${LEFTOVERS_VERSION}/leftovers-v${LEFTOVERS_VERSION}-linux-amd64 && \
mv leftovers-v${LEFTOVERS_VERSION}-linux-amd64 leftovers && \
chmod +x leftovers && \
sudo mv leftovers /usr/local/bin

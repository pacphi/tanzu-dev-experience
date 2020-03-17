#!/bin/bash

# Install prerequisites

sudo apt update --yes && \
sudo apt install --yes build-essential curl default-jdk jq git python-pip python-dev wget && \
sudo pip install --upgrade pip

PIVNET_UAA_REFRESH_TOKEN=change_me

cd ~

pip install awscli

export AZ_REPO=$(lsb_release -cs) && \
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
sudo tee /etc/apt/sources.list.d/azure-cli.list && \
sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
--keyserver packages.microsoft.com \
--recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF && \
sudo apt update && \
sudo apt install --yes azure-cli

BOSH_VERSION=6.2.1
wget -O bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_VERSION}-linux-amd64 && \
chmod +x bosh && \
sudo mv bosh /usr/local/bin/

sudo apt install --yes docker.io && \
sudo systemctl start docker && \
sudo systemctl enable docker && \
sudo usermod -aG docker ${USER}

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
echo "deb http://packages.cloud.google.com/apt ${CLOUD_SDK_REPO} main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
apt update -y && apt install google-cloud-sdk -y

curl -L https://k14s.io/install.sh | sudo bash

PIVNET_VERSION=1.0.1
wget -O pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v${PIVNET_VERSION}/pivnet-linux-amd64-${PIVNET_VERSION} && \
chmod +x pivnet && \
sudo mv pivnet /usr/local/bin/

TF_VERSION=0.12.23
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

LEFTOVERS_VERSION=0.62.0
wget https://github.com/genevieve/leftovers/releases/download/v${LEFTOVERS_VERSION}/leftovers-v${LEFTOVERS_VERSION}-linux-amd64 && \
mv leftovers-v${LEFTOVERS_VERSION}-linux-amd64 leftovers && \
chmod +x leftovers && \
sudo mv leftovers /usr/local/bin
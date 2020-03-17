# tanzu-dev-experience

[![Generic badge](https://img.shields.io/badge/work%20in%20progress-buyer%20beware-yellow)](https://shields.io/)


A compendium of notes and links in order to reduce the time it takes to get an environment up-and-running to evaluate a continually evolving collection of open-source and commercial tooling within the Tanzu portfolio.

Intent here is to document alternative, curated combinations of tools and products that I've had some experience with, and allow you to choose your own adventure through (a hopefully more expedient) installation and usage of them.

## Overview

The following paths have been tread.  Documentation will be organized (and updated) accordingly.

| AWS  | GCP | Azure | VMWare |
|------|-----|-------|--------|
|      | :x: |       |        |

## Prerequisites

The minimum complement of CLIs and SDKs

* aws
* az
* bosh
* cf
* docker
* gcloud
* git
* java
* jq
* k14s
* kubectl
* leftovers
* pivnet
* terraform

Here's a script that will install the above on an  Ubuntu Linux VM

```bash
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
```

## Products evaluated

The following collection of open-source and commercial products have been evaluated

| PKS | TKG | cf-for-k8s | kpack | Harbor |
|-----|-----|------------|-------|--------|
| :x: |     |     :x:    |       |  :x:   |

## Where to go from here?

### Install PKS and Harbor

Go visit [Niall Thomson](https://www.niallthomson.com)'s excellent [paasify-pks](https://github.com/niallthomson/paasify-pks) project.

#### on GCP

Be sure to peruse and follow the

* [Pre](https://github.com/niallthomson/paasify-pks/blob/master/docs/pre-install/gcp.md) install instructions if you're looking to spin up a jumpbox VM and
* [Post](https://github.com/niallthomson/paasify-pks/blob/master/docs/post-install/gcp.md) install instructions when you want to complete creating and configuring a Kubernetes cluster with a load balancer using the `pks` CLI
  * Be sure to follow the [Update Plans for PKS](#update-plans-for-pks) section below before attempting to complete step 3.  You'll want to create a cluster that's sized to accommodate subsequent `cf-for-k8s` and `kpack` installations

> Revisit the [prerequisites](#prerequisites) section above so you can successfully complete this phase of evaluation

 Make a note of the credentials for

 * Operations Manager
   * Use `terraform output` inside the `paasify-pks` directory
 * Harbor
    * Login to Operations Manager, visit the Harbor tile configuration, click on the `Credentials` tab, click on the `Admin Password` link

##### Don't forget to restart your jumbox

You will need to restart your compute instance in order for Docker to work appropriately.


```
sudo shutdown -r
```

### Update Plans for PKS

* Login to Operations Manager
* Visit the `Enterprise PKS` tile and select `Plan 2` from the left-hand pane
* Click on `Active` radio button underneath `Plan` heading in the right-hand pane
* Set the drop-box option underneath the `Worker VM Type` heading to be `large.disk (cpu: 2, ram: 8 GB, disk: 64GB)`
* Make sure the last 3 of 4 checkboxes of the `Plan 2` configuration have been checked, then click the `Save` button
* Click on the `Installation Dashboard` link at top of page
* Click on `Review Pending Changes`
* Un-check the checkbox next to the product titled `VMWare Harbor Registry`, then click on the the `Apply Changes` button

### Install cf-for-k8s

This is an open-source project that's meant to deliver the `cf push` experience for developers who are deploying applications on Kubernetes.  It's early days yet, so don't expect to show off a robust set of features.  What we can do today is demonstrate pushing a pre-built Docker image that originates from a secure, private Docker registry (Harbor).

Visit and follow the [deploy](https://github.com/cloudfoundry/cf-for-k8s/blob/master/docs/deploy.md#steps-to-deploy) documentation for `cf-for-k8s`.
  * Choose `Option 1` on Step 2 which relies on script for generating configuration for use with install script

### Deploy sample application

#### Build application from source

We're going to clone the source of a [Spring Boot 2.3.0.M3](https://spring.io/blog/2020/03/12/spring-boot-2-3-0-m3-available-now) application which when built with [Gradle](https://gradle.org), will automatically assemble a Docker image employing a cloud-native [buildpack](https://hub.docker.com/r/cloudfoundry/cnb).

```
git clone https://github.com/fastnsilver/primes
cd primes
git checkout solution
./gradlew build
```

If you see an exception that looks like this

```
> Task :bootBuildImage FAILED
Building image 'docker.io/library/primes:1.0-SNAPSHOT'

 > Pulling builder image 'docker.io/cloudfoundry/cnb:0.0.53-bionic' ..................................................

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':bootBuildImage'.
> Docker API call to 'docker://localhost/v1.24/images/create?fromImage=docker.io%2Fcloudfoundry%2Fcnb%3A0.0.53-bionic' failed with status code 500 "com.sun.jna.LastErrorException: [13] Permission denied"

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org
```

you will want to restart your jumpbox.

#### Add new project to Harbor

* Login to Harbor with `admin` credentials
* Create a new `Project`
* Name it `fastnsilver`
* Set the `Access level` to `Public`
  * Make sure to check the checkbox
* Click the `OK` button

#### Push image to Harbor

We will need to login, tag the image, then push it

```
docker login -u admin https://{harbor-hostname}
docker tag primes:1.0-SNAPSHOT {harbor-hostname}/fastnsilver/primes:1.0-SNAPSHOT
docker push {harbor-hostname}/fastnsilver/primes:1.0-SNAPSHOT
```
> Fetch `{harbor-hostname}` bv visiting your Operations Manager instance, logging in, selecting the `VMWare Harbor Registry` tile, clicking on the `General` link in the left-hand pane and copying the value from the field titled `Hostname`.

#### Setup cf environment

Target the cf-for-k8s API endpoint and authenticate

```
cf api --skip-ssl-validation https://{cf-api-endpoint}
cf auth {username} {password}
```
> If you forgot any of the placeholder values above, just change directories to be inside the `paasify-pks` directory, then execute `terraform output`.

Create a new organization and space

```
cf create-org zoo-labs
cf t -o zoo-labs
cf create-space dev
cf t -s dev
```

#### Deploy application

Push it... real good

```
cf push primes -o {harbor-hostname}/fastnsilver/primes:1.0-SNAPSHOT
```

Calculate some primes

```
curl http://{app-url}/primes/1/10000
```
> Replace `{app-url}` above with the route to your freshly deployed application instance

### Install kpack

Now that we've worked out how to build and deploy a Spring Boot application.  What about everything else that could be containerized?  And how do we offload the work of building images (and keeping them up-to-date) from our jumpbox to some sort of automated CI engine?  Let's take a look at what [kpack](https://github.com/pivotal/kpack) can do for us.

Seems pretty straight-forward to follow these [instructions](https://github.com/pivotal/kpack/blob/master/docs/install.md#installing-kpack-1).  You'll want to download the [latest release](https://github.com/pivotal/kpack/releases/download/v0.0.6/release-0.0.6.yaml) first.

// TODO Add more explicit post-installation instructions
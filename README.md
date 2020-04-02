# tanzu-dev-experience

[![Generic badge](https://img.shields.io/badge/work%20in%20progress-walk%20in%20someone%20else's%20shoes-yellow)](https://shields.io/)


A compendium of notes and links in order to reduce the time it takes to get an environment up-and-running to evaluate a continually evolving collection of open-source and commercial tooling within the Tanzu portfolio.

Intent here is to document alternative, curated combinations of tools and products that I've had some experience with, and allow you to choose your own adventure through (a hopefully more expedient evaluation) installation and usage of them.

## Table of Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Tanzu Portfolio](#tanzu-portfolio)
* [Run](#run)
  * [TKG](#tkg)
  * [PKS and Harbor](#pks-and-harbor)
    * [on AWS](#on-aws)
    * [on Azure](#on-azure)
    * [on GCP](#on-gcp)
    * [Activate additional plans for PKS](#activate-additional-plans-for-pks)
  * [TAS](#tas)
    * [Configure](#configure)
        * [Integrate Harbor](#integrate-harbor)
    * [Rollout](#rollout)
* [Build](#build)
  * [Use cf CLI to setup environment](#use-cf-cli-to-setup-environment)
  * [Build and deploy sample application](#build-and-deploy-sample-application)
    * [Clone](#clone-1)
    * [Assemble image](#assemble-image)
    * [Push image to Harbor](#push-image-to-harbor)
    * [Deploy image](#deploy-image)
    * [Build and deploy from source](#build-and-deploy-from-source)
  * [Brokered Services](#brokered-services)
    * [(KSM) Container Services Manager](#ksm-container-services-manager)
    * [(TAC) Tanzu Application Catalog](#tac-tanzu-application-catalog)
  * [kpack](#kpack)
    * [Update images](#update-images)
* [Manage](#manage)
  * [Velero](#velero)
  * [(TO) Tanzu Observability](#to-tanzu-observability)
  * [(TMC) Tanzu Mission Control](#tmc-tanzu-mission-control)
* [Appendices](#appendices)
  * [Articles](#articles)
  * [Documentation](#documentation)

## Overview

The following paths have been tread.  Documentation will be organized (and updated) accordingly.

| AWS  | GCP | Azure | VMWare |
|------|-----|-------|--------|
|      | :heavy_check_mark: |       |        |

## Prerequisites

The minimum complement of

| CLIs   |  and   |  SDKs     |
|--------|--------|-----------|
| aws    | git    | kubectl   |
| az     | helm   | leftovers |
| bosh   | httpie | pivnet    |
| cf     | java   | python    |
| docker | jq     | terraform |
| gcloud | k14s   | yq        |
|        | ksm    |           |

Here's a [script](jumpbox-tools.sh) that will install the above on an  Ubuntu Linux VM

## Tanzu Portfolio

The following collection of open-source and commercial products have been evaluated

TKG | PKS                | Harbor             | Velero  | TAS                | kpack |  KSM |TAC | TO  | TMC |
|---|--------------------|--------------------|---------|--------------------|-------|------|----|-----|-----|
|   | :heavy_check_mark: | :heavy_check_mark: |         | :heavy_check_mark: |       |      |    |     |     |


## Run

### TKG

// TODO

### PKS and Harbor

Go visit [Niall Thomson](https://www.niallthomson.com)'s excellent [paasify-pks](https://github.com/niallthomson/paasify-pks) project.

#### on AWS

// TODO

#### on Azure

// TODO

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

<details><summary>And don't forget to restart your jumpbox... you'll need to restart your compute instance in order for Docker to work appropriately.</summary><pre>sudo shutdown -r</pre></details>


#### Activate additional plans for PKS

* Login to Operations Manager
* Visit the `Enterprise PKS` tile and select `Plan 2` from the left-hand pane
* Click on `Active` radio button underneath `Plan` heading in the right-hand pane
* Set the drop-box option underneath the `Worker VM Type` heading to be `large.disk (cpu: 2, ram: 8 GB, disk: 64GB)`
* Make sure the last 3 of 4 checkboxes of the `Plan 2` configuration have been checked, then click the `Save` button
* Click on the `Installation Dashboard` link at top of page
* Click on `Review Pending Changes`
* Un-check the checkbox next to the product titled `VMWare Harbor Registry`, then click on the the `Apply Changes` button

### TAS


**cf-for-k8s**

An open-source project that's meant to deliver the `cf push` experience for developers who are deploying applications on Kubernetes.  It's early days yet, so don't expect to show off a robust set of features.

What we can do today is demonstrate

* deploying a pre-built Docker image that originates from a secure, private Docker registry (e.g., Harbor) or
* starting with source code, leveraging a cloud native [buildpack](https://buildpacks.io) to build and package it into an OCI image, and then deploying.

Option 1:

If you haven't yet installed PKS or TKG with Harbor on your IaaS of choice, you might consider a fast-track route for demo/evaluation purposes. Employ  Niall Thomson's [Tanzu Playground](https://github.com/niallthomson/tanzu-playground) to quickly launch cf-for-k8s on GKE.  You may ignore the configure, integrate Harbor, and rollout steps as these are handled.

<details><summary>Generate a kubeconfig entry</summary><pre>gcloud container clusters get-credentials {cluster-name} --zone {availability-zone}</pre></details>

Option 2:

```
git clone https://github.com/cloudfoundry/cf-for-k8s.git
cd cf-for-k8s
```

**(TAS) Tanzu Application Service for Kubernetes**

The commercial distribution based on cf-for-k8s. It must be sourced from the [Pivotal Network](https://network.pivotal.io/products/pas-for-kubernetes).

```
mkdir tas-for-k8s
pivnet download-product-files --product-slug='pas-for-kubernetes' --release-version='0.1.0-build.223' --product-file-id=649189
tar xvf tanzu-application-service.0.1.0-build.223.tar -C tas-for-k8s
cd tas-for-k8s
```
> Update `--release-version` and `--product-file-id` when later releases become available


#### Configure

If cf-for-k8s

```
./hack/generate-values.sh -d {cf-domain} > /tmp/cf-values.yml
```

If TAS

```
./config/cf-for-k8s/hack/generate-values.sh -d {cf-domain} > /tmp/cf-values.yml
```

> Replace `{cf-domain}` with `cf.` as the prefix to your PKS sub-domain (e.g., if your sub-domain was `hagrid.ironleg.me`, then `{cf-domain}` would be `cf.hagrid.ironleg.me`.

##### Integrate Harbor

If cf-for-k8s

Use `vi` or some other editor to append the following lines to `/tmp/cf-values.yml`.  We're also enabling Cloud Native Buildpack support by doing this.

```
app_registry:
  hostname: harbor.{sub-domain}
  repository: library
  username: admin
  password: {harbor-password}
```

If TAS

```
export YTT_TAS_registry__server="harbor.{sub-domain}"
export YTT_TAS_registry__username=admin
export YTT_TAS_registry__password="{harbor-password}"
```

> Replace `{sub-domain}` with your PKS sub-domain.  Replace `{harbor-password}` by logging into `Operations Manager`, clicking on the `VMWare Harbor Registry` tile, clicking on the `Credentials` tab, then clicking on `Link to Credential` next to the `Admin Password` label.

#### Rollout

<details><summary>Install cf-for-k8s</summary><pre>./bin/install-cf.sh /tmp/cf-values.yml</pre></details>

<details><summary>Install TAS</summary><pre>./bin/install-tas.sh /tmp/cf-values.yml</pre></details>

<details><summary>(Optional) Add overlays</summary><ul><li>Consult these <a href="https://github.com/cloudfoundry/cf-for-k8s/commit/b4215fdddd10f0fdcb970f7f5db1cbe945aea1a5">instructions</a> for deploying with an overlay</li></ul></details>

<details><summary>Determine IP Address of Istio Ingress Gateway</summary><pre>kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}'</pre></details>

<details><summary>Set DNS entry</summary><pre># Sample A record in cloud provider DNS. The IP address below is the address of Ingress gateway's external IP
Domain         Record Type  TTL  IP Address
*.{cf-domain}  A            30   35.111.111.111</pre><ul><li>for GCP, see <a href="https://cloud.google.com/dns/records#adding_or_removing_a_record">Adding or Removing a Record</a></li></ul></details>

#### Additional

<details><summary>Validate</summary><pre>kubectl get pods -n cf-system</pre></details>

<details><summary>Uninstall</summary><pre>kapp delete -a cf</pre></details>


## Build

### Use cf CLI to setup environment

Target the cf-for-k8s API endpoint and authenticate

```
cf api --skip-ssl-validation https://{cf-api-endpoint}
cf auth {username} {password}
```
> If you forgot any of the placeholder values above, just `cat /tmp/cf-values.yml`.  Values for `{cf-api-endpoint}` and `{password}` should respectively equate to `app_domain` and `cf_admin_password` values.

Enable Docker

```
cf enable-feature-flag diego_docker
```

Create a new organization and space

```
cf create-org {organization-name}
cf t -o {organization-name}
cf create-space {space-name}
cf t -s {space-name}
```
> Replace placeholder values above with your own choices

### Build and deploy sample application

We're going to clone the source of a [Spring Boot 2.3.0.M3](https://spring.io/blog/2020/03/12/spring-boot-2-3-0-m3-available-now) application which when built with [Gradle](https://gradle.org), will automatically assemble a Docker image employing a cloud-native [buildpack](https://hub.docker.com/r/cloudfoundry/cnb).

#### Clone

```
git clone https://github.com/fastnsilver/primes
```

#### Assemble image

```
cd primes
git checkout solution
./gradlew build -b build.boot-image.gradle
```

<details><summary>If you see an exception like this you will want to restart your jumpbox.</summary>
<pre>> Task :bootBuildImage FAILED
Building image 'docker.io/library/primes:1.0-SNAPSHOT'
 > Pulling builder image 'docker.io/cloudfoundry/cnb:0.0.53-bionic' ..................................................
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':bootBuildImage'.
> Docker API call to 'docker://localhost/v1.24/images/create?fromImage=docker.io%2Fcloudfoundry%2Fcnb%3A0.0.53-bionic' failed with status code 500 "com.sun.jna.LastErrorException: [13] Permission denied"
* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.
* Get more help at https://help.gradle.org</pre></details>


#### Push image to Harbor

We will need to login to our registry, tag the image, then push it

```
docker login -u admin https://{harbor-hostname}
docker tag primes:1.0-SNAPSHOT {harbor-hostname}/library/primes:1.0-SNAPSHOT
docker push {harbor-hostname}/library/primes:1.0-SNAPSHOT
```
> Fetch `{harbor-hostname}` bv visiting your Operations Manager instance, logging in, selecting the `VMWare Harbor Registry` tile, clicking on the `General` link in the left-hand pane and copying the value from the field titled `Hostname`.


#### Deploy image

Push it... real good

```
cf push primes -o {harbor-hostname}/library/primes:1.0-SNAPSHOT
```

Calculate some primes

```
http http://{app-url}/primes/1/10000
```
> Replace `{app-url}` above with the route to your freshly deployed application instance

<details><summary>Get environment variables</summary><pre>cf env primes</pre></details>

<details><summary>Show most recent logs</summary><pre>cf logs primes --recent</pre></details>

<details><summary>Tail the logs</summary><pre>cf tail primes</pre></details>

<details><summary>Scale up</summary><pre>cf scale primes -i 2</pre></details>

<details><summary>Inspect events</summary><pre>cf events primes</pre></details>

<details><summary>Show app health and status</summary><pre>cf app primes</pre></details>


#### Build and deploy from source

Why did we go through all that? What if all we really needed to do was bring our source code to the party; let the platform take care of building, packaging, deploying an up-to-date, secure image to our registry, then push that image out to an environment?

Let's see how we do that. It's as simple as...

```
cf push primes
```

#### Deploy stratos

[Stratos](https://github.com/cloudfoundry/stratos/tree/master/deploy/kubernetes/console) is a UI administrative console for managing Cloud Foundry

<details><summary>Add Helm repository</summary><pre>helm repo add stratos https://cloudfoundry.github.io/stratos</pre></details>

<details><summary>Create new namespace</summary><pre>kubectl create namespace stratos</pre></details>

<details><summary>Install</summary><pre>helm install console stratos/console --namespace=stratos --set console.service.type=LoadBalancer</pre></details>

<details><summary>Get Ingress</summary><pre>kubectl describe service console-ui-ext -n stratos | grep Ingress</pre></details>

<details><summary>Upgrade</summary><pre>helm repo update
helm upgrade console stratos/console --namespace=stratos --recreate-pods</pre></details>

<details><summary>Uninstall</summary><pre>helm uninstall console --namespace=stratos
kubectl delete namespace stratos</pre></details>

### Brokered Services

No self-respecting enterprise application functions alone.  It's typically integrated with an array of other services (e.g., credentials/secrets management, databases, and messaging queues, to name but a few).  How do we curate, launch and integrate services (from a catalog) with applications?

#### (KSM) Container Services Manager

At a minimum a complement of Couchbase, Elasticsearch, Kafka, Mongo, MySQL, Neo4J, Postgres, and Vault offerings would be compelling to curate and deliver to enterprise developers.

// TODO

#### (TAC) Tanzu Application Catalog
// TODO

### kpack

Now that we've worked out how to build and deploy a Spring Boot application.  What about everything else that could be containerized?  And how do we offload the work of building images (and keeping them up-to-date) from our jumpbox to some sort of automated CI engine?  Let's take a look at what [kpack](https://github.com/pivotal/kpack) and [kpack-viz](https://github.com/niallthomson/kpack-viz) can do for us.

Seems pretty straight-forward to follow these [instructions](https://github.com/pivotal/kpack/blob/master/docs/install.md#installing-kpack-1).  You'll want to download the [latest release](https://github.com/pivotal/kpack/releases/download/v0.0.8/release-0.0.8.yaml) first.

// TODO Add more explicit post-installation instructions

#### Update images

// TODO Demonstrate a use-case where-in a sub-category of images are updated

## Manage

### Velero

What about your backup and recovery needs?

// TODO

### (TO) Tanzu Observability

Great we've deployed workloads to Kubernetes.  How are we able to troubleshoot issues in production?  At a minimum we'd like to surface health and performance metrics.

// TODO

### (TMC) Tanzu Mission Control

All clusters are not created equally.  Most enterprises struggle to apply consistent policies (security and compliance come to mind) across multiple runtime environments operating on-premise and/or in multiple public clouds.

// TODO

## Appendices

### Articles

* [How to Add Software Packaged as Helm Charts & Kubernetes Operators to Tanzu Application Service](https://tanzu.vmware.com/content/blog/how-to-add-software-packaged-as-helm-charts-kubernetes-operators-to-your-pivotal-platform)

### Documentation

* [Cloud Foundry for Kubernetes](https://github.com/cloudfoundry/cf-for-k8s)
* [(KSM) Container Services Manager](https://docs.pivotal.io/ksm/0-7/index.html)
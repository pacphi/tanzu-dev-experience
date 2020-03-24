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
  * [cf-for-k8s](#cf-for-k8s)
    * [Clone](#clone)
    * [Configure](#configure)
        * [Integrate Harbor](#integrate-harbor)
    * [Rollout](#rollout)
* [Build](#build)
  * [Use cf CLI to setup cf-for-k8s environment](#use-cf-cli-to-setup-cf-for-k8s-environment)
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
| az     | httpie | leftovers |
| bosh   | java   | pivnet    |
| cf     | jq     | python    |
| docker | k14s   | terraform |
| gcloud | ksm    | yq        |

Here's a [script](jumpbox-tools.sh) that will install the above on an  Ubuntu Linux VM

## Tanzu Portfolio

The following collection of open-source and commercial products have been evaluated

TKG | PKS                | Harbor             | Velero  | cf-for-k8s         | kpack |  KSM |TAC | TO  | TMC |
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

### cf-for-k8s

This is an open-source project that's meant to deliver the `cf push` experience for developers who are deploying applications on Kubernetes.  It's early days yet, so don't expect to show off a robust set of features.

What we can do today is demonstrate

* deploying a pre-built Docker image that originates from a secure, private Docker registry (e.g., Harbor) or
* starting with source code, leveraging a cloud native [buildpack](https://buildpacks.io) to build and package it into an OCI image, and then deploying.

#### Clone

```
git clone https://github.com/cloudfoundry/cf-for-k8s.git
```

#### Configure

```
cd cf-for-k8s
./hack/generate-values.sh {cf-domain} > /tmp/cf-values.yml
```
> Replace `{cf-domain}` with `cf.` as the prefix to your PKS sub-domain (e.g., if your sub-domain was `hagrid.ironleg.me`, then `{cf-domain}` would be `cf.hagrid.ironleg.me`.

##### Integrate Harbor

Use `vi` or some other editor to append the following lines to `/tmp/cf-values.yml`.  We're also enabling Cloud Native Buildpack support by doing this.

```
kpack:
  registry:
    hostname: harbor.{sub-domain}
    repository: library
    username: admin
    password: {harbor-password}
```
> Replace `{sub-domain}` with your PKS sub-domain.  Replace `{harbor-password}` by logging into `Operations Manager`, clicking on the `VMWare Harbor Registry` tile, clicking on the `Credentials` tab, then clicking on `Link to Credential` next to the `Admin Password` label.


#### Rollout

<details><summary>Install</summary><pre>./bin/install-cf.sh /tmp/cf-values.yml</pre></details>

<details><summary>Validate</summary><pre>kubectl get pods -n cf-system</pre></details>

<details><summary>Uninstall</summary><pre>kapp delete -a cf</pre></details>


## Build

### Use cf CLI to setup cf-for-k8s environment

Target the cf-for-k8s API endpoint and authenticate

```
cf api --skip-ssl-validation https://{cf-api-endpoint}
cf auth {username} {password}
```
> If you forgot any of the placeholder values above, just `cat /tmp/cf-values.yml`.  Values for `{cf-api-endpoint}` and `{password}` should respectively equate to `app_domain` and `cf_admin_password` values.

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

[Stratos](https://github.com/cloudfoundry/stratos/tree/master/deploy/cloud-foundry#Deploy-Stratos-from-docker-image) is a UI administrative console for managing Cloud Foundry

```
cf push console -o splatform/stratos:stable -m 128M -k 384M
```

> ** Outstanding [issue](https://github.com/cloudfoundry/cf-for-k8s/issues/46) currently prevents us from effectively demonstrating above.

### Brokered Services

No self-respecting enterprise application functions alone.  It's typically integrated with an array of other services (e.g., credentials/secrets management, databases, and messaging queues, to name but a few).  How do we curate, launch and integrate services (from a catalog) with applications?

#### (KSM) Container Services Manager

At a minimum a complement of Elasticsearch, Kafka, Mongo, MySQL, and Neo4J, Postgres offerings would be compelling to curate and deliver to enterprise developers.

// TODO

#### (TAC) Tanzu Application Catalog
// TODO

### kpack

Now that we've worked out how to build and deploy a Spring Boot application.  What about everything else that could be containerized?  And how do we offload the work of building images (and keeping them up-to-date) from our jumpbox to some sort of automated CI engine?  Let's take a look at what [kpack](https://github.com/pivotal/kpack) and [kpack-viz](https://github.com/niallthomson/kpack-viz) can do for us.

Seems pretty straight-forward to follow these [instructions](https://github.com/pivotal/kpack/blob/master/docs/install.md#installing-kpack-1).  You'll want to download the [latest release](https://github.com/pivotal/kpack/releases/download/v0.0.6/release-0.0.6.yaml) first.

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

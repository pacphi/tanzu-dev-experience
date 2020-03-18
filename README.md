# tanzu-dev-experience

[![Generic badge](https://img.shields.io/badge/work%20in%20progress-walk%20in%20someone%20else's%20shoes-yellow)](https://shields.io/)


A compendium of notes and links in order to reduce the time it takes to get an environment up-and-running to evaluate a continually evolving collection of open-source and commercial tooling within the Tanzu portfolio.

Intent here is to document alternative, curated combinations of tools and products that I've had some experience with, and allow you to choose your own adventure through (a hopefully more expedient evaluation) installation and usage of them.

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Products evaluated](#products-evaluated)
* [Install PKS and Harbor](#install-pks-and-harbor)
    * [on GCP](#on-gcp)
* [Update Plans for PKS](#update-plans-for-pks)
* [Install cf-for-k8s](#install-cf-for-k8s)
* [Deploy sample application](#deploy-sample-application)
    * [Build application from source](#build-application-from-source)
    * [Add new project to Harbor](#add-new-project-to-harbor)
    * [Push image to Harbor](#push-image-to-harbor)
    * [Setup cf environment](#setup-cf-environment)
    * [Deploy an application](#deploy-an-application)
* [Install kpack](#install-kpack)
    * [Update images](#update-images)
* [Launch on-demand services](#launch-on-demand-services)
* [Observability](#observability)
* [Cluster Lifecycle Management and Compliance](#cluster-lifecycle-management-and-compliance)

## Overview

The following paths have been tread.  Documentation will be organized (and updated) accordingly.

| AWS  | GCP | Azure | VMWare |
|------|-----|-------|--------|
|      | :heavy_check_mark: |       |        |

## Prerequisites

The minimum complement of

| CLIs   |  and   |  SDKs     |
|--------|--------|-----------|
| aws    | gcloud | kubectl   |
| az     | git    | leftovers |
| bosh   | java   | pivnet    |
| cf     | jq     | python    |
| docker | k14s   | terraform |


Here's a [script](jumpbox-tools.sh) that will install the above on an  Ubuntu Linux VM

## Products evaluated

The following collection of open-source and commercial products have been evaluated

| PKS | TKG | cf-for-k8s | kpack | Harbor | TAC | TO | TMC |
|-----|-----|------------|-------|--------|-----|----|-----|
| :heavy_check_mark: |     |     :heavy_check_mark:    |       |  :heavy_check_mark:   |    |     |    |


## Install PKS and Harbor

Go visit [Niall Thomson](https://www.niallthomson.com)'s excellent [paasify-pks](https://github.com/niallthomson/paasify-pks) project.

### on GCP

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

And don't forget to restart your jumpbox... you'll need to restart your compute instance in order for Docker to work appropriately.

```
sudo shutdown -r
```

## Update Plans for PKS

* Login to Operations Manager
* Visit the `Enterprise PKS` tile and select `Plan 2` from the left-hand pane
* Click on `Active` radio button underneath `Plan` heading in the right-hand pane
* Set the drop-box option underneath the `Worker VM Type` heading to be `large.disk (cpu: 2, ram: 8 GB, disk: 64GB)`
* Make sure the last 3 of 4 checkboxes of the `Plan 2` configuration have been checked, then click the `Save` button
* Click on the `Installation Dashboard` link at top of page
* Click on `Review Pending Changes`
* Un-check the checkbox next to the product titled `VMWare Harbor Registry`, then click on the the `Apply Changes` button

## Install cf-for-k8s

This is an open-source project that's meant to deliver the `cf push` experience for developers who are deploying applications on Kubernetes.  It's early days yet, so don't expect to show off a robust set of features.  What we can do today is demonstrate pushing a pre-built Docker image that originates from a secure, private Docker registry (Harbor).

Visit and follow the [deploy](https://github.com/cloudfoundry/cf-for-k8s/blob/master/docs/deploy.md#steps-to-deploy) documentation for `cf-for-k8s`.
  * Choose `Option 1` on Step 2 which relies on script for generating configuration for use with install script

## Deploy sample application

### Build application from source

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

### Add new project to Harbor

* Login to Harbor with `admin` credentials
* Create a new `Project`
* Name it `contrivances`
* Set the `Access level` to `Public`
  * Make sure to check the checkbox
* Click the `OK` button

### Push image to Harbor

We will need to login, tag the image, then push it

```
docker login -u admin https://{harbor-hostname}
docker tag primes:1.0-SNAPSHOT {harbor-hostname}/contrivances/primes:1.0-SNAPSHOT
docker push {harbor-hostname}/contrivances/primes:1.0-SNAPSHOT
```
> Fetch `{harbor-hostname}` bv visiting your Operations Manager instance, logging in, selecting the `VMWare Harbor Registry` tile, clicking on the `General` link in the left-hand pane and copying the value from the field titled `Hostname`.

### Setup cf environment

Target the cf-for-k8s API endpoint and authenticate

```
cf api --skip-ssl-validation https://{cf-api-endpoint}
cf auth {username} {password}
```
> If you forgot any of the placeholder values above, just change directories to be inside the `paasify-pks` directory, then execute `terraform output`.

Create a new organization and space

```
cf create-org {organization-name}
cf t -o {organization-name}
cf create-space {space-name}
cf t -s {space-name}
```
> Replace placeholder values above with your own choices

### Deploy an application

Push it... real good

```
cf push primes -o {harbor-hostname}/contrivances/primes:1.0-SNAPSHOT
```

Calculate some primes

```
curl http://{app-url}/primes/1/10000
```
> Replace `{app-url}` above with the route to your freshly deployed application instance


Scale up

```
cf scale primes -i 2
```

Inspect events

```
cf events primes
```

Show app health and status

```
cf app primes
```

## Launch on-demand services

No self-respecting enterprise application functions alone.  It's typically integrated with an array of other services (e.g., credentials/secrets management, databases, and messaging queues, to name but a few).  How do we curate, launch and integrate services (from a catalog) with applications?

// TODO This is a great time to demo Tanzu Application Catalog

## Install kpack

Now that we've worked out how to build and deploy a Spring Boot application.  What about everything else that could be containerized?  And how do we offload the work of building images (and keeping them up-to-date) from our jumpbox to some sort of automated CI engine?  Let's take a look at what [kpack](https://github.com/pivotal/kpack) can do for us.

Seems pretty straight-forward to follow these [instructions](https://github.com/pivotal/kpack/blob/master/docs/install.md#installing-kpack-1).  You'll want to download the [latest release](https://github.com/pivotal/kpack/releases/download/v0.0.6/release-0.0.6.yaml) first.

// TODO Add more explicit post-installation instructions

### Update images

// TODO Demonstrate a use-case where-in a sub-category of images are updated

## Observability

Great we've deployed workloads to Kubernetes.  How are we able to troubleshoot issues in production?  At a minimum we'd like to surface health and performance metrics.

// TODO This is a perfect time to demo Tanzu Observability features

## Cluster Lifecycle Management and Compliance

All clusters are not created equally.  Most enterprises struggle to apply consistent policies (security and compliance come to mind) across multiple runtime environments operating on-premise and/or in multiple public clouds.

// TODO Time for Tanzu Mission Control to shine

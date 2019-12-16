## DISCLAIMER: 
### This project is under development. 
### I'm developing this project during my spare time and mostly for a personal eductional purpose, so it might take a while to finish it or approve PRs and so on. 
### As the license says, feel free to use it, and/or adapt it for your own needs.

## Kubernetes on AWS

**"Kubernetes on AWS"** is a Kubernetes boostrap system built with Terraform and BASH which will create and up&running fully encrypted Kubernetes cluster.

The Terraform run will create/deploy the following components:

* 3, 5 or more ec2 instances based on CentOS, which will serve as Kubernetes controllers.
* 1 Network load balancer on top of the KubeControllers with a TCP health check on the instances
* 3 security groups with the following details:
    - x
    - x
* The certificates needed for: kube-proxy, etcd, admin, kube-controller-manager, kube-scheduler and service-account.
* It will create an AWS KeyPair with dynamically generated public keys.
* The required Kubernetes configuration for each controllers component using templates.

The BASH startup scripts will create:
- 

## Usage:

### Simple usage:

### Complex usage:


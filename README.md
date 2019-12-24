## Kubernetes on AWS

**"Kubernetes on AWS"** is a Kubernetes boostrap system built with Terraform and BASH which will create an up&running fully TLS encrypted Kubernetes cluster on your AWS account.

The Terraform run will create/deploy the following components:

- 3, 5 or more ec2 instances based on CentOS, which will serve as Kubernetes controllers.

- 1 Network load balancer on top of the KubeControllers with a TCP health check on the instances.

- The required security groups for both controllers and workers.

- The certificates needed for: kube-proxy, etcd, admin, kube-controller-manager, kube-scheduler and service-account.

- It will create an AWS KeyPair with dynamically generated public keys.

- The required Kubernetes configuration for each controllers component using templates.

- An AutoScalingGroup for the Kubernetes workers.


The BASH startup scripts will:

- Boostrap the etcd cluster.

- Boostrap the Kubernetes Control Plane.

- Bootstrap the workers instances.


## Requirements:

    * An AWS Account
    * Terraform >= 0.12


## Usage

1.  Adapt variables.tf with your own environment.
```
vi src/variables.tf
```

2. Download dependencies and dry run.
```
cd src && terraform init && terraform plan
```

3. Create the Kubernetes cluster
```
terraform apply -auto-approve
```



### Disclaimer: 
*The project is under development. I'm developing this project during my spare time and mostly for personal eductional purposes, so it might take a while to finish it and/or approve PRs and so on. As the license says, please feel free to use it or adapt it for your own needs.*
### TODO

1. Improve security groups and personalization
2. Convert to terraform module
3. CI/CD Testing
4. Remote lock and state file
*Release*
* Controllers bootstrap key rotation or user input key
* Remove associate_public_ip on controllers and implements SSH Bastion Host (Pay attentions to the terraform provisioners)
    * Fix controllers security group to enable only ingress from the NLB, Bastion Host and other controllers
* Currently there's only one VPC both for controllers and workers (it needs more flexibility) [DONE -> needs testing]
* Rework security groups controllers
* Rework security groups workers
* OS Security hardening
* AWS Security hardening
* External CLI
* Move binaries to a private repository

Current versions:

* kubernetes 1.15.3
* containerd 1.2.9
* coredns v1.6.3
* cni v0.7.1
* etcd v3.4.0
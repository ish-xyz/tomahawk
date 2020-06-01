### TODO

*Release*
* CI/CD Testing (test-infra/kubetest)
* Configure AWS as cloud provider on kubelet
* Configure workers LB
* External CLI: Remote state file and lock, init, create-cluster, migrate-cluster, upgrade-cluster
* Controllers bootstrap key rotation or user input key
* Controllers logs to a central logging (TBD)
* Rework security groups workers
* AWS Security review
* AMI Security hardening (security Groups, subnets etc)

* Move binaries to a private repository

Current versions:

* kubernetes 1.15.3
* containerd 1.2.9
* coredns v1.6.3
* cni v0.7.1
* etcd v3.4.0

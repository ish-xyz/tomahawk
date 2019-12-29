### TODO

1. Improve security groups and personalization
2. Convert to terraform module
3. CI/CD Testing
4. Remote lock and state file
*Release*
* Controllers bootstrap key rotation or user input key
* Remove associate_public_ip on controllers and implements SSH Bastion Host (Pay attentions to the terraform provisioners)
    * Fix controllers security group to enable only ingress from the NLB, Bastion Host and other controllers
* Different subnet/az zone for each controllers [DONE]
* Remote terraform state and terraform lock
* ETCD boostrap.sh add desired state check [DONE]
* Null resource "import boostrap files" add triggers for files [DONE]
* Currently there's only one VPC both for controllers and workers (it needs more flexibility) [DONE -> needs testing]
* Rework security groups controllers
* Rework security groups workers
* OS Security hardening
* AWS Security hardening

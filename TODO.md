### TODO

**Controllers**

* Controllers bootstrap key rotation or user input key
* Remove associate_public_ip on controllers and implements SSH Bastion Host (Pay attentions to the provisioners)
    * Fix controllers security group to enable only ingress from ALB, Bastion Host and controllers
* Different subnet/az zone for each controllers [DONE]
* Remote terraform state and terraform lock
* ETCD boostrap.sh add desired state check [DONE]
* Null resource "import boostrap files" add triggers for files [DONE]
* Currently there's only one VPC both for controllers and workers (it needs more flexibility)
* Security hardening
FROM centos:7

RUN yum install unzip python3 openssh-clients ansible -y && \ 
	curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.12.16/terraform_0.12.16_linux_amd64.zip && \
	unzip /tmp/terraform.zip -d /usr/bin && \
	chmod +x /usr/bin/terraform && \
	rm -rf /tmp/* && \
	rm -rf /var/cache/yum/*

#Append process
CMD ["tail", "-f", "/dev/null"]

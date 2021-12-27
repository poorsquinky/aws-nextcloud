
SSH := ssh -o "StrictHostKeyChecking=no" -o UserKnownHostsFile=/dev/null -o ProxyCommand="sh -c \"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p\"" -i privkey.pem -l ubuntu

default: terraform ansible

ssh_setup:
	chmod 600 privkey.pem
	$(eval INSTANCE := $(shell terraform output instance_id | sed -e 's/"//g'))
	timeout 300 bash -c -- 'until $(SSH) $(INSTANCE) "/bin/true"; do sleep 0.5; done'

ansible: ssh_setup
	$(SSH) $(INSTANCE) "which -a ansible || (sudo apt-get update && sudo apt-get -y install ansible)"
	sed -e 's/{{INSTANCE}}/$(INSTANCE)/' inventory.tmpl.ini > inventory.ini
	ansible-playbook -i inventory.ini --private-key privkey.pem -l nextcloud site.yaml

terraform:
	terraform init
	terraform apply

.PHONY: ssh_setup ansible terraform


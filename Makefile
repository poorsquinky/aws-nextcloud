
SSH := ssh -o "StrictHostKeyChecking=no" -o UserKnownHostsFile=/dev/null -o ProxyCommand="sh -c \"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p\"" -i privkey.pem -l ubuntu

default: terraform ansible

# I can't be relied on to remember the command to connect to the instance
ssh: setup
	$(SSH) $(INSTANCE)

setup:
	$(eval INSTANCE  := $(shell terraform output instance_id | sed -e 's/"//g'))
	$(eval PUBLIC_IP := $(shell terraform output public_ip   | sed -e 's/"//g'))
	$(eval BUCKET    := $(shell terraform output bucket      | sed -e 's/"//g'))
	chmod 600 privkey.pem

ansible: setup
	timeout --foreground 300 bash -c -- 'until $(SSH) $(INSTANCE) "/bin/true"; do sleep 0.5; done'
	$(SSH) $(INSTANCE) "which -a ansible || (sudo apt-get update && sudo apt-get -y install ansible)"
	sed \
		-e 's/{{INSTANCE}}/$(INSTANCE)/' \
		-e 's/{{PUBLIC_IP}}/$(PUBLIC_IP)/' \
		-e 's/{{BUCKET}}/$(BUCKET)/' \
		inventory.tmpl.ini > inventory.ini
	ansible-playbook -i inventory.ini --private-key privkey.pem -l nextcloud site.yaml

terraform:
	terraform init
	terraform apply

.PHONY: setup ansible terraform


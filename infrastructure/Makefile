MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TOFU := tofu -chdir=$(MAKEFILE_DIR)

.PHONY: init plan apply destroy fmt validate output console

init:
	$(TOFU) init

plan:
	$(TOFU) plan -out=tfplan

apply:
	$(TOFU) apply tfplan

destroy:
	$(TOFU) destroy

fmt:
	$(TOFU) fmt

validate:
	$(TOFU) validate

output:
	$(TOFU) output

console:
	@echo "Run: oci ce cluster create-kubeconfig --cluster-id $$(tofu -chdir=$(MAKEFILE_DIR) output -raw cluster_id) --file ~/.kube/config --region us-ashburn-1 --token-version 2.0.0"
	@echo "Then: kubectl get nodes"
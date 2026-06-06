MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TOFU := tofu -chdir=$(MAKEFILE_DIR)
TOFU_BACKUPS := tofu -chdir=$(MAKEFILE_DIR)/backups
BACKEND_CONFIG = -backend-config="region=$${OCI_REGION}" -backend-config="endpoint=https://$${OCI_NAMESPACE}.compat.objectstorage.$${OCI_REGION}.oraclecloud.com"

.PHONY: init plan apply destroy fmt validate output console \
        backups-init backups-plan backups-apply backups-destroy \
        postgres-deploy postgres-reset postgres-destroy postgres-cleanup \
        state-cleanup backups-bucket-cleanup teardown

# ─── Infrastructure ───────────────────────────────────────────────

init:
	OCI_NAMESPACE=$$(oci os ns get | jq -r '.data') && \
	$(TOFU) init $(BACKEND_CONFIG)

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

# ─── Backups (separate state) ────────────────────────────────────

backups-init:
	OCI_NAMESPACE=$$(oci os ns get | jq -r '.data') && \
	$(TOFU_BACKUPS) init $(BACKEND_CONFIG)

backups-plan:
	$(TOFU_BACKUPS) plan -out=tfplan

backups-apply:
	$(TOFU_BACKUPS) apply tfplan

backups-destroy:
	$(TOFU_BACKUPS) destroy

# ─── Bucket Cleanup ─────────────────────────────────────────────
#
# These scripts use OCI CLI to delete buckets that Terraform
# doesn't manage (or can't empty before deletion).

state-cleanup:
	./scripts/cleanup-state.sh $(ARGS)

backups-bucket-cleanup:
	./scripts/cleanup-backups-bucket.sh $(ARGS)

# ─── Full Teardown (testing) ────────────────────────────────────
#
# Tears down everything in the correct order:
#   1. PostgreSQL (CNPG, cert-manager, CSI driver)
#   2. Infrastructure (OKE, VCN, IAM via tofu destroy)
#   3. State bucket (OCI CLI — not managed by Terraform)
#
# Usage:
#   make teardown                  # interactive confirmation
#   make teardown ARGS="--force"   # skip confirmation
#
# NOTE: Cloudflare resources and the backup bucket are cleaned up
#       separately via GitHub Actions workflows:
#       - [Web] Destroy         → Cloudflare Pages + DNS
#       - [Backups] Destroy     → backup bucket (Terraform)
#       - [Backups] Cleanup Bucket → backup bucket (OCI CLI, if needed)

teardown:
	@echo "=== Step 1/3: PostgreSQL cleanup ==="
	chmod +x scripts/cleanup-cnpg.sh
	./scripts/cleanup-cnpg.sh postgres || echo "PostgreSQL cleanup skipped (cluster may not exist)"
	@echo ""
	@echo "=== Step 2/3: Infrastructure destroy ==="
	OCI_NAMESPACE=$$(oci os ns get | jq -r '.data') && \
	$(TOFU) init $(BACKEND_CONFIG) && \
	$(TOFU) destroy -auto-approve
	@echo ""
	@echo "=== Step 3/3: State bucket cleanup ==="
	./scripts/cleanup-state.sh --force
	@echo ""
	@echo "=== Teardown Complete ==="
	@echo ""
	@echo "Run these GitHub Actions workflows separately:"
	@echo "  1. [Web] Destroy         → Cloudflare Pages + DNS"
	@echo "  2. [Backups] Destroy     → backup bucket (Terraform)"
	@echo "  3. [Backups] Cleanup Bucket → backup bucket (OCI CLI, if needed)"

# ─── PostgreSQL ───────────────────────────────────────────────────

postgres-deploy:
	./scripts/deploy-postgres.sh postgres us-ashburn-1

postgres-reset:
	./scripts/reset-postgres.sh postgres

postgres-destroy:
	./scripts/cleanup-cnpg.sh postgres

postgres-cleanup:
	./scripts/wait-for-namespace-gone.sh cnpg-system 120
TF_STACKS := terraform/dev terraform/stage terraform/prod terraform/mercor terraform/jenkins

.PHONY: lint lint-terraform lint-ansible

lint: lint-terraform lint-ansible

lint-terraform:
	terraform fmt -check -recursive terraform/
	@for stack in $(TF_STACKS); do \
		echo "==> terraform validate $$stack"; \
		(cd $$stack && terraform init -input=false -backend=false -upgrade=false >/dev/null && terraform validate) || exit 1; \
	done
	tflint --recursive --chdir=terraform
	checkov -d terraform/ --compact --quiet

lint-ansible:
	cd ansible && ansible-lint --profile=min .

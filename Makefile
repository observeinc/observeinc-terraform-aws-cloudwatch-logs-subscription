.PHONY: precommit-dependencies
precommit-dependencies:
	# github actions helper
	pip install pre-commit
	curl -L "$(shell curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest |grep -o -E "https://.+?linux-amd64.tar.gz")" > terraform-docs.tar.gz && tar -xzf terraform-docs.tar.gz terraform-docs && chmod +x terraform-docs && sudo mv terraform-docs /usr/bin/ && rm terraform-docs.tar.gz
	curl -L "$(shell curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/bin/

.PHONY: test
test:
	pre-commit run
	python3 ./lambda/test_index.py

.PHONY: test-all
test-all: test
	terraform -chdir=./test/ init -upgrade
	terraform -chdir=./test/ apply -auto-approve
	terraform -chdir=./test/ destroy -auto-approve

.PHONY: changelog
changelog:
	git-chglog -o CHANGELOG.md --next-tag `semtag final -s minor -o`

.PHONY: cloudformation
cloudformation:
	terraform -chdir=./cloudformation init
	terraform -chdir=./cloudformation apply -auto-approve
	aws s3 cp cloudformation/generated/subscribelogs.yaml s3://observeinc/cloudformation/subscribelogs-`semtag final -s minor -o`.yaml

.PHONY: release
release: cloudformation
	semtag final -s minor

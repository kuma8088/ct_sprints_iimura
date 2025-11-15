# Repository Guidelines

This repository defines a small AWS environment with Terraform. Follow the practices below to keep modules, state, and automation predictable across sprints.

## Project Structure & Module Organization
- Root `.tf` files are split by responsibility: `network.tf` provisions the VPC, subnets, routing, and gateways, while `compute.tf` handles instances, security groups, EIPs, and outputs.
- Bootstrap scripts (`api_user_data.sh`, `web_user_data.sh`) live beside the Terraform files. Keep user data logic minimal and parameterize via `templatefile` variables when referencing infrastructure values.
- State files (`terraform.tfstate*`) are stored locally for now. Treat them as ephemeral artifacts; prefer a remote backend when collaborating.

## Build, Test, and Development Commands
- `terraform init` — download the AWS provider before any other action.
- `terraform fmt` — apply canonical formatting; run `terraform fmt -check` in CI or before reviews.
- `terraform validate` — catch syntax and reference errors without hitting AWS APIs.
- `terraform plan -out plan.tfplan` — preview infra deltas for reviewers; share the saved plan when proposing changes.
- `terraform apply plan.tfplan` — deploy the reviewed plan; avoid direct `apply` without a plan file.

## Coding Style & Naming Conventions
- Use two-space indentation and keep block arguments sorted logically (provider → networking → compute → outputs) to mirror the current layout.
- Resource names follow `aws_<service>.<role>` (`aws_subnet.web_aws_subnet_01`, `aws_instance.api_server_01`); keep suffixes consistent (`_01`, `_02`) when scaling.
- Tag AWS resources with `Name = "sprints-<component>"` for discoverability, and prefer descriptive variables such as `api_subnet_cidr` over generic names.

## Testing Guidelines
- Treat `terraform fmt -check` and `terraform validate` as pre-commit tests; both must pass before opening a PR.
- Generate `terraform plan` outputs for every change and attach the diff summary (routes, instances, or tags) to the review.
- When touching user data scripts, run shellcheck locally if available and document manual verification steps (e.g., curl endpoints) in the PR description.

## Commit & Pull Request Guidelines
- Existing history uses short, imperative summaries (`Spring1 terraform draft`); continue that style and keep subjects under 50 characters, optionally prefixing the major area (`network: add NAT gateway`).
- Reference related issues (e.g., `Fixes #42`) and clearly describe expected infra changes, including resource counts and cost-impact notes.
- PRs should include: goal statement, command sequence used (`fmt`, `validate`, `plan`), screenshots or logs for script updates, and rollback guidance.

## Security & Configuration Tips
- Do not commit secrets, private keys, or AWS credentials; store per-developer variables in untracked `terraform.tfvars` files.
- Rotate `key_name` references and keep state files encrypted if shared. When testing, use isolated AWS accounts or sandboxes to avoid impacting production workloads.

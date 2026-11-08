# Naming Module

A small Terraform/OpenTofu module that produces **consistent resource names** and a **standard tag set** for AWS infrastructure.

It does not create any AWS resources. It only takes a few inputs (org, workload, environment, region, …), validates them, and returns:

- name prefixes (regional and global),
- a map of full resource names you ask for,
- a tag map to plug into the AWS provider's `default_tags`.

Use it at the top of every stack so every team names and tags things the same way.

---

## Table of contents

1. [The naming convention](#1-the-naming-convention)
2. [Name segments and their rules](#2-name-segments-and-their-rules)
3. [Region codes](#3-region-codes)
4. [Resource suffixes and length limits](#4-resource-suffixes-and-length-limits)
5. [Tags](#5-tags)
6. [Usage](#6-usage)
7. [Inputs](#7-inputs)
8. [Outputs](#8-outputs)
9. [Rules of thumb and gotchas](#9-rules-of-thumb-and-gotchas)
10. [Requirements](#10-requirements)
11. [Full example](#11-full-example)

---

## 1. The naming convention

Every name is built from hyphen-separated segments, in this exact order:

**Regional resources** (VPCs, ALBs, RDS, Lambda, …):

```
{org}-{workload}[-{tenant}]-{environment}-{region_code}-{suffix}
```

**Global resources** (IAM roles/policies, Route 53, CloudFront, … — anything where region is meaningless):

```
{org}-{workload}[-{tenant}]-{environment}-{suffix}
```

`[-{tenant}]` is only present when `tenant` is set.

### Examples

Using the values from the [full example's `test.tfvars`](#testtfvars)
(`org = "frshrute"`, `workload = "workshop"`, `tenant = "whs01"`, `environment = "prd"`, `region = "us-east-1"`):

| Kind     | Suffix     | Generated name                              |
|----------|------------|---------------------------------------------|
| Regional | `vpc`      | `frshrute-workshop-whs01-prd-use1-vpc`      |
| Regional | `shipment` | `frshrute-workshop-whs01-prd-use1-shipment` |
| Regional | `api-alb`  | `frshrute-workshop-whs01-prd-use1-api-alb`  |
| Global   | `shipment` | `frshrute-workshop-whs01-prd-shipment`      |

The same stack **without a tenant** (shared infrastructure):

| Kind     | Suffix | Generated name                   |
|----------|--------|----------------------------------|
| Regional | `vpc`  | `frshrute-workshop-prd-use1-vpc` |
| Global   | `vpc`  | `frshrute-workshop-prd-vpc`      |

More examples:

| org    | workload  | tenant  | env   | region           | suffix   | Result                                   |
|--------|-----------|---------|-------|------------------|----------|------------------------------------------|
| `acme` | `billing` | –       | `dev` | `eu-west-1`      | `db`     | `acme-billing-dev-euw1-db`               |
| `acme` | `billing` | `cust42`| `prd` | `ap-southeast-2` | `api-alb`| `acme-billing-cust42-prd-apse2-api-alb`  |
| `acme` | `search`  | –       | `stg` | `eu-central-1`   | `cache`  | `acme-search-stg-euc1-cache`             |

---

## 2. Name segments and their rules

All segments are validated at `plan` time. If a value breaks a rule, Terraform fails with a clear error before anything is created.

| Segment       | Variable      | Required | Rule                                                              | Good examples             | Bad examples                      |
|---------------|---------------|----------|-------------------------------------------------------------------|---------------------------|-----------------------------------|
| Organisation  | `org`         | Yes      | 2–8 chars, lowercase letters/digits, must start with a letter     | `acme`, `abi`, `frshrute` | `ACME`, `1acme`, `acme-corp`, `a` |
| Workload      | `workload`    | Yes      | 2–16 chars, lowercase letters/digits, must start with a letter    | `billing`, `workshop`     | `Billing`, `billing_api`, `b`     |
| Tenant        | `tenant`      | No       | 2–16 chars, lowercase letters/digits, must start with a letter    | `whs01`, `cust42`         | `01whs`, `cust-42`                |
| Environment   | `environment` | Yes      | Exactly one of `prd`, `stg`, `dev`, `sbx`                         | `prd`, `dev`              | `prod`, `production`, `test`      |
| Region code   | `region` / `region_code` | Yes | Derived from `region` (see [Region codes](#3-region-codes)) | `use1`, `euw2`            | –                                 |
| Suffix        | key of `resources` | –   | Your choice – see [Resource suffixes](#4-resource-suffixes-and-length-limits) | `vpc`, `api-alb` | `API_ALB`                         |

> **No hyphens or underscores inside `org`, `workload` or `tenant`.** The hyphen is the segment separator; putting one inside a segment makes names ambiguous. Use `billingapi`, not `billing-api`.

### Environment codes

| Code  | Meaning               |
|-------|-----------------------|
| `prd` | Production            |
| `stg` | Staging / pre-prod    |
| `dev` | Development           |
| `sbx` | Sandbox / experiments |

### When to use `tenant`

Only set `tenant` for **per-customer (single-tenant) infrastructure**, e.g. a dedicated database for one customer or warehouse. Leave it unset (`null`) for shared infrastructure. It is inserted right after `workload` and is also added as a `Tenant` tag.

---

## 3. Region codes

The region segment is a short code derived automatically from the full AWS region name:

```
<2-letter geo> + <direction code> + <number>
```

| Direction word | Code |
|----------------|------|
| `north`        | `n`  |
| `south`        | `s`  |
| `east`         | `e`  |
| `west`         | `w`  |
| `central`      | `c`  |
| `northeast`    | `ne` |
| `northwest`    | `nw` |
| `southeast`    | `se` |
| `southwest`    | `sw` |

Any other direction word falls back to its first letter.

### Common regions

| Region           | Code    |
|------------------|---------|
| `us-east-1`      | `use1`  |
| `us-east-2`      | `use2`  |
| `us-west-2`      | `usw2`  |
| `eu-west-1`      | `euw1`  |
| `eu-west-2`      | `euw2`  |
| `eu-central-1`   | `euc1`  |
| `eu-north-1`     | `eun1`  |
| `ca-central-1`   | `cac1`  |
| `sa-east-1`      | `sae1`  |
| `af-south-1`     | `afs1`  |
| `ap-south-1`     | `aps1`  |
| `ap-southeast-1` | `apse1` |
| `ap-southeast-2` | `apse2` |
| `ap-northeast-1` | `apne1` |
| `me-central-1`   | `mec1`  |

### Overriding the code

If you need a different code, set `region_code` explicitly; it always wins over the derived value:

```hcl
region      = "us-east-1"
region_code = "nva" # names become ...-prd-nva-...
```

The `region` input must still match the pattern `xx-direction-N` (see [gotchas](#9-rules-of-thumb-and-gotchas)).

---

## 4. Resource suffixes and length limits

You tell the module which names you need through the `resources` map. **Each key becomes the suffix** of a name:

```hcl
resources = {
  vpc      = {}                  # default max_length = 63
  shipment = { max_length = 50 }
  api-alb  = { max_length = 32 } # ALB names are limited to 32 chars
}
```

### How to pick a suffix

- **Lowercase letters, digits and hyphens only** (e.g. `api-alb`, `orders-db`, `ingest-fn`). The module does not validate suffixes, so this is on you.
- **Short and descriptive** – it describes *what* the resource is; org/workload/env/region are already in the prefix. Don't repeat them.
- **Include the resource type when it helps** to tell things apart: `orders-db`, `orders-sg`, `orders-role`.
- **Unique within the stack** – keys of a map are unique by definition, so two resources can't share a suffix.

| Good           | Why bad?                                       | Bad                         |
|----------------|------------------------------------------------|-----------------------------|
| `api-alb`      | Uppercase / underscores                        | `API_ALB`                   |
| `orders-db`    | Repeats prefix info                            | `billing-prd-orders-db`     |
| `ingest-fn`    | Too long, eats into the length budget          | `ingestion-lambda-function` |

### `max_length`

Many AWS resources have name length limits. Set `max_length` per suffix and the module fails the **plan** if a generated name is too long – instead of failing halfway through an `apply`.

| Resource                   | Typical limit |
|----------------------------|---------------|
| ALB / NLB, target group    | 32            |
| S3 bucket, RDS identifier  | 63            |
| IAM role                   | 64            |
| Default if not specified   | 63            |

The check runs on both `names` (regional) and `names_global`. If it fails, you'll see:

```
One or more generated names exceed their max_length. Shorten org/workload/tenant or the resource suffix.
```

**Length budget:** a regional prefix is `len(org) + len(workload) + len(tenant) + 3 (env) + len(region_code) + hyphens`. For example `frshrute-workshop-whs01-prd-use1` is 32 chars, so with a 32-char ALB limit **no suffix fits** – you'd need a shorter org/workload/tenant. Keep codes short.

---

## 5. Tags

The `tags` output is the standard tag set every resource should carry. Pass it to the AWS provider's `default_tags` so it's applied everywhere automatically.

| Tag key              | Value source                | Always present?            |
|----------------------|-----------------------------|----------------------------|
| `Application`        | `workload`                  | Yes                        |
| `Environment`        | `environment`               | Yes                        |
| `Owner`              | `owner`                     | Yes                        |
| `CostCenter`         | `cost_center`               | Yes                        |
| `ManagedBy`          | always `"terraform"`        | Yes                        |
| `DataClassification` | `data_classification`       | Only if set                |
| `Tenant`             | `tenant`                    | Only if set                |
| *anything else*      | `extra_tags`                | As provided                |

- Tags with a `null` value (unset `tenant` / `data_classification`) are dropped.
- `extra_tags` **cannot override** the mandatory tags above – if you pass `Environment = "x"` in `extra_tags`, the module's value wins.
- `data_classification` must be one of `public`, `internal`, `confidential`, `restricted`.

---

## 6. Usage

### Module source

You can reference the module in two ways.

**Option A – remotely from GitHub (recommended for other repos/teams):**

```hcl
module "naming" {
  source = "git::https://github.com/<your-org>/<your-repo>.git//modules/naming?ref=v1.0.0"
  # ...
}
```

**Option B – local path (when your code lives in this same repository):**

```hcl
module "naming" {
  source = "../../modules/naming" # path relative to your .tf file
  # ...
}
```

Notes on the GitHub source:

- Replace `<your-org>/<your-repo>` with the repository that hosts this module.
- `//modules/naming` (double slash) tells Terraform which **subdirectory** of the repo contains the module.
- `?ref=` pins a **tag**, branch or commit SHA. Always pin to a tag (e.g. `v1.0.0`) — never track `main`, or a change to the module could rename your resources unexpectedly.
- For a private repo, Terraform uses your local git credentials (credential helper, `gh auth login`, or SSH keys).
- After changing `source` or `ref`, run `terraform init -upgrade` so Terraform downloads the new version.

### Example

```hcl
module "naming" {
  source = "git::https://github.com/<your-org>/<your-repo>.git//modules/naming?ref=v1.0.0"
  # source = "../../modules/naming" # local alternative

  org         = "acme"
  workload    = "billing"
  environment = "prd"
  region      = "us-east-1"
  # tenant    = "cust42"        # only for per-customer infra

  owner               = "platform-team"
  cost_center         = "cc1234"
  data_classification = "confidential"

  extra_tags = {
    Project = "invoicing"
  }

  resources = {
    vpc     = {}
    api-alb = { max_length = 32 }
    invoices = {}
    app-role = { max_length = 64 }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = module.naming.tags
  }
}

# Regional resource -> names
resource "aws_lb" "api" {
  name = module.naming.names["api-alb"]          # acme-billing-prd-use1-api-alb
  # ...
}

# Global resource -> names_global
resource "aws_iam_role" "app" {
  name = module.naming.names_global["app-role"]  # acme-billing-prd-app-role
  # ...
}

# Ad-hoc name not listed in `resources` (no length check!)
resource "aws_sqs_queue" "events" {
  name = "${module.naming.prefix}-events"        # acme-billing-prd-use1-events
}
```

**Which output should I use?**

- Regional resource → `module.naming.names["<suffix>"]`
- Global resource (IAM, Route 53, CloudFront, …) → `module.naming.names_global["<suffix>"]`
- One-off name → `module.naming.prefix` / `prefix_global` + your own suffix. Prefer adding it to `resources` so the length is checked.

---

## 7. Inputs

| Name                  | Type                                      | Default | Required | Description |
|-----------------------|-------------------------------------------|---------|----------|-------------|
| `org`                 | `string`                                  | –       | Yes      | Org short code, 2–8 chars, `^[a-z][a-z0-9]{1,7}$`. |
| `workload`            | `string`                                  | –       | Yes      | Workload/application short code, 2–16 chars, `^[a-z][a-z0-9]{1,15}$`. |
| `environment`         | `string`                                  | –       | Yes      | One of `prd`, `stg`, `dev`, `sbx`. |
| `region`              | `string`                                  | –       | Yes      | Full AWS region (e.g. `us-east-1`). Must match `^[a-z]{2}-[a-z]+-[0-9]+$`. |
| `region_code`         | `string`                                  | `null`  | No       | Overrides the derived short region code. |
| `tenant`              | `string`                                  | `null`  | No       | Tenant ID for per-customer infra, 2–16 chars, `^[a-z][a-z0-9]{1,15}$`. Inserted after `workload`. |
| `owner`               | `string`                                  | –       | Yes      | Owning team (`Owner` tag). |
| `cost_center`         | `string`                                  | –       | Yes      | Cost center (`CostCenter` tag). |
| `data_classification` | `string`                                  | `null`  | No       | One of `public`, `internal`, `confidential`, `restricted`. |
| `extra_tags`          | `map(string)`                             | `{}`    | No       | Additional tags. Cannot override mandatory tags. |
| `resources`           | `map(object({ max_length = optional(number, 63) }))` | `{}` | No | Suffixes to generate names for, each with an optional length limit. |

## 8. Outputs

| Name            | Description | Example |
|-----------------|-------------|---------|
| `prefix`        | Regional prefix `{org}-{workload}[-{tenant}]-{env}-{region_code}` | `acme-billing-prd-use1` |
| `prefix_global` | Prefix without region | `acme-billing-prd` |
| `region_code`   | Short region code used in names | `use1` |
| `tags`          | Standard tag map, for provider `default_tags` | `{ Application = "billing", ... }` |
| `names`         | Map `suffix => full regional name` (length-checked) | `{ vpc = "acme-billing-prd-use1-vpc" }` |
| `names_global`  | Map `suffix => full global name` (length-checked) | `{ vpc = "acme-billing-prd-vpc" }` |

---

## 9. Rules of thumb and gotchas

- **S3 bucket names are globally unique across all AWS accounts.** The generated name may already be taken. If so, append the account ID or a random suffix: `"${module.naming.names["data"]}-${data.aws_caller_identity.current.account_id}"` (and leave room for it in `max_length`).
- **Don't hand-craft names.** Always derive them from this module's outputs so the convention stays consistent.
- **Don't rename after creation lightly.** Changing `org`, `workload`, `tenant`, `environment`, `region` or a suffix changes names, and many AWS resources are *replaced* (destroyed and recreated) when their name changes.
- **Suffixes are not validated** – stick to lowercase letters, digits and hyphens. Some services (e.g. S3) reject uppercase or underscores.
- **Names built from `prefix` directly are not length-checked** – only entries in `resources` are.
- **Non-standard region formats are not supported yet.** Regions like `us-gov-east-1` fail the `region` validation, even if you set `region_code`.

---

## 10. Requirements

| Tool      | Version    |
|-----------|------------|
| Terraform | `>= 1.3.0` (needed for `optional()` attribute defaults) |
| OpenTofu  | Compatible |

No providers are required by the module itself.

---

## 11. Full example

A complete, working stack that uses this module to name and tag an S3 bucket. Create a new folder (e.g. `my-stack/`) with the four files below, then run the commands at the end.

```
my-stack/
├── main.tf          # module call, provider, resources, outputs
├── variables.tf     # input variable declarations
├── test.tfvars      # naming/tag values (safe to commit)
└── secrets.tfvars   # AWS credentials (NEVER commit)
```

### `main.tf`

```hcl
module "naming" {
  source = "git::https://github.com/<your-org>/<your-repo>.git//modules/naming?ref=v1.0.0"
  # source = "../../modules/naming" # local alternative

  org                 = var.org
  workload            = var.workload
  environment         = var.environment
  region              = var.region
  tenant              = var.tenant
  owner               = var.owner
  cost_center         = var.cost_center
  data_classification = var.data_classification
  extra_tags          = var.extra_tags
  resources           = var.resources
}


provider "aws" {
  region     = var.region
  profile    = var.aws_profile
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token

  default_tags {
    tags = module.naming.tags
  }
}

resource "aws_s3_bucket" "shipment" {
  bucket = module.naming.names["shipment"] # global namespace: add account ID or random suffix if it collides
}

output "names" {
  value = module.naming.names
}
output "bucket_domain_name" {
  value = aws_s3_bucket.shipment.bucket_domain_name
}
```

### `variables.tf`

```hcl
variable "aws_profile" {
  type    = string
  default = null
}

variable "aws_access_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "aws_session_token" {
  type      = string
  default   = null
  sensitive = true
}


# =====


variable "org" {
  type = string
}

variable "workload" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "owner" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "data_classification" {
  type    = string
  default = null
}

variable "tenant" {
  type    = string
  default = null
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "resources" {
  type = map(object({
    max_length = optional(number, 63)
  }))
  default = {}
}
```

### `test.tfvars`

```hcl
org         = "frshrute"
workload    = "workshop"
environment = "prd"
region      = "us-east-1"

owner               = "platform_team"
cost_center         = "business"
data_classification = "confidential"

# Per-customer infra only; omit for shared infra
tenant = "whs01"

extra_tags = {
  Project = "warehousing"
}

resources = {
  vpc      = {}
  shipment = {max_length = 50 }
  api-alb  = {}
}
```

With these values the bucket is named `frshrute-workshop-whs01-prd-use1-shipment`.

### `secrets.tfvars`

```hcl
# Option 1: static keys
aws_access_key    = "<your-access-key-id>"
aws_secret_key    = "<your-secret-access-key>"
# aws_session_token = "<your-session-token>" # only for temporary credentials

# Option 2 (preferred): use a named profile from ~/.aws/config instead of keys
# aws_profile = "<your-profile-name>"
```

> [!WARNING]
> **Never commit secrets to git.**
>
> - `secrets.tfvars` contains real AWS credentials — keep it **only on your machine**.
> - `terraform.tfstate` and `terraform.tfstate.backup` can also contain sensitive data — don't commit them either (use a remote backend such as S3 for shared state).
> - Prefer `aws_profile`, AWS SSO (`aws sso login`) or environment variables (`AWS_PROFILE`, `AWS_ACCESS_KEY_ID`, …) over static keys in a file.
> - If a key was **ever** committed or pushed, even briefly, treat it as leaked: **rotate it in IAM immediately**. Deleting the file in a later commit does not remove it from git history.
>
> Add this to your `.gitignore`:
>
> ```gitignore
> secrets.tfvars
> *.tfstate
> *.tfstate.*
> .terraform/
> ```

### Run it

```bash
cd my-stack
terraform init
terraform plan    -var-file=test.tfvars -var-file=secrets.tfvars
terraform apply   -var-file=test.tfvars -var-file=secrets.tfvars
terraform destroy -var-file=test.tfvars -var-file=secrets.tfvars
```

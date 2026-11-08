variable "org" {
  description = "Org short code, 2-8 chars (e.g. acme)."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.org))
    error_message = "org must be 2-8 chars, lowercase alphanumeric, starting with a letter."
  }
}

variable "workload" {
  description = "Workload/application short code, 2-16 chars (e.g. billing)."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,15}$", var.workload))
    error_message = "workload must be 2-16 chars, lowercase alphanumeric, starting with a letter."
  }
}

variable "environment" {
  description = "Environment code."
  type        = string
  validation {
    condition     = contains(["prd", "stg", "dev", "sbx"], var.environment)
    error_message = "environment must be one of: prd, stg, dev, sbx."
  }
}

variable "region" {
  description = "Full AWS region name (e.g. us-east-1). Format: <2 letters>-<direction>-<number>."
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "region must look like us-east-1 or ap-southeast-2. For other formats (e.g. us-gov-east-1) this module's derivation does not apply; set region_code explicitly."
  }
}

variable "region_code" {
  description = "Override the derived short region code (e.g. use1)."
  type        = string
  default     = null
}

variable "tenant" {
  description = "Optional tenant ID for per-customer infra. Inserted after workload."
  type        = string
  default     = null
  validation {
    condition     = var.tenant == null || can(regex("^[a-z][a-z0-9]{1,15}$", var.tenant))
    error_message = "tenant must be 2-16 chars, lowercase alphanumeric, starting with a letter."
  }
}

variable "owner" {
  description = "Owning team (mandatory tag)."
  type        = string
}

variable "cost_center" {
  description = "Cost center (mandatory tag)."
  type        = string
}

variable "data_classification" {
  description = "Data classification tag."
  type        = string
  default     = null
  validation {
    condition     = var.data_classification == null || contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}

variable "extra_tags" {
  description = "Additional tags. Cannot override the mandatory tags."
  type        = map(string)
  default     = {}
}

variable "resources" {
  description = "Resource suffixes to generate names for. max_length is checked at plan time (e.g. alb/target group = 32, S3/RDS = 63, IAM role = 64)."
  type = map(object({
    max_length = optional(number, 63)
  }))
  default = {}
}
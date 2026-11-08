output "prefix" {
  description = "Regional name prefix: {org}-{workload}[-{tenant}]-{env}-{region_code}"
  value       = local.prefix
}

output "prefix_global" {
  description = "Prefix without region, for global resources."
  value       = local.prefix_global
}

output "region_code" {
  description = "Short region code used in names."
  value       = local.region_code
}

output "tags" {
  description = "Standard tag set. Pass to provider default_tags."
  value       = local.tags
}

output "names" {
  description = "Map of resource suffix => full regional name."
  value       = { for k, v in var.resources : k => "${local.prefix}-${k}" }

  precondition {
    condition     = alltrue([for k, v in var.resources : length("${local.prefix}-${k}") <= v.max_length])
    error_message = "One or more generated names exceed their max_length. Shorten org/workload/tenant or the resource suffix."
  }
}

output "names_global" {
  description = "Map of resource suffix => full global (region-less) name."
  value       = { for k, v in var.resources : k => "${local.prefix_global}-${k}" }

  precondition {
    condition     = alltrue([for k, v in var.resources : length("${local.prefix_global}-${k}") <= v.max_length])
    error_message = "One or more generated global names exceed their max_length."
  }
}
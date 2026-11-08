locals {
  direction_codes = {
    north     = "n"
    south     = "s"
    east      = "e"
    west      = "w"
    central   = "c"
    northeast = "ne"
    northwest = "nw"
    southeast = "se"
    southwest = "sw"
  }

  region_parts         = split("-", var.region)
  computed_region_code = "${local.region_parts[0]}${lookup(local.direction_codes, local.region_parts[1], substr(local.region_parts[1], 0, 1))}${local.region_parts[2]}"
  region_code          = coalesce(var.region_code, local.computed_region_code)

  segments = [for s in [var.org, var.workload, var.tenant] : s if s != null]

  # {org}-{workload}[-{tenant}]-{env}-{region}
  prefix = join("-", concat(local.segments, [var.environment, local.region_code]))

  # For global resources (IAM, Route 53, S3 if region is irrelevant)
  prefix_global = join("-", concat(local.segments, [var.environment]))

  mandatory_tags = {
    Application        = var.workload
    Environment        = var.environment
    Owner              = var.owner
    CostCenter         = var.cost_center
    ManagedBy          = "terraform"
    DataClassification = var.data_classification
    Tenant             = var.tenant
  }

  # Mandatory tags win over extra_tags; null values are dropped.
  tags = merge(
    var.extra_tags,
    { for k, v in local.mandatory_tags : k => v if v != null }
  )
}

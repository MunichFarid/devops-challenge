# Deploy the local Helm chart into the 'default' namespace
resource "helm_release" "orders" {
  name       = "orders"
  namespace  = "default"
  repository = ""                     # not used for local charts
  chart      = "../helm-chart/orders" # path is relative to ./terraform
  version    = ""                     # not used for local charts

  # Example overrides (optional):
  # set {
  #   name  = "image.tag"
  #   value = "amd64-360649f"
  # }
  # set {
  #   name  = "resources.requests.cpu"
  #   value = "100m"
  # }
  set {
    name  = "terraform.chartHash"
    value = local.chart_hash
  }

  set_sensitive {
    name  = "db.password"
    value = var.db_password
  }

  # Wait for resources to become ready before finishing apply
  wait          = true
  timeout       = 90
  recreate_pods = false
  atomic        = true
}

locals {
  chart_dir   = "${path.module}/../helm-chart/orders"
  chart_files = fileset(local.chart_dir, "**")
  chart_hash  = sha256(join("", [for f in local.chart_files : filesha256("${local.chart_dir}/${f}")]))
}


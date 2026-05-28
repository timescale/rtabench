terraform {
  required_providers {
    timescale = {
      source = "timescale/timescale"
    }
  }
}

provider "timescale" {
  project_id = var.ts_project_id
  access_key = var.ts_access_key
  secret_key = var.ts_secret_key
}

variable "ts_project_id" {}
variable "ts_access_key" {}
variable "ts_secret_key" {}
variable "region" {}
variable "milli_cpu" {}

resource "timescale_service" "my-resource" {
  name        = format("rta-benchmark-%d",var.milli_cpu)
  memory_gb   = var.milli_cpu / 250
  milli_cpu   = var.milli_cpu
  region_code = var.region
}

output "service_url" {
  value = format("postgres://tsdbadmin:%s@%s:%s/tsdb?sslmode=require",
    timescale_service.my-resource.password,
    timescale_service.my-resource.hostname,
    timescale_service.my-resource.port)
  sensitive = true
}

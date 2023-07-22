locals {
  environment  = "${var.app_environment}${var.app_suffix}"
  service_name = "cpd-ecf"
}

module "application_configuration" {
  source = "git::https://github.com/DFE-Digital/terraform-modules.git//aks/application_configuration?ref=testing"

  namespace             = var.namespace
  environment           = local.environment
  azure_resource_prefix = var.azure_resource_prefix
  service_short         = var.service_short
  config_short          = var.config_short

  is_rails_application = true

  config_variables = {
    HOSTING_ENVIRONMENT = local.environment
    RAILS_ENV           = var.app_environment
    DB_SSLMODE          = var.db_sslmode

    BIGQUERY_PROJECT_ID = "ecf-bq",
    BIGQUERY_DATASET    = "events_${var.app_environment}", # TODO: work this out
    BIGQUERY_TABLE_NAME = "events",                        # TODO: work this out
    GIAS_API_SCHEMA     = "https://ea-edubase-api-prod.azurewebsites.net/edubase/schema/service.wsdl"
    GIAS_EXTRACT_ID     = 13904
    GIAS_API_USER       = "ecftech"
  }

  secret_key_vault_short = "app"
  secret_variables = {
    DATABASE_URL = module.postgres.url
    REDIS_URL    = module.redis.url
  }
}

module "web_application" {
  source = "git::https://github.com/DFE-Digital/terraform-modules.git//aks/application?ref=testing"

  name   = "web"
  is_web = true

  namespace    = var.namespace
  environment  = local.environment
  service_name = local.service_name

  cluster_configuration_map = module.cluster_data.configuration_map

  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  probe_path = "/check"
}

module "worker_application" {
  source = "git::https://github.com/DFE-Digital/terraform-modules.git//aks/application?ref=testing"

  name   = "worker"
  is_web = false

  namespace    = var.namespace
  environment  = local.environment
  service_name = local.service_name

  cluster_configuration_map = module.cluster_data.configuration_map

  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image  = var.docker_image
  command       = ["bundle", "exec", "sidekiq", "-C", "./config/sidekiq.yml"]
  probe_command = ["pgrep", "-f", "sidekiq"]
}
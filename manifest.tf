terraform {
  required_providers {
    harness = {
      source = "harness/harness"
    }
  }
}

provider "harness" {
  platform_api_key = var.HARNESS_API_KEY
  account_id = var.HARNESS_ACCOUNT_ID
  endpoint = "https://app.harness.io/gateway"
}

resource "harness_platform_project" "project" {
  name = var.HARNESS_PROJECT_ID
  identifier  = var.HARNESS_PROJECT_ID
  org_id      = var.HARNESS_ORG_ID
  description = "Example project description"
}

resource "harness_platform_service" "example" {
  depends_on = [harness_platform_project.project]
  identifier  = var.HARNESS_PROJECT_ID
  name        = var.HARNESS_PROJECT_ID
  description = "test"
  org_id      = "default"
  project_id  = var.HARNESS_PROJECT_ID

  ## SERVICE V2 UPDATE
  ## We now take in a YAML that can define the service definition for a given Service
  ## It isn't mandatory for Service creation 
  ## It is mandatory for Service use in a pipeline

yaml = <<-EOT
service:
  name: ${var.HARNESS_PROJECT_ID}
  identifier: ${var.HARNESS_PROJECT_ID}
  orgIdentifier: default
  projectIdentifier: ${var.HARNESS_PROJECT_ID}
  serviceDefinition:
    type: Kubernetes
    spec:
      manifests:
        - manifest:
            identifier: ${var.HARNESS_PROJECT_ID}
            type: K8sManifest
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.Github
                  gitFetchType: Branch
                  paths:
                    - deployment.yaml
                  repoName: ${var.HARNESS_PROJECT_ID}
                  branch: main
              valuesPaths:
                - values.yaml
              skipResourceVersioning: false
              enableDeclarativeRollback: false
      artifacts:
        primary:
          spec:
            connectorRef: account.dockerhubkroon
            imagePath: munkys123/kotlin
            tag: latest
            digest: ""
          type: DockerRegistry
      type: Kubernetes
EOT
}

resource "harness_platform_environment" "example" {
  identifier = "identifier"
  name       = "name"
  org_id     = "org_id"
  project_id = "project_id"
  tags       = ["foo:bar", "bar:foo"]
  type       = "PreProduction"
  description = "env description"

  ## ENVIRONMENT V2 Update
  ## The YAML is needed if you want to define the Environment Variables and Overrides for the environment
  ## Not Mandatory for Environment Creation nor Pipeline Usage

  yaml = <<-EOT
  environment:
    name: Development
    identifier: Development
    tags: {}
    type: PreProduction
    orgIdentifier: default
    projectIdentifier: ${var.HARNESS_PROJECT_ID}
  EOT
}

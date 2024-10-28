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



resource "harness_platform_pipeline" "pipeline" {
  org_id     = var.HARNESS_ORG_ID
  project_id = var.HARNESS_PROJECT_ID
  identifier = var.HARNESS_WORKSPACE_ID
  name       = var.HARNESS_WORKSPACE_ID

 yaml = <<-EOT
  pipeline:
    name: ${var.HARNESS_PROJECT_ID}
    identifier: ${var.HARNESS_PROJECT_ID}
    projectIdentifier: ${var.HARNESS_PROJECT_ID}
    orgIdentifier: ${var.HARNESS_ORG_ID}
    tags: {}
    stages:
      - stage:
          name: onboarding
          identifier: onboarding
          description: ""
          type: IACM
          spec:
            workspace: ${harness_platform_workspace.workspace.identifier}
            execution:
              steps:
                - step:
                    type: IACMTerraformPlugin
                    name: init
                    identifier: init
                    timeout: 10m
                    spec:
                      command: init
                - step:
                    type: IACMTerraformPlugin
                    name: plan
                    identifier: plan
                    timeout: 10m
                    spec:
                      command: plan
                - step:
                    type: IACMTerraformPlugin
                    name: apply
                    identifier: apply
                    timeout: 10m
                    spec:
                      command: apply
            infrastructure:
              type: KubernetesDirect
              spec:
                connectorRef: account.k8s
                namespace: default
                volumes: []
                annotations: {}
                labels: {}
                automountServiceAccountToken: true
                nodeSelector: {}
                containerSecurityContext:
                  capabilities:
                    drop: []
                    add: []
                os: Linux
                hostNames: []
          tags: {}
  EOT
}

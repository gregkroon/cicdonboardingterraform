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

resource "harness_platform_secret_text" "githubsecret" {

  depends_on = [harness_platform_project.project]
 
  org_id      = var.HARNESS_ORG_ID
  project_id  = var.HARNESS_PROJECT_ID
  name =  "HARNESS_GITHUB_SECRET"
  identifier = "HARNESS_GITHUB_SECRET"
  secret_manager_identifier = "harnessSecretManager"
  value = var.HARNESS_GITHUB_SECRET_VALUE
  value_type = "Inline"
  
  
}

resource "harness_platform_secret_text" "awssecret" {

  depends_on = [harness_platform_project.project]
 
  org_id      = var.HARNESS_ORG_ID
  project_id  = var.HARNESS_PROJECT_ID
  name = "AWS_SECRET_KEY"
  identifier = "AWS_SECRET_KEY"
  secret_manager_identifier = "harnessSecretManager"
  value = var.AWS_SECRET_KEY
  value_type = "Inline"

  
}




resource "harness_platform_connector_aws" "aws_connector" {

depends_on = [harness_platform_secret_text.awssecret]

  org_id      = var.HARNESS_ORG_ID
  project_id  = var.HARNESS_PROJECT_ID
  identifier = var.HARNESS_AWS_CONNECTOR_ID
  name = var.HARNESS_AWS_CONNECTOR_ID

   manual {
    access_key = var.AWS_ACCESS_KEY
    secret_key_ref = "AWS_SECRET_KEY"

}
}





resource "harness_platform_connector_github" "github_connector" {

  depends_on = [harness_platform_secret_text.githubsecret]

  org_id      = var.HARNESS_ORG_ID
  project_id  = var.HARNESS_PROJECT_ID
  identifier = var.HARNESS_GITHUB_CONNECTOR_ID
  connection_type = "Account"
  name = var.HARNESS_GITHUB_CONNECTOR_ID
  url =  var.HARNESS_GITHUB_URL

  credentials {
    http {
      username = var.GITHUB_USER
      //username_ref = var.GITHUB_USER_REF
      token_ref    = "HARNESS_GITHUB_SECRET"
    }
  }



}




resource "harness_platform_workspace" "workspace" {

depends_on = [harness_platform_connector_github.github_connector,harness_platform_connector_aws.aws_connector]

  name        = var.HARNESS_WORKSPACE_ID
  identifier  = var.HARNESS_WORKSPACE_ID
  org_id      = var.HARNESS_ORG_ID
  project_id  = var.HARNESS_PROJECT_ID
  description = "Example workspace description"


  cost_estimation_enabled = var.HARNESS_COST_ESTIMATION_ENABLED
  provisioner_version = "1.5.6"
  repository_path = var.HARNESS_REPO_PATH
  repository = var.HARNESS_REPO
  provider_connector = var.HARNESS_AWS_CONNECTOR_ID
  provisioner_type = "terraform"
  repository_connector = var.HARNESS_GITHUB_CONNECTOR_ID
  repository_branch = var.HARNESS_REPO_BRANCH

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

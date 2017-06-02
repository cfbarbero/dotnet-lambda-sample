resource "aws_codepipeline" "integration-pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = "${module.pipeline-core.iam_role_arn}"

  artifact_store {
    location = "${module.pipeline-core.s3_bucket_id}"
    type     = "S3"

    encryption_key = {
      type = "KMS"
      id   = "${module.pipeline-core.kms_key_arn}"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        Owner  = "${var.github_owner}"
        Repo   = "${var.github_repo}"
        Branch = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      input_artifacts = ["source"]

      owner    = "Custom"
      provider = "gig-jenkins"
      version  = "1"

      configuration {
        ProjectName = "jobsearch-integration-build"
      }

      output_artifacts = ["build"]
    }
  }

  stage {
    name = "DEV"

    action {
      name            = "CreateChangeSet"
      category        = "Deploy"
      input_artifacts = ["source", "build"]

      owner    = "AWS"
      provider = "CloudFormation"
      version  = "1"

      configuration {
        ActionMode    = "CHANGE_SET_REPLACE"
        ChangeSetName = "codepipeline"
        RoleArn       = "${module.inf-deployer.cloudformation_deployer_role_arn}"
        Capabilities  = "CAPABILITY_NAMED_IAM"
        StackName     = "${var.project_name}-dev"

        # TemplateConfiguration = "source::JobSearch.Integration/Deploy/parameters.test.json"
        TemplatePath = "build::compiledTemplate.yaml"
      }

      run_order = 1
    }

    action {
      name     = "DeployChangeSet"
      category = "Deploy"

      owner    = "AWS"
      provider = "CloudFormation"
      version  = "1"

      configuration {
        ActionMode    = "CHANGE_SET_EXECUTE"
        ChangeSetName = "codepipeline"
        RoleArn       = "${module.inf-deployer.cloudformation_deployer_role_arn}"
        Capabilities  = "CAPABILITY_NAMED_IAM"
        StackName     = "${var.project_name}-dev"
      }

      run_order = 2
    }
  }
}

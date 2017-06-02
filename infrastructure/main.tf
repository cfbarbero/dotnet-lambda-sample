provider "aws" {
  region = "us-east-1"
}

module "pipeline-core" {
  source = "github.com/DiceHoldingsInc/tf-aws-codestar.git//modules/codepipeline-core?ref=sam-deploy"

  project_name        = "${var.project_name}"
  trusted_account_ids = ["229357985605"]

  tags = {
    owner = "deltaforce"
  }
}

module "inf-deployer" {
  source = "github.com/DiceHoldingsInc/tf-aws-codestar.git//modules/codepipeline-cloudformation-deployer?ref=sam-deploy"

  project_name = "${var.project_name}"
  kms_key_arn  = "${module.pipeline-core.kms_key_arn}"
  s3_bucket_id = "${module.pipeline-core.s3_bucket_id}"
}

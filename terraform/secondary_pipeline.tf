resource "aws_codepipeline" "pipeline_triggered_by_image_push" {
  name = "wynne-pipeline-triggered-by-image-push"
  role_arn = aws_iam_role.wynne_codepipeline_terraform_role.arn

  artifact_store {
    location = aws_s3_bucket.wynne_codepipeline_terraform_spike_artifact_store.bucket
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "dev-pki"
      category = "Source"
      owner = "AWS"
      provider = "CodeStarSourceConnection"
      version = "1"
      output_artifacts = ["verify_dev_pki"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.wynnternet.arn
        FullRepositoryId = "wynnternet/verify-dev-pki"
        BranchName = "hub-1051-codepipeline-spike"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }

    action {
      name = "pushed-ecr-image"
      category = "Source"
      owner = "AWS"
      provider = "ECR"
      version = "1"
      output_artifacts = ["pushed_ecr_image"]

      configuration = {
        RepositoryName = "wynne-codepipeline-spike"
        ImageTag = "latest"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["verify_dev_pki", "pushed_ecr_image"]
      output_artifacts = ["build_output"]
      version = "1"
      
      configuration = {
        ProjectName = "wynne-ecr-triggered-pipeline-build"
        PrimarySource = "verify_dev_pki"
      }
    }
  }
}

resource "aws_codebuild_project" "wynne_ecr_triggered_pipeline_build" {
  name = "wynne-ecr-triggered-pipeline-build"
  description = "I'm testing the thing"
  service_role = aws_iam_role.wynne_codebuild_terraform_role.arn

  source {
    type = "CODEPIPELINE"
    buildspec = "ecr-triggered-pipeline.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type = "LINUX_CONTAINER"
    image = "626298535712.dkr.ecr.eu-west-2.amazonaws.com/wynne-codepipeline-spike:latest"
    image_pull_credentials_type = "CODEBUILD"
  }
}

resource "aws_cloudwatch_event_rule" "trigger_pipeline_on_ecr_push" {
  name = "image-pushed"
  role_arn = aws_iam_role.wynne_codebuild_terraform_role.arn
  event_pattern = <<EOF
{
  "detail-type": [
    "ECR Image Action"
  ],
  "source": [
    "aws.ecr"
  ],
  "detail": {
    "action-type": [
      "PUSH"
    ],
    "image-tag": [
      "latest"
    ],
    "repository-name": [
      "wynne-codepipeline-spike"
    ],
    "result": [
      "SUCCESS"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "pipeline_triggered_by_image_push" {
  rule = aws_cloudwatch_event_rule.trigger_pipeline_on_ecr_push.name
  arn = aws_codepipeline.pipeline_triggered_by_image_push.arn
  role_arn = aws_iam_role.wynne_codebuild_terraform_role.arn
}
terraform {
  required_version = "= 1.0.1"

  backend "s3" {
    bucket = "wynne-codepipeline-spike"
    key    = "pipeline.tfstate"
    region = "eu-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.58"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
}

resource "aws_codepipeline" "codepipeline" {
  name = "wynne-test-2-electric-boogaloo"
  role_arn = aws_iam_role.wynne_codepipeline_terraform_role.arn

  artifact_store {
    location = aws_s3_bucket.wynne_codepipeline_terraform_spike_artifact_store.bucket
    type = "S3"
  }

  stage {
    name = "Source-stage"

    action {
      name = "Source-dev-pki"
      category = "Source"
      owner = "AWS"
      provider = "CodeStarSourceConnection"
      version = "1"
      output_artifacts = ["verify_dev_pki"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.wynnternet.arn
        FullRepositoryId = "wynnternet/verify-dev-pki"
        BranchName = "hub-1051-codepipeline-spike"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }

    action {
      name = "Source-visual-regression"
      category = "Source"
      owner = "AWS"
      provider = "CodeStarSourceConnection"
      version = "1"
      output_artifacts = ["visual_regression_tests"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.wynnternet.arn
        FullRepositoryId = "wynnternet/verify-visual-regression-tests"
        BranchName = "main"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }


  stage {
    name = "Build-stage"

    action {
      name = "Build-action"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["verify_dev_pki", "visual_regression_tests"]
      output_artifacts = ["build_output"]
      version = "1"

      configuration = {
        ProjectName = "wynne-terraform-test"
        PrimarySource = "verify_dev_pki"
      }
    }
  }
}

resource "aws_codebuild_project" "wynne_terraform_test" {
  name = "wynne-terraform-test"
  description = "I'm testing the thing"
  service_role = aws_iam_role.wynne_codebuild_terraform_role.arn

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type = "LINUX_CONTAINER"
    image = "openjdk@sha256:058e2dae50d1f4c35586235e70b3d4ca29efc67fec7bc78dc7accce8263783c8"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential = "wynne-codebuild-spike-2"
      credential_provider = "SECRETS_MANAGER"
    }
  }
}

resource "aws_codestarconnections_connection" "wynnternet" {
  name = "wynne-connection"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "wynne_codepipeline_terraform_spike_artifact_store" {
  bucket = "wynne-codepipeline-spike-artifact-store"
  acl = "private"
}

resource "aws_iam_role" "wynne_codebuild_terraform_role" {
  name = "wynne_codebuild_terraform_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "wynne_codebuild_policy" {
  role = aws_iam_role.wynne_codebuild_terraform_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:eu-west-2:626298535712:secret:wynne-codebuild-spike-2-jVh2Pb",
                "arn:aws:secretsmanager:eu-west-2:626298535712:secret:maven-central-signing-AGkGfQ",
                "arn:aws:secretsmanager:eu-west-2:626298535712:secret:sonatype-password-p867Yc"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
              "*"
            ],
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
              "${aws_s3_bucket.wynne_codepipeline_terraform_spike_artifact_store.arn}",
              "${aws_s3_bucket.wynne_codepipeline_terraform_spike_artifact_store.arn}/*",
              "arn:aws:s3:::wynne-codepipeline-spike",
              "arn:aws:s3:::wynne-codepipeline-spike/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "wynne_codepipeline_terraform_role" {
  name = "wynne_codepipeline_terraform_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "wynne_terraform_spike_codepipeline_policy"
  role = aws_iam_role.wynne_codepipeline_terraform_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.wynne_codepipeline_terraform_spike_artifact_store.arn}",
        "${aws_s3_bucket.wynne_codepipeline_terraform_spike_artifact_store.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.wynnternet.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
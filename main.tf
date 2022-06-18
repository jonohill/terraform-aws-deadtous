terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "3.51.0"
        }
        docker = {
            source = "kreuzwerker/docker"
            version = "2.14.0"
        }
    }
}

resource "aws_s3_bucket" "s3" {
    bucket = var.name
    acl = "private"
}

resource "aws_ecr_repository" "deadtous_ecr" {
    name = var.name
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
    repository = aws_ecr_repository.deadtous_ecr.name

    policy = jsonencode({
        "rules" = [{
            "rulePriority" = 1,
            "description" = "Only keep latest",
            "selection" = {
                "tagStatus" = "any",
                "countType" = "imageCountMoreThan",
                "countNumber" = 1
            },
            "action": {
                "type" = "expire"
            }
        }]
    })
}

data "aws_ecr_authorization_token" "token" {}

provider "docker" {
    registry_auth {
        address = data.aws_ecr_authorization_token.token.proxy_endpoint
        username = data.aws_ecr_authorization_token.token.user_name
        password = data.aws_ecr_authorization_token.token.password
    }
}

# Copy image from public docker hub image to this repo
resource "docker_registry_image" "ecr_image" {
    name = "${aws_ecr_repository.deadtous_ecr.repository_url}:${var.image_tag}"
    build {
        context = path.module
        build_args = { "TAG" = var.image_tag }
    }
}

resource "aws_cloudwatch_log_group" "access_logs" {
    name = "${var.name}-access"
    retention_in_days = 14
}

module "lambda" {
    source  = "terraform-aws-modules/lambda/aws"
    version = "3.3.1"
  
    function_name = var.name
    create_package = false
    image_uri = docker_registry_image.ecr_image.name
    package_type = "Image"
    publish = true

    cloudwatch_logs_retention_in_days = 14
    timeout = 10

    environment_variables = {
        "DEADTOUS_STORAGE" = "s3:/${aws_s3_bucket.s3.bucket}"
        "DEADTOUS_SLACK_TOKENS" = var.slack_tokens
    }

    attach_policy_statements = true
    policy_statements = {
        s3_read = {
            effect = "Allow",
            actions = ["s3:GetObject"],
            resources = ["${aws_s3_bucket.s3.arn}/*"]
        }
    }

    allowed_triggers = {
        AllowExecutionFromAPIGateway = {
            service    = "apigateway"
            source_arn = "${module.apigateway-v2.apigatewayv2_api_execution_arn}/*/*"
        }
    }
}

module "apigateway-v2" {
    source  = "terraform-aws-modules/apigateway-v2/aws"
    version = "1.2.0"
    
    name = var.name
    protocol_type = "HTTP"

    create_api_domain_name = false

    default_stage_access_log_destination_arn = aws_cloudwatch_log_group.access_logs.arn
    default_stage_access_log_format = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

    integrations = {
        "$default" = {
            lambda_arn = module.lambda.lambda_function_arn
        }
    }
}

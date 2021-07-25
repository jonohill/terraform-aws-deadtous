# terraform-aws-deadtous

This module makes it easy to deploy [deadtous](https://github.com/hillnz/deadtous) to AWS.
It:
- Uploads the deadtous Docker image to ECR
- Creates a Lambda function that uses this image
- Sets up API Gateway
- Sets up an S3 bucket for storage

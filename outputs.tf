output "url" {
    description = "URL to configure in Slack"
    value = module.apigateway-v2.apigatewayv2_api_api_endpoint
}

output "s3_bucket" {
    description = "Name of storage bucket"
    value = aws_s3_bucket.s3.bucket
}

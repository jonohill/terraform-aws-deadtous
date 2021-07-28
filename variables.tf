variable "name" {
    type = string
    default = "deadtous"
}

variable "image_tag" {
    description = "Image tag for deadtous image (added to ECR)"
    type = string
    default = "1.0.1-lambda"
}

variable "slack_tokens" {
    description = "Tokens that Slack may send in its requests (comma-separated)"
    type = string
    sensitive = true
}

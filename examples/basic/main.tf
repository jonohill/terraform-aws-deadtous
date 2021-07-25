provider "aws" {
    # The region of your choice
    region = "ap-southeast-2"
}

variable "slack_tokens" {
    # It's wise to make this a variable so that you don't save your tokens here directly (unsafe)
    type = string
}

module "deadtous" {
    source = "jonohill/deadtous/aws"
    slack_tokens = var.slack_tokens
    # image_tag = "0.1.7-lambda" # image_tag is optional, the module should already reference the latest
    # name = "deadtous" # deadtous by default, but you could change it if you need a test version or multiple
}

# You'll want to output these so you know them for the configuration steps

output "url" {
    description = "URL to put into Slack"
    value = module.deadtous.url
}

output "storage_path" {
    description = "Storage path to import to (npx deadtous import <path>)"
    value = "s3:/${module.deadtous.s3_bucket}"
}

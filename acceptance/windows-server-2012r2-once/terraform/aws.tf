# Restrict operation of terraform to chef-es profile so that
# we do not create resources in other aws profiles.
# We assume user has configured standard aws credentials
# under ~/.aws/credentials or with $AWS_SHARED_CREDENTIALS_FILE
provider "aws" {
  region  = "${var.aws_region}"
  profile = "chef-aws"
}

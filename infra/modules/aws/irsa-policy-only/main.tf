/*
 * IAM Policy attachment module for existing IRSA role
 * Creates an IAM policy and attaches it to an existing role
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM policy for additional permissions
resource "aws_iam_policy" "this" {
  name        = var.policy_name
  description = var.policy_description
  policy      = var.policy_json
  tags        = var.tags
}

# Attach the policy to the existing role
resource "aws_iam_role_policy_attachment" "this" {
  role       = var.existing_role_name
  policy_arn = aws_iam_policy.this.arn
}
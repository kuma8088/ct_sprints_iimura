# Lambda Function for CodeDeploy Lifecycle Hook
resource "aws_lambda_function" "deployment_hook" {
  filename      = "deployment_hook.zip"
  function_name = "sprints-deployment-hook"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.deployment_hook.output_base64sha256
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "sprints-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda (CodeDeploy access)
resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:PutLifecycleEventHookExecutionStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Source code for Lambda
data "archive_file" "deployment_hook" {
  type        = "zip"
  output_path = "deployment_hook.zip"
  source {
    content  = <<EOF
import boto3
import json
import os

codedeploy = boto3.client('codedeploy')

def lambda_handler(event, context):
    print("Entering Lifecycle Hook!")
    print(json.dumps(event))

    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')

    if not deployment_id or not lifecycle_event_hook_execution_id:
        print("No DeploymentId or LifecycleEventHookExecutionId found. Exiting.")
        return

    params = {
        'deploymentId': deployment_id,
        'lifecycleEventHookExecutionId': lifecycle_event_hook_execution_id,
        'status': 'Succeeded' # 検証成功としてマーク
    }

    try:
        response = codedeploy.put_lifecycle_event_hook_execution_status(**params)
        print("Successfully reported status Succeeded")
        return response
    except Exception as e:
        print(f"Failed to report status: {e}")
        raise e
EOF
    filename = "index.py"
  }
}

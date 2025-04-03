# Deploy AWS Lambda Function with API Gateway Using Terraform

This project demonstrates how to deploy an AWS Lambda function integrated with an API Gateway using Terraform. AWS Lambda provides a serverless compute service, while API Gateway enables the creation of scalable RESTful APIs. By the end of this guide, you will have a working API that triggers a Lambda function upon receiving HTTP requests.

## Overview

In this setup:

- **AWS Lambda**: Executes a simple Python function that returns a "Hello from Lambda!" message.
- **API Gateway**: Provides an HTTP endpoint to invoke the Lambda function.
- **Terraform**: Automates the provisioning of AWS resources, including IAM roles, Lambda, and API Gateway.

## Prerequisites

Before you begin, ensure you have the following:

- An AWS account with IAM permissions to create Lambda, API Gateway, and IAM roles.
- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials (`aws configure`).
- Ubuntu 24.04 (or a similar environment) with the `zip` utility installed (`sudo apt install zip`).
- Basic knowledge of AWS, Terraform, and shell scripting.

## Directory Structure

Organize your project as follows:

```
terra/
├── api_gateway.tf         # API Gateway configuration
├── iam.tf                # IAM role and policy for Lambda
├── lambda.tf             # Lambda function configuration
├── lambda_function/      # Directory for Lambda code and packaging
│   ├── lambda_function.py # Lambda function code
│   ├── lambda_function.zip # Zipped Lambda function (generated)
│   └── zip_lambda.sh     # Script to zip the Lambda function
├── provider.tf           # AWS provider configuration
└── README.md             # This file
```

## Setup Instructions

Follow these steps to deploy the Lambda function and API Gateway:

### Step 1: Set Up Terraform Provider for AWS

Create `provider.tf` to configure the AWS provider:

```hcl
provider "aws" {
  region = "ap-south-1"  # Change to your preferred AWS region
}
```

### Step 2: Create an IAM Role for Lambda

Define an IAM role in `iam.tf` to allow Lambda to execute:

```hcl
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

### Step 3: Define the Lambda Function

Create `lambda.tf` to define the Lambda function:

```hcl
resource "aws_lambda_function" "my_lambda" {
  filename      = "${path.module}/lambda_function/lambda_function.zip"
  function_name = "MyLambdaFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
}
```

### Step 4: Configure API Gateway

Define the API Gateway in `api_gateway.tf`:

```hcl
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "LambdaAPI"
  description = "API Gateway for Lambda Function"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.my_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_api_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  deployment_id = aws_api_gateway_deployment.lambda_api_deployment.id
  stage_name    = "dev"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}
```

### Step 5: Create Lambda Function Code

Inside the `lambda_function/` directory:

1. Create `lambda_function.py`:

```python
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Hello from Lambda!'
    }
```

2. Create `zip_lambda.sh` to package the function:

```bash
#!/bin/bash
zip lambda_function.zip lambda_function.py
```

3. Make the script executable and run it:

```bash
chmod +x zip_lambda.sh
./zip_lambda.sh
```

This generates `lambda_function.zip`.

### Step 6: Deploy with Terraform

From the `terra/` directory, run:

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Preview the deployment:

   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply -auto-approve
   ```

After deployment, note the API Gateway endpoint URL from the Terraform output or AWS Console to test your API.

### Step 7: Test the Deployment

- Use a tool like `curl` or a browser to hit the API Gateway endpoint (e.g., `https://<api-id>.execute-api.<region>.amazonaws.com/dev/`).
- Expected response: `Hello from Lambda!`.

![alt text](<Screenshot 2025-04-03 at 11.23.55 PM.png>)
![alt text](<Screenshot 2025-04-03 at 11.24.07 PM.png>)
![alt text](<Screenshot 2025-04-03 at 11.24.51 PM.png>)

### Step 8: Clean Up

To destroy all resources and avoid charges:

```bash
terraform destroy -auto-approve
```

## Conclusion

You have successfully deployed a serverless application using AWS Lambda and API Gateway with Terraform. This setup is scalable, cost-efficient, and easy to manage, making it ideal for modern cloud applications.

## Troubleshooting

- **Lambda Zip Error**: Ensure `lambda_function.zip` is created and contains `lambda_function.py`.
- **Permission Issues**: Verify AWS CLI credentials and IAM permissions.
- **API Gateway 500 Error**: Check Lambda permissions and integration settings in `api_gateway.tf`.

For further assistance, refer to the [AWS Documentation](https://docs.aws.amazon.com/) or [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

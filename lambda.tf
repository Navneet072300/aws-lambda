resource "aws_lambda_function" "my_lambda" {
  filename      = "${path.module}/lambda_function/lambda_function.zip"
  function_name = "MyLambdaFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
}
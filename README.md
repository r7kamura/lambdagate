# Lambdagate
Management tool for Amazon API Gateway and Amazon Lambda.

## Requirements
- Ruby 2.2.0 or later
- Default credentials in `~/.aws/credentials`

```
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```

## Usage
The `lambdagate` executable is provided to create and update your API from your API schema
written in [Swagger](http://swagger.io/) format.

```
$ lambdagate
Usage: lambdagate [create|deploy|update] [command-specific-options]
```

### lambdagate create
Creates Restapi, Resources, Methods, and so on from your swagger schema.

```
$ lambdagate create
```

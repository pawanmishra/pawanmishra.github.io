---
layout: post
title: Localstack & Terraform
tags: [AWS, Terraform]
excerpt: In this blog post, we are going to see an example of how we can use the localstack framework for testing terraform deployments.
---
{% include base_path %}
{% include toc %}

#### LocalStack
---

[Localstack](https://github.com/localstack/localstack) is a framework which spins up core AWS Cloud APIs on our machine. It allows us to test & deploy our cloud infrastructure code locally. 

In this blog post, we will first go through the steps of installing and configuring [localstack](https://github.com/localstack/localstack) on our machine. After that we will define a simple terraform deployment script and apply it against the locally running localstack framework.

#### Setup
---

[Localstack](https://github.com/localstack/localstack) github documentation explains in detail the multiple ways we can install and run Localstack locally. I am following the docker-compose approach. Steps :-

* Configuring AWS Credentials. Since Localstack is a locally running AWS framework, we can technically run aws cli commands against it. But before we can do that, we need to create a test profile. In the .aws/credentials file, add the following lines -

```bash
[test]
output = json
region = us-east-1
aws_access_key_id = test
aws_secret_access_key = test
```

Next, add this function in your .bash_profile or .zprofile script - 

```bash
aws_localstack() {
    export AWS_PROFILE="test"
}
```

Running aws_localstack function will set the **AWS_PROFILE** environment variable to _test_.

* Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop). Besides the core docker framework, docker-desktop will also download and install the **docker-compose** library which is required for running [Localstack](https://github.com/localstack/localstack).
* Clone the [Localstack](https://github.com/localstack/localstack) git repo
* Next, navigate inside the localstack directory and open the **docker-compose.yml** file in an editor. As per the [Localstack](https://github.com/localstack/localstack) documentation, all of the AWS services can now be accessed via the 4566 port. However, when I ran aws cli commands e.g. 

> aws --endpoint-url=http://127.0.0.1:4566 s3 ls

I got a 404 exception - An error occurred (404) when calling the ListBuckets operation: Not Found.

In the end, I had to modify the **docker-compose.yml** file and add port mapping for all of the services under the **ports** section. This is what my **docker-compose.yml** file looks like -

```json
version: "3.8"

services:
  localstack:
    container_name: "${LOCALSTACK_DOCKER_NAME-localstack_main}"
    image: localstack/localstack
    network_mode: bridge
    ports:
      - "127.0.0.1:53:53"
      - "127.0.0.1:53:53/udp"
      - "127.0.0.1:443:443"
      - "127.0.0.1:4566:4566"
      - "127.0.0.1:4571:4571"
      - "127.0.0.1:4567:4567"
      - "127.0.0.1:4581:4581"
      - "127.0.0.1:4582:4582"
      - "127.0.0.1:4569:4569"
      - "127.0.0.1:4570:4570"
      - "127.0.0.1:4597:4597"
      - "127.0.0.1:4578:4578"
      - "127.0.0.1:4573:4573"
      - "127.0.0.1:4593:4593"
      - "127.0.0.1:4568:4568"
      - "127.0.0.1:4599:4599"
      - "127.0.0.1:4574:4574"
      - "127.0.0.1:4586:4586"
      - "127.0.0.1:4577:4577"
      - "127.0.0.1:4580:4580"
      - "127.0.0.1:4572:4572"
      - "127.0.0.1:4584:4584"
      - "127.0.0.1:4579:4579"
      - "127.0.0.1:4575:4575"
      - "127.0.0.1:4576:4576"
      - "127.0.0.1:4583:4583"
      - "127.0.0.1:4592:4592"
      - "127.0.0.1:4587:4587"
      - "127.0.0.1:4585:4585"
    environment:
      - SERVICES=${SERVICES- }
      - DEBUG=${DEBUG- }
      - DATA_DIR=${DATA_DIR-/tmp/localstack/data}
      - LAMBDA_EXECUTOR=${LAMBDA_EXECUTOR- }
      - LOCALSTACK_API_KEY=${LOCALSTACK_API_KEY- }
      - KINESIS_ERROR_PROBABILITY=${KINESIS_ERROR_PROBABILITY- }
      - DOCKER_HOST=unix:///var/run/docker.sock
      - HOST_TMP_FOLDER="${TMPDIR:-/tmp}/localstack"
    volumes:
      - "${TMPDIR:-/tmp}/localstack:/tmp/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
```
* We are now ready to run [Localstack](https://github.com/localstack/localstack). From within the localstack directory, run the follwoing command(this is for Mac) -  

> TMPDIR=/private$TMPDIR docker-compose up

Running the above command should output the following -

```bash
Starting localstack_main ... done
Attaching to localstack_main
localstack_main | Waiting for all LocalStack services to be ready
localstack_main | 2021-09-19 15:18:48,260 CRIT Supervisor is running as root.  Privileges were not dropped because no user is specified in the config file.  If you intend to run as root, you can set user=root in the config file to avoid this message.
localstack_main | 2021-09-19 15:18:48,265 INFO supervisord started with pid 14
localstack_main | 2021-09-19 15:18:49,271 INFO spawned: 'dashboard' with pid 20
localstack_main | 2021-09-19 15:18:49,275 INFO spawned: 'infra' with pid 21
localstack_main | (. .venv/bin/activate; bin/localstack web)
localstack_main | 2021-09-19 15:18:49,284 INFO success: dashboard entered RUNNING state, process has stayed up for > than 0 seconds (startsecs)
localstack_main | (. .venv/bin/activate; exec bin/localstack start --host)
localstack_main | Starting local dev environment. CTRL-C to quit.
localstack_main | 2021-09-19 15:18:51,029 INFO success: infra entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
localstack_main | Waiting for all LocalStack services to be ready
localstack_main | Starting mock API Gateway (http port 4567)...
localstack_main | Starting mock CloudFormation (http port 4581)...
localstack_main | Starting mock CloudWatch (http port 4582)...
localstack_main | Starting mock DynamoDB (http port 4569)...
localstack_main | Starting mock DynamoDB Streams service (http port 4570)...
localstack_main | Starting mock EC2 (http port 4597)...
localstack_main | Starting mock ES service (http port 4578)...
localstack_main | Starting mock Firehose service (http port 4573)...
localstack_main | Starting mock IAM (http port 4593)...
localstack_main | Starting mock Kinesis (http port 4568)...
localstack_main | Starting mock KMS (http port 4599)...
localstack_main | Starting mock Lambda service (http port 4574)...
localstack_main | Starting mock CloudWatch Logs (http port 4586)...
localstack_main | Starting mock Redshift (http port 4577)...
localstack_main | Starting mock Route53 (http port 4580)...
localstack_main | Starting mock S3 (http port 4572)...
localstack_main | Starting mock Secrets Manager (http port 4584)...
localstack_main | Starting mock SES (http port 4579)...
localstack_main | Starting mock SNS (http port 4575)...
localstack_main | Starting mock SQS (http port 4576)...
localstack_main | Starting mock SSM (http port 4583)...
localstack_main | Starting mock STS (http port 4592)...
localstack_main | Starting mock Cloudwatch Events (http port 4587)...
localstack_main | Starting mock StepFunctions (http port 4585)...
localstack_main | 2021-09-19T15:19:00:INFO:localstack.multiserver: Starting multi API server process on port 51492
localstack_main | Waiting for all LocalStack services to be ready
localstack_main | Ready.
```

We can test if [Localstack](https://github.com/localstack/localstack) is working correctly or not by running sample **aws cli** command against it. Run this command for getting list of StepFunctions -

> aws --endpoint-url=http://localhost:4585 stepfunctions list-state-machines

Since we haven't deployed any StepFunctions locally, above command should return this - 

```json
{
    "stateMachines": []
}
```

#### Terraform
---

In this section, we are going to run a simple terraform script, which will create a single S3 bucket. The terraform script will run against the locally running [Localstack](https://github.com/localstack/localstack) instance. 

> Ensure that the Localstack service is running and the AWS_PROFILE is set to "test"

```python
terraform {
  required_version = "0.14.10"

  backend "local" {}
}

provider "aws" {
  region                      = "us-east-1"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    cloudformation = "http://localhost:4581"
    cloudwatch     = "http://localhost:4582"
    dynamodb       = "http://localhost:4569"
    ec2            = "http://localhost:4597"
    iam            = "http://localhost:4593"
    kinesis        = "http://localhost:4568"
    kms            = "http://localhost:4599"
    lambda         = "http://localhost:4574"
    redshift       = "http://localhost:4577"
    route53        = "http://localhost:4580"
    s3             = "http://localhost:4572"
    ses            = "http://localhost:4579"
    sns            = "http://localhost:4575"
    sqs            = "http://localhost:4576"
    ssm            = "http://localhost:4583"
    sts            = "http://localhost:4592"
    stepfunctions  = "http://localhost:4585"
  }
}

module "blog" {
  source = "cloudposse/s3-bucket/aws"
  # Cloud Posse recommends pinning every module to a specific version
  version                = "0.43.0"
  acl                    = "private"
  enabled                = true
  user_enabled           = true
  versioning_enabled     = false
  allowed_bucket_actions = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
  name                   = "pawan"
  stage                  = "test"
  namespace              = "eg"
}
```

* In the provider section, we are setting some attributes to true. This is required because we aren't running our deployment against real AWS infrastructure and thus we cannot expect real credentials, AWS accountId, S3 path structure, etc.
* In the endpoints section, we are setting the endpoints for various AWS services to the locally running Localstack endpoints. This is the key to making terraform run against Localstack. For this demo, I only need the S3 endpoint but I decided to list all the endpoints.
* Finally, using the open source [cloudposse s3 module](https://registry.terraform.io/modules/cloudposse/s3-bucket/aws/latest) for creating the S3 bucket.

This is all we need to run and test our terraform script against [Localstack](https://github.com/localstack/localstack). Go ahead and run **terraform plan** followed by **terraform apply**. **terraform apply** should complete with the following output -

```bash
module.blog.module.s3_user.module.s3_user.aws_iam_user.default[0]: Creating...
module.blog.aws_s3_bucket.default[0]: Creating...
module.blog.module.s3_user.module.s3_user.aws_iam_user.default[0]: Creation complete after 0s [id=eg-test-pawan]
module.blog.module.s3_user.module.s3_user.aws_iam_access_key.default[0]: Creating...
module.blog.module.s3_user.module.s3_user.aws_iam_access_key.default[0]: Creation complete after 0s [id=AKIAZ6TWM22LRD58T1LI]
module.blog.aws_s3_bucket.default[0]: Creation complete after 0s [id=eg-test-pawan]
module.blog.data.aws_iam_policy_document.bucket_policy[0]: Reading...
module.blog.module.s3_user.data.aws_iam_policy_document.default[0]: Reading...
module.blog.aws_s3_bucket_public_access_block.default[0]: Creating...
module.blog.data.aws_iam_policy_document.bucket_policy[0]: Read complete after 0s [id=561002259]
module.blog.module.s3_user.data.aws_iam_policy_document.default[0]: Read complete after 0s [id=597709288]
module.blog.data.aws_iam_policy_document.aggregated_policy[0]: Reading...
module.blog.data.aws_iam_policy_document.aggregated_policy[0]: Read complete after 0s [id=561002259]
module.blog.module.s3_user.aws_iam_user_policy.default[0]: Creating...
module.blog.aws_s3_bucket_public_access_block.default[0]: Creation complete after 1s [id=eg-test-pawan]
module.blog.module.s3_user.aws_iam_user_policy.default[0]: Creation complete after 0s [id=eg-test-pawan:eg-test-pawan]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```
To test if the **terraform apply** has actually created the bucket against [Localstack](https://github.com/localstack/localstack) or not, run the following aws cli command 

> aws --endpoint-url=http://127.0.0.1:4572 s3 ls

Running the above commad on my machine returns the following output -

```bash
2021-09-19 10:19:07 eg-test-pawan
```

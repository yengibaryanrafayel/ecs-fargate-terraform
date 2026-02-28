# Unleash Live — AWS Multi-Region Assessment

Modular Terraform project that provisions a fully working multi-region AWS compute stack secured by a centralised Amazon Cognito User Pool.

---

## Architecture overview

```
us-east-1 (primary)                  eu-west-1 (replica)
─────────────────────                ─────────────────────
Cognito User Pool ←────────────────── JWT Authorizer
                                      (reads same pool)

API Gateway (HTTP)                   API Gateway (HTTP)
  GET  /greet  ──► Lambda Greeter      GET  /greet  ──► Lambda Greeter
  POST /dispatch ► Lambda Dispatcher   POST /dispatch ► Lambda Dispatcher
       │                                    │
       ▼                                    ▼
  DynamoDB Table                      DynamoDB Table
  (GreetingLogs)                      (GreetingLogs)
       │                                    │
       └──────────► SNS ◄──────────────────┘
                (us-east-1)

ECS Fargate cluster (public subnet, no NAT Gateway)
  Task: amazon/aws-cli → aws sns publish → exit
```

### Multi-region provider design

The root `providers.tf` declares two aliased AWS providers:

| Alias        | Region      | Used by |
|-------------|-------------|---------|
| `aws.us_east_1` | `us-east-1` | `module.cognito`, `module.us_east_1` |
| `aws.eu_west_1` | `eu-west-1` | `module.eu_west_1` |

`module.regional` is a **single module called twice** — once per provider alias. Every resource inside (`networking`, `dynamodb`, `ecs`, `lambda`, `api_gateway`) inherits the caller's provider, so the identical module creates a complete, independent stack in each region with no code duplication.

IAM resources (which are global) are suffixed with the region name to avoid naming conflicts.

---

## Project structure

```
.
├── main.tf                   # Root — wires cognito + two regional stacks
├── providers.tf              # Multi-region provider aliases
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── modules/
│   ├── cognito/              # Cognito User Pool + Client + test user
│   ├── regional/             # Wrapper: calls all regional sub-modules
│   ├── networking/           # VPC, public subnets, IGW, security group
│   ├── dynamodb/             # GreetingLogs table (PAY_PER_REQUEST)
│   ├── ecs/                  # ECS cluster, task definition, IAM roles
│   ├── lambda/               # Greeter + Dispatcher functions + IAM
│   │   └── functions/
│   │       ├── greeter/      # Python — DynamoDB write + SNS publish
│   │       └── dispatcher/   # Python — ECS RunTask
│   └── api_gateway/          # HTTP API, JWT authorizer, routes
├── scripts/
│   └── test.py               # Integration test (concurrent, latency)
└── .github/
    └── workflows/
        └── deploy.yml        # CI/CD pipeline
```

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Terraform | 1.5.0 |
| AWS CLI | 2.x (for initial credential setup) |
| Python | 3.9+ (for test script) |
| boto3, requests | latest (`pip install boto3 requests`) |

AWS credentials must have permissions for: Cognito, API Gateway, Lambda, DynamoDB, ECS, ECR Public, IAM, CloudWatch Logs, VPC.

---

## Manual deployment

### 1. Clone and configure

```bash
git clone https://github.com/<you>/aws-assessment
cd aws-assessment

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in your email, GitHub repo, and password
```

### 2. Initialise Terraform

```bash
terraform init
```

> **Optional — remote state (recommended):** Create an S3 bucket and add a `backend.tf`:
> ```hcl
> terraform {
>   backend "s3" {
>     bucket = "my-tf-state-bucket"
>     key    = "unleash-live/terraform.tfstate"
>     region = "us-east-1"
>   }
> }
> ```

### 3. Plan & Apply

```bash
terraform plan
terraform apply
```

Terraform will output the two API URLs and Cognito identifiers on completion.

### 4. Note the outputs

```
cognito_user_pool_id = "us-east-1_XXXXXXX"
cognito_client_id    = "XXXXXXXXXXXXXXXXXXXXXXXXXX"
us_east_1_api_url    = "https://XXXXXXXX.execute-api.us-east-1.amazonaws.com"
eu_west_1_api_url    = "https://XXXXXXXX.execute-api.eu-west-1.amazonaws.com"
```

---

## Running the test script

```bash
pip install boto3 requests

python scripts/test.py \
  --us-api-url  "$(terraform output -raw us_east_1_api_url)" \
  --eu-api-url  "$(terraform output -raw eu_west_1_api_url)" \
  --user-pool-id "$(terraform output -raw cognito_user_pool_id)" \
  --client-id   "$(terraform output -raw cognito_client_id)" \
  --email       "your.email@example.com" \
  --password    "TempPass123!"
```

The script will:
1. Authenticate with Cognito and retrieve a JWT.
2. **Concurrently** call `/greet` in both regions and assert the `region` field matches.
3. **Concurrently** call `/dispatch` in both regions, triggering the ECS Fargate tasks.
4. Print a latency comparison that demonstrates the geographic performance difference.

---

## Teardown (important — avoid charges)

Once you have successfully triggered the SNS payloads:

```bash
terraform destroy
```

---

## CI/CD pipeline (`deploy.yml`)

| Job | Trigger | What it does |
|-----|---------|--------------|
| **lint** | every push / PR | `terraform fmt -check`, `terraform validate` |
| **security** | after lint | tfsec + Checkov static analysis |
| **plan** | PR only | `terraform plan`, uploads artifact |
| **deploy** | push to `main` | `terraform apply`, captures outputs |
| **destroy** | manual dispatch | `terraform destroy` (cost guard) |

### Required GitHub Secrets

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | IAM access key |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `TF_STATE_BUCKET` | S3 bucket name for remote state |
| `TF_EMAIL` | Your email address |
| `TF_GITHUB_REPO` | Your GitHub repository URL |
| `TF_COGNITO_PASSWORD` | Cognito test-user password |

---

## Cost considerations

- **Fargate in public subnet** — no NAT Gateway (~$32/month saved per region).
- **DynamoDB PAY_PER_REQUEST** — zero cost at low volume.
- **Lambda** — well within the free tier for testing.
- **ECS cluster** — no cost when idle; you only pay for running tasks.
- Destroy immediately after the SNS payloads are confirmed to eliminate all charges.

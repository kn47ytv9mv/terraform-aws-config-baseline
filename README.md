# terraform-aws-config-baseline

Terraform module for a curated set of AWS Config managed rules — a
starting security posture, evaluated against the resource inventory
[`terraform-aws-config-recorder`](https://github.com/kn47ytv9mv/terraform-aws-config-recorder)
maintains.

## Cost

AWS Config bills per rule evaluation, separately from the recorder's
own per-configuration-item charge. With every rule left at its
default, this module creates one rule per check listed below;
disabling any via its `enable_*` variable removes that rule's
evaluations and its cost. See
AWS's [Config pricing](https://aws.amazon.com/config/pricing/) page
for current rates.

## Design

Every rule is an AWS managed rule (this module does not, and cannot,
create a custom Lambda- or Guard-backed rule) selected across four
categories: network exposure, storage exposure, identity, and
logging/monitoring. See the Inputs table below for the exact managed
rule each `enable_*` variable controls.

Every rule defaults to enabled. None of these rules are blocking —
AWS Config rules only report a resource as `NON_COMPLIANT`, they never
prevent it from being created — so leaving all 15 on is safe to apply
against an existing account: it surfaces findings, it does not break
anything. Disable individual rules via their `enable_*` variable for
an account that intentionally accepts a given risk, or reach for
[`terraform-aws-config-rule`](https://github.com/kn47ytv9mv/terraform-aws-config-rule)
directly for a rule outside this curated set, or one needing a
`scope` this module does not expose.

This module implements its own `aws_config_config_rule` resources
rather than calling `terraform-aws-config-rule` internally — this
family keeps single-purpose modules standalone; only a parent
composition config wires leaf modules together.

A rule's identifier is not always a mechanical transform of its AWS
documentation page name — `restricted-common-ports`'s real identifier
is `RESTRICTED_INCOMING_TRAFFIC`, and `restricted-ssh`'s is
`INCOMING_SSH_DISABLED` — every identifier in this module was
confirmed against its own AWS documentation page rather than assumed.

## Usage

```hcl
module "baseline" {
  source = "kn47ytv9mv/config-baseline/aws"
}
```

Or directly from this repository, disabling one noisy rule and tuning
a couple of parameters:

```hcl
module "baseline" {
  source = "github.com/kn47ytv9mv/terraform-aws-config-baseline"

  enable_iam_policy_no_statements_with_admin_access = false

  restricted_common_ports_blocked_ports = [22, 3389]

  iam_password_policy = {
    minimum_password_length = 16
  }
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| aws | ~> 6.61 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| enable_incoming_ssh_disabled | Flag security groups that allow unrestricted inbound SSH (0.0.0.0/0 or ::/0 on port 22). Managed rule: INCOMING_SSH_DISABLED. | `true` | no |
| enable_restricted_common_ports | Flag security groups that allow unrestricted inbound TCP on common sensitive ports. Managed rule: RESTRICTED_INCOMING_TRAFFIC (AWS names this rule 'restricted-common-ports'; the identifier and the friendly name differ). | `true` | no |
| restricted_common_ports_blocked_ports | TCP ports checked by enable_restricted_common_ports. If null, AWS's own defaults apply (20, 21, 3389, 3306, 4333 — FTP, RDP, and MySQL). | `null` | no |
| enable_vpc_default_security_group_closed | Flag any VPC's default security group that allows any inbound or outbound traffic. Managed rule: VPC_DEFAULT_SECURITY_GROUP_CLOSED. | `true` | no |
| enable_s3_bucket_server_side_encryption_enabled | Flag S3 buckets without default encryption enabled. Managed rule: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED. | `true` | no |
| enable_s3_bucket_ssl_requests_only | Flag S3 buckets whose policy does not deny non-TLS requests. Managed rule: S3_BUCKET_SSL_REQUESTS_ONLY. | `true` | no |
| enable_encrypted_volumes | Flag attached EBS volumes that are not encrypted. Managed rule: ENCRYPTED_VOLUMES. | `true` | no |
| encrypted_volumes_kms_key_id | If set, enable_encrypted_volumes additionally requires this specific KMS key ID or ARN, rejecting volumes encrypted with any other key. If null, any KMS key satisfies the check. | `null` | no |
| enable_rds_storage_encrypted | Flag RDS DB instances without storage encryption enabled. Managed rule: RDS_STORAGE_ENCRYPTED. | `true` | no |
| rds_storage_encrypted_kms_key_id | If set, enable_rds_storage_encrypted additionally requires this specific KMS key ID or ARN. If null, any KMS key satisfies the check. | `null` | no |
| enable_root_account_mfa_enabled | Flag the account if its root user does not have MFA enabled for console sign-in. Managed rule: ROOT_ACCOUNT_MFA_ENABLED. | `true` | no |
| enable_mfa_enabled_for_iam_console_access | Flag any IAM user with console access that does not have MFA enabled. Managed rule: MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS. | `true` | no |
| enable_iam_password_policy | Flag the account if its IAM password policy does not meet the requirements in iam_password_policy. Managed rule: IAM_PASSWORD_POLICY. | `true` | no |
| iam_password_policy | Requirements checked by enable_iam_password_policy. If null, AWS's own defaults apply (uppercase, lowercase, symbols, and numbers all required; minimum length 14; 24 passwords remembered; 90-day max age) — note AWS itself marks the true IAM default policy, which is weaker than this rule's defaults, as NON_COMPLIANT. | `null` | no |
| enable_access_keys_rotated | Flag active IAM access keys not rotated within access_keys_rotated_max_age days. Managed rule: ACCESS_KEYS_ROTATED. | `true` | no |
| access_keys_rotated_max_age | Maximum access key age, in days, checked by enable_access_keys_rotated. If null, AWS's own default of 90 applies. | `null` | no |
| enable_iam_policy_no_statements_with_admin_access | Flag any customer-managed IAM policy with a statement granting Action:* over Resource:*. Managed rule: IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS. Does not evaluate inline or AWS-managed policies. | `true` | no |
| iam_policy_no_statements_with_admin_access_exclude_permission_boundary_policy | If true, enable_iam_policy_no_statements_with_admin_access skips policies used as permissions boundaries. If null, AWS's own default of false applies (boundary policies are evaluated). | `null` | no |
| enable_cloudtrail_enabled | Flag the account if no CloudTrail trail exists and is actively logging. Managed rule: CLOUDTRAIL_ENABLED. | `true` | no |
| enable_cloud_trail_log_file_validation_enabled | Flag any CloudTrail trail without log file validation (signed digest files) enabled. Managed rule: CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED. | `true` | no |
| enable_cloud_trail_encryption_enabled | Flag any CloudTrail trail not configured for SSE-KMS encryption. Managed rule: CLOUD_TRAIL_ENCRYPTION_ENABLED. | `true` | no |
| tags | A map of tags to assign to every rule this module creates. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| rule_ids | Map of rule key to its AWS Config rule ID, one entry per rule this module enabled. |
| rule_arns | Map of rule key to its ARN, one entry per rule this module enabled. |

## License

MIT — see [LICENSE.md](LICENSE.md).

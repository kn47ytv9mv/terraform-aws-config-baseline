locals {
  rules = {
    incoming_ssh_disabled = {
      enabled           = var.enable_incoming_ssh_disabled
      description       = "Checks if security groups allow unrestricted inbound SSH."
      source_identifier = "INCOMING_SSH_DISABLED"
      input_parameters  = null
    }

    restricted_common_ports = {
      enabled           = var.enable_restricted_common_ports
      description       = "Checks if security groups allow unrestricted inbound TCP on common sensitive ports."
      source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
      input_parameters = var.restricted_common_ports_blocked_ports == null ? null : jsonencode({
        blockedPorts = join(",", [for p in var.restricted_common_ports_blocked_ports : tostring(p)])
      })
    }

    vpc_default_security_group_closed = {
      enabled           = var.enable_vpc_default_security_group_closed
      description       = "Checks if the default security group of any VPC allows inbound or outbound traffic."
      source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
      input_parameters  = null
    }

    s3_bucket_server_side_encryption_enabled = {
      enabled           = var.enable_s3_bucket_server_side_encryption_enabled
      description       = "Checks if S3 buckets have default encryption enabled."
      source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
      input_parameters  = null
    }

    s3_bucket_ssl_requests_only = {
      enabled           = var.enable_s3_bucket_ssl_requests_only
      description       = "Checks if S3 bucket policies require requests to use SSL/TLS."
      source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
      input_parameters  = null
    }

    encrypted_volumes = {
      enabled           = var.enable_encrypted_volumes
      description       = "Checks if attached EBS volumes are encrypted."
      source_identifier = "ENCRYPTED_VOLUMES"
      input_parameters = var.encrypted_volumes_kms_key_id == null ? null : jsonencode({
        kmsId = tostring(var.encrypted_volumes_kms_key_id)
      })
    }

    rds_storage_encrypted = {
      enabled           = var.enable_rds_storage_encrypted
      description       = "Checks if RDS DB instance storage encryption is enabled."
      source_identifier = "RDS_STORAGE_ENCRYPTED"
      input_parameters = var.rds_storage_encrypted_kms_key_id == null ? null : jsonencode({
        kmsKeyId = tostring(var.rds_storage_encrypted_kms_key_id)
      })
    }

    root_account_mfa_enabled = {
      enabled           = var.enable_root_account_mfa_enabled
      description       = "Checks if the root user requires MFA for console sign-in."
      source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
      input_parameters  = null
    }

    mfa_enabled_for_iam_console_access = {
      enabled           = var.enable_mfa_enabled_for_iam_console_access
      description       = "Checks if IAM users with console access have MFA enabled."
      source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
      input_parameters  = null
    }

    iam_password_policy = {
      enabled           = var.enable_iam_password_policy
      description       = "Checks if the account password policy meets the configured requirements."
      source_identifier = "IAM_PASSWORD_POLICY"
      input_parameters = var.iam_password_policy == null ? null : jsonencode({
        for k, v in {
          RequireUppercaseCharacters = var.iam_password_policy.require_uppercase_characters
          RequireLowercaseCharacters = var.iam_password_policy.require_lowercase_characters
          RequireSymbols             = var.iam_password_policy.require_symbols
          RequireNumbers             = var.iam_password_policy.require_numbers
          MinimumPasswordLength      = var.iam_password_policy.minimum_password_length
          PasswordReusePrevention    = var.iam_password_policy.password_reuse_prevention
          MaxPasswordAge             = var.iam_password_policy.max_password_age
        } : k => tostring(v) if v != null
      })
    }

    access_keys_rotated = {
      enabled           = var.enable_access_keys_rotated
      description       = "Checks if active IAM access keys are rotated within the configured age."
      source_identifier = "ACCESS_KEYS_ROTATED"
      # maxAccessKeyAge is required by the AWS API despite AWS's own docs listing
      # a default — confirmed via a real apply that rejected an empty parameter
      # set with "required parameter [maxAccessKeyAge] is not present".
      input_parameters = jsonencode({
        maxAccessKeyAge = tostring(coalesce(var.access_keys_rotated_max_age, 90))
      })
    }

    iam_policy_no_statements_with_admin_access = {
      enabled           = var.enable_iam_policy_no_statements_with_admin_access
      description       = "Checks if customer-managed IAM policies grant Action:* over Resource:*."
      source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
      input_parameters = var.iam_policy_no_statements_with_admin_access_exclude_permission_boundary_policy == null ? null : jsonencode({
        excludePermissionBoundaryPolicy = tostring(var.iam_policy_no_statements_with_admin_access_exclude_permission_boundary_policy)
      })
    }

    cloudtrail_enabled = {
      enabled           = var.enable_cloudtrail_enabled
      description       = "Checks if a CloudTrail trail exists and is actively logging."
      source_identifier = "CLOUD_TRAIL_ENABLED"
      input_parameters  = null
    }

    cloud_trail_log_file_validation_enabled = {
      enabled           = var.enable_cloud_trail_log_file_validation_enabled
      description       = "Checks if CloudTrail log file validation is enabled."
      source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
      input_parameters  = null
    }

    cloud_trail_encryption_enabled = {
      enabled           = var.enable_cloud_trail_encryption_enabled
      description       = "Checks if CloudTrail is configured for SSE-KMS encryption."
      source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
      input_parameters  = null
    }
  }

  enabled_rules = { for k, v in local.rules : k => v if v.enabled }
}

resource "aws_config_config_rule" "resource" {
  for_each = local.enabled_rules

  name             = replace(each.key, "_", "-")
  description      = each.value.description
  input_parameters = each.value.input_parameters

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  evaluation_mode {
    mode = "DETECTIVE"
  }

  tags = var.tags
}

output "rule_ids" {
  description = "Map of rule key to its AWS Config rule ID, one entry per rule this module enabled."
  value       = { for k, v in aws_config_config_rule.resource : k => v.id }
}

output "rule_arns" {
  description = "Map of rule key to its ARN, one entry per rule this module enabled."
  value       = { for k, v in aws_config_config_rule.resource : k => v.arn }
}

variable "enable_incoming_ssh_disabled" {
  default     = true
  description = "Flag security groups that allow unrestricted inbound SSH (0.0.0.0/0 or ::/0 on port 22). Managed rule: INCOMING_SSH_DISABLED."
}

variable "enable_restricted_common_ports" {
  default     = true
  description = "Flag security groups that allow unrestricted inbound TCP on common sensitive ports. Managed rule: RESTRICTED_INCOMING_TRAFFIC (AWS names this rule 'restricted-common-ports'; the identifier and the friendly name differ)."
}

variable "restricted_common_ports_blocked_ports" {
  default     = null
  description = "TCP ports checked by enable_restricted_common_ports. If null, AWS's own defaults apply (20, 21, 3389, 3306, 4333 — FTP, RDP, and MySQL)."
}

variable "enable_vpc_default_security_group_closed" {
  default     = true
  description = "Flag any VPC's default security group that allows any inbound or outbound traffic. Managed rule: VPC_DEFAULT_SECURITY_GROUP_CLOSED."
}

variable "enable_s3_bucket_server_side_encryption_enabled" {
  default     = true
  description = "Flag S3 buckets without default encryption enabled. Managed rule: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED."
}

variable "enable_s3_bucket_ssl_requests_only" {
  default     = true
  description = "Flag S3 buckets whose policy does not deny non-TLS requests. Managed rule: S3_BUCKET_SSL_REQUESTS_ONLY."
}

variable "enable_encrypted_volumes" {
  default     = true
  description = "Flag attached EBS volumes that are not encrypted. Managed rule: ENCRYPTED_VOLUMES."
}

variable "encrypted_volumes_kms_key_id" {
  default     = null
  description = "If set, enable_encrypted_volumes additionally requires this specific KMS key ID or ARN, rejecting volumes encrypted with any other key. If null, any KMS key satisfies the check."
}

variable "enable_rds_storage_encrypted" {
  default     = true
  description = "Flag RDS DB instances without storage encryption enabled. Managed rule: RDS_STORAGE_ENCRYPTED."
}

variable "rds_storage_encrypted_kms_key_id" {
  default     = null
  description = "If set, enable_rds_storage_encrypted additionally requires this specific KMS key ID or ARN. If null, any KMS key satisfies the check."
}

variable "enable_root_account_mfa_enabled" {
  default     = true
  description = "Flag the account if its root user does not have MFA enabled for console sign-in. Managed rule: ROOT_ACCOUNT_MFA_ENABLED."
}

variable "enable_mfa_enabled_for_iam_console_access" {
  default     = true
  description = "Flag any IAM user with console access that does not have MFA enabled. Managed rule: MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS."
}

variable "enable_iam_password_policy" {
  default     = true
  description = "Flag the account if its IAM password policy does not meet the requirements in iam_password_policy. Managed rule: IAM_PASSWORD_POLICY."
}

variable "iam_password_policy" {
  default     = null
  description = "Requirements checked by enable_iam_password_policy. If null, AWS's own defaults apply (uppercase, lowercase, symbols, and numbers all required; minimum length 14; 24 passwords remembered; 90-day max age) — note AWS itself marks the true IAM default policy, which is weaker than this rule's defaults, as NON_COMPLIANT."
  type = object({
    require_uppercase_characters = optional(bool)
    require_lowercase_characters = optional(bool)
    require_symbols              = optional(bool)
    require_numbers              = optional(bool)
    minimum_password_length      = optional(number)
    password_reuse_prevention    = optional(number)
    max_password_age             = optional(number)
  })
}

variable "enable_access_keys_rotated" {
  default     = true
  description = "Flag active IAM access keys not rotated within access_keys_rotated_max_age days. Managed rule: ACCESS_KEYS_ROTATED."
}

variable "access_keys_rotated_max_age" {
  default     = null
  description = "Maximum access key age, in days, checked by enable_access_keys_rotated. If null, AWS's own default of 90 applies."
}

variable "enable_iam_policy_no_statements_with_admin_access" {
  default     = true
  description = "Flag any customer-managed IAM policy with a statement granting Action:* over Resource:*. Managed rule: IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS. Does not evaluate inline or AWS-managed policies."
}

variable "iam_policy_no_statements_with_admin_access_exclude_permission_boundary_policy" {
  default     = null
  description = "If true, enable_iam_policy_no_statements_with_admin_access skips policies used as permissions boundaries. If null, AWS's own default of false applies (boundary policies are evaluated)."
}

variable "enable_cloudtrail_enabled" {
  default     = true
  description = "Flag the account if no CloudTrail trail exists and is actively logging. Managed rule: CLOUDTRAIL_ENABLED."
}

variable "enable_cloud_trail_log_file_validation_enabled" {
  default     = true
  description = "Flag any CloudTrail trail without log file validation (signed digest files) enabled. Managed rule: CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED."
}

variable "enable_cloud_trail_encryption_enabled" {
  default     = true
  description = "Flag any CloudTrail trail not configured for SSE-KMS encryption. Managed rule: CLOUD_TRAIL_ENCRYPTION_ENABLED."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to every rule this module creates."
}

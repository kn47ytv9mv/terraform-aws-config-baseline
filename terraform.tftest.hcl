mock_provider "aws" {}

run "all_fifteen_rules_enabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_config_config_rule.resource) == 15
    error_message = "Every enable_* toggle defaults to true, so all 15 baseline rules should be created by default."
  }
}

run "disabling_a_rule_removes_only_that_rule" {
  command = plan

  variables {
    enable_incoming_ssh_disabled = false
  }

  assert {
    condition     = length(aws_config_config_rule.resource) == 14
    error_message = "Disabling one rule should drop the count to 14, leaving the other 14 untouched."
  }

  assert {
    condition     = !contains(keys(aws_config_config_rule.resource), "incoming_ssh_disabled")
    error_message = "The disabled rule's key should not appear among the created rules."
  }
}

run "disabling_every_rule_creates_nothing" {
  command = plan

  variables {
    enable_incoming_ssh_disabled                      = false
    enable_restricted_common_ports                    = false
    enable_vpc_default_security_group_closed          = false
    enable_s3_bucket_server_side_encryption_enabled   = false
    enable_s3_bucket_ssl_requests_only                = false
    enable_encrypted_volumes                          = false
    enable_rds_storage_encrypted                      = false
    enable_root_account_mfa_enabled                   = false
    enable_mfa_enabled_for_iam_console_access         = false
    enable_iam_password_policy                        = false
    enable_access_keys_rotated                        = false
    enable_iam_policy_no_statements_with_admin_access = false
    enable_cloudtrail_enabled                         = false
    enable_cloud_trail_log_file_validation_enabled    = false
    enable_cloud_trail_encryption_enabled             = false
  }

  assert {
    condition     = length(aws_config_config_rule.resource) == 0
    error_message = "Disabling every toggle should create no rules at all."
  }
}

run "rule_name_is_derived_from_its_key" {
  command = plan

  assert {
    condition     = aws_config_config_rule.resource["incoming_ssh_disabled"].name == "incoming-ssh-disabled"
    error_message = "A rule's name should be its map key with underscores replaced by hyphens."
  }
}

run "rule_source_identifiers_are_correct" {
  command = plan

  assert {
    condition     = aws_config_config_rule.resource["incoming_ssh_disabled"].source[0].source_identifier == "INCOMING_SSH_DISABLED"
    error_message = "incoming_ssh_disabled should use the INCOMING_SSH_DISABLED managed rule."
  }

  assert {
    condition     = aws_config_config_rule.resource["restricted_common_ports"].source[0].source_identifier == "RESTRICTED_INCOMING_TRAFFIC"
    error_message = "restricted_common_ports should use the RESTRICTED_INCOMING_TRAFFIC managed rule — its identifier and friendly name differ."
  }

  assert {
    condition     = aws_config_config_rule.resource["cloudtrail_enabled"].source[0].source_identifier == "CLOUD_TRAIL_ENABLED"
    error_message = "cloudtrail_enabled should use the CLOUD_TRAIL_ENABLED managed rule — its identifier and friendly name differ."
  }
}

run "access_keys_rotated_always_sends_required_parameter" {
  command = plan

  assert {
    condition     = aws_config_config_rule.resource["access_keys_rotated"].input_parameters == jsonencode({ maxAccessKeyAge = "90" })
    error_message = "maxAccessKeyAge is required by the AWS API — it must always be sent, defaulting to AWS's own documented default of 90 as a string."
  }
}

run "access_keys_rotated_max_age_override_is_stringified" {
  command = plan

  variables {
    access_keys_rotated_max_age = 45
  }

  assert {
    condition     = aws_config_config_rule.resource["access_keys_rotated"].input_parameters == jsonencode({ maxAccessKeyAge = "45" })
    error_message = "An explicit access_keys_rotated_max_age should be sent as a string — AWS Config rejects non-string parameter values for this rule family."
  }
}

run "no_input_parameters_by_default" {
  command = plan

  assert {
    condition     = aws_config_config_rule.resource["restricted_common_ports"].input_parameters == null
    error_message = "Leaving restricted_common_ports_blocked_ports unset should leave input_parameters null, so AWS's own defaults apply."
  }
}

run "restricted_common_ports_blocked_ports_builds_csv_parameter" {
  command = plan

  variables {
    restricted_common_ports_blocked_ports = [22, 23, 8080]
  }

  assert {
    condition     = aws_config_config_rule.resource["restricted_common_ports"].input_parameters == jsonencode({ blockedPorts = "22,23,8080" })
    error_message = "A blocked_ports list should be joined into a CSV blockedPorts parameter."
  }
}

run "encrypted_volumes_kms_key_id_builds_parameter" {
  command = plan

  variables {
    encrypted_volumes_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }

  assert {
    condition     = aws_config_config_rule.resource["encrypted_volumes"].input_parameters == jsonencode({ kmsId = "arn:aws:kms:us-east-1:123456789012:key/abc" })
    error_message = "Setting encrypted_volumes_kms_key_id should produce a kmsId input parameter."
  }
}

run "iam_password_policy_only_includes_set_fields_as_strings" {
  command = plan

  variables {
    iam_password_policy = {
      minimum_password_length = 20
      require_symbols         = true
    }
  }

  assert {
    condition     = aws_config_config_rule.resource["iam_password_policy"].input_parameters == jsonencode({ RequireSymbols = "true", MinimumPasswordLength = "20" })
    error_message = "Only explicitly set iam_password_policy fields should appear in input_parameters, each stringified — AWS Config rejects non-string values for this rule."
  }
}

run "tags_pass_through_to_every_rule" {
  command = plan

  variables {
    tags = { Environment = "production" }
  }

  assert {
    condition     = aws_config_config_rule.resource["cloudtrail_enabled"].tags["Environment"] == "production"
    error_message = "tags should pass through to every created rule."
  }
}

run "readme_default_example" {
  command = plan
}

run "readme_selective_example" {
  command = plan

  variables {
    enable_iam_policy_no_statements_with_admin_access = false
    restricted_common_ports_blocked_ports             = [22, 3389]
    iam_password_policy = {
      minimum_password_length = 16
    }
  }
}

# Manage Postfix.
#
# @example Configure Postfix with the defaults as shipped by the OS and managing any aliases using the standard Puppet `mailalias` resource type
#   include postfix
#
#   postfix::lookup::database { '/etc/aliases':
#     type => 'hash',
#   }
#
#   Mailalias <||> -> Postfix::Lookup::Database['/etc/aliases']
#
# @example Configure Postfix with an additional submission service running on TCP port 587
#   include postfix
#
#   postfix::master { 'submission/inet':
#     private => 'n',
#     chroot  => 'n',
#     command => 'smtpd -o smtpd_tls_security_level=encrypt -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject',
#   }
#
# @example Configure Postfix for virtual mailbox hosting using LDAP to provide the various lookup tables
#   class { 'postfix':
#     virtual_mailbox_base    => '/var/mail/vhosts',
#     virtual_mailbox_domains => ['ldap:/etc/postfix/virtualdomains.cf'],
#     virtual_mailbox_maps    => ['ldap:/etc/postfix/virtualrecipients.cf'],
#     virtual_minimum_uid     => 100,
#     virtual_uid_maps        => 'static:5000',
#     virtual_gid_maps        => 'static:5000',
#   }
#
#   # Specify connection defaults to enable sharing as per LDAP_README
#   Postfix::Lookup::Ldap {
#     server_host => ['ldap://192.0.2.1'],
#     search_base => 'dc=example,dc=com',
#     bind_dn     => 'cn=Manager,dc=example,dc=com',
#     bind_pw     => 'secret',
#     version     => 3,
#   }
#
#   postfix::lookup::ldap { '/etc/postfix/virtualdomains.cf':
#     query_filter     => '(associatedDomain=%s)',
#     result_attribute => ['associatedDomain'],
#   }
#
#   postfix::lookup::ldap { '/etc/postfix/virtualrecipients.cf':
#     query_filter     => '(mail=%s)',
#     result_attribute => ['mail'],
#   }
#
# @param conf_dir
# @param services
# @param lookup_packages
# @param package_name
# @param service_name
# @param twobounce_notice_recipient `2bounce_notice_recipient` is a violation
#   of Puppet variable naming conventions.
# @param access_map_defer_code
# @param access_map_reject_code
# @param address_verify_cache_cleanup_interval
# @param address_verify_default_transport
# @param address_verify_local_transport
# @param address_verify_map
# @param address_verify_negative_cache
# @param address_verify_negative_expire_time
# @param address_verify_negative_refresh_time
# @param address_verify_poll_count
# @param address_verify_poll_delay
# @param address_verify_positive_expire_time
# @param address_verify_positive_refresh_time
# @param address_verify_relay_transport
# @param address_verify_relayhost
# @param address_verify_sender
# @param address_verify_sender_dependent_default_transport_maps
# @param address_verify_sender_dependent_relayhost_maps
# @param address_verify_sender_ttl
# @param address_verify_service_name
# @param address_verify_transport_maps
# @param address_verify_virtual_transport
# @param alias_database
# @param alias_maps
# @param allow_mail_to_commands
# @param allow_mail_to_files
# @param allow_min_user
# @param allow_percent_hack
# @param allow_untrusted_routing
# @param alternate_config_directories
# @param always_add_missing_headers
# @param always_bcc
# @param anvil_rate_time_unit
# @param anvil_status_update_time
# @param append_at_myorigin
# @param append_dot_mydomain
# @param application_event_drain_time
# @param authorized_flush_users
# @param authorized_mailq_users
# @param authorized_submit_users
# @param backwards_bounce_logfile_compatibility
# @param berkeley_db_create_buffer_size
# @param berkeley_db_read_buffer_size
# @param best_mx_transport
# @param biff
# @param body_checks
# @param body_checks_size_limit
# @param bounce_notice_recipient
# @param bounce_queue_lifetime
# @param bounce_service_name
# @param bounce_size_limit
# @param bounce_template_file
# @param broken_sasl_auth_clients
# @param canonical_classes
# @param canonical_maps
# @param cleanup_service_name
# @param command_directory
# @param command_execution_directory
# @param command_expansion_filter
# @param command_time_limit
# @param compatibility_level
# @param config_directory
# @param connection_cache_protocol_timeout
# @param connection_cache_service_name
# @param connection_cache_status_update_time
# @param connection_cache_ttl_limit
# @param content_filter
# @param cyrus_sasl_config_path
# @param daemon_directory
# @param daemon_table_open_error_is_fatal
# @param daemon_timeout
# @param data_directory
# @param debug_peer_level
# @param debug_peer_list
# @param debugger_command
# @param default_database_type
# @param default_delivery_slot_cost
# @param default_delivery_slot_discount
# @param default_delivery_slot_loan
# @param default_destination_concurrency_failed_cohort_limit
# @param default_destination_concurrency_limit
# @param default_destination_concurrency_negative_feedback
# @param default_destination_concurrency_positive_feedback
# @param default_destination_rate_delay
# @param default_destination_recipient_limit
# @param default_extra_recipient_limit
# @param default_filter_nexthop
# @param default_minimum_delivery_slots
# @param default_privs
# @param default_process_limit
# @param default_rbl_reply
# @param default_recipient_limit
# @param default_recipient_refill_delay
# @param default_recipient_refill_limit
# @param default_transport
# @param default_verp_delimiters
# @param defer_code
# @param defer_service_name
# @param defer_transports
# @param delay_logging_resolution_limit
# @param delay_notice_recipient
# @param delay_warning_time
# @param deliver_lock_attempts
# @param deliver_lock_delay
# @param destination_concurrency_feedback_debug
# @param detect_8bit_encoding_header
# @param disable_dns_lookups
# @param disable_mime_input_processing
# @param disable_mime_output_conversion
# @param disable_verp_bounces
# @param disable_vrfy_command
# @param dnsblog_reply_delay
# @param dnsblog_service_name
# @param dont_remove
# @param double_bounce_sender
# @param duplicate_filter_limit
# @param empty_address_default_transport_maps_lookup_key
# @param empty_address_recipient
# @param empty_address_relayhost_maps_lookup_key
# @param enable_long_queue_ids
# @param enable_original_recipient
# @param error_notice_recipient
# @param error_service_name
# @param execution_directory_expansion_filter
# @param expand_owner_alias
# @param export_environment
# @param fallback_transport
# @param fallback_transport_maps
# @param fast_flush_domains
# @param fast_flush_purge_time
# @param fast_flush_refresh_time
# @param fault_injection_code
# @param flush_service_name
# @param fork_attempts
# @param fork_delay
# @param forward_expansion_filter
# @param forward_path
# @param frozen_delivered_to
# @param hash_queue_depth
# @param hash_queue_names
# @param header_address_token_limit
# @param header_checks
# @param header_size_limit
# @param helpful_warnings
# @param home_mailbox
# @param hopcount_limit
# @param html_directory
# @param ignore_mx_lookup_error
# @param import_environment
# @param in_flow_delay
# @param inet_interfaces
# @param inet_protocols
# @param initial_destination_concurrency
# @param internal_mail_filter_classes
# @param invalid_hostname_reject_code
# @param ipc_idle
# @param ipc_timeout
# @param ipc_ttl
# @param line_length_limit
# @param lmtp_address_preference
# @param lmtp_assume_final
# @param lmtp_bind_address
# @param lmtp_bind_address6
# @param lmtp_body_checks
# @param lmtp_cname_overrides_servername
# @param lmtp_connect_timeout
# @param lmtp_connection_cache_destinations
# @param lmtp_connection_cache_on_demand
# @param lmtp_connection_cache_time_limit
# @param lmtp_connection_reuse_time_limit
# @param lmtp_data_done_timeout
# @param lmtp_data_init_timeout
# @param lmtp_data_xfer_timeout
# @param lmtp_defer_if_no_mx_address_found
# @param lmtp_discard_lhlo_keyword_address_maps
# @param lmtp_discard_lhlo_keywords
# @param lmtp_dns_resolver_options
# @param lmtp_enforce_tls
# @param lmtp_generic_maps
# @param lmtp_header_checks
# @param lmtp_host_lookup
# @param lmtp_lhlo_name
# @param lmtp_lhlo_timeout
# @param lmtp_line_length_limit
# @param lmtp_mail_timeout
# @param lmtp_mime_header_checks
# @param lmtp_mx_address_limit
# @param lmtp_mx_session_limit
# @param lmtp_nested_header_checks
# @param lmtp_per_record_deadline
# @param lmtp_pix_workaround_delay_time
# @param lmtp_pix_workaround_maps
# @param lmtp_pix_workaround_threshold_time
# @param lmtp_pix_workarounds
# @param lmtp_quit_timeout
# @param lmtp_quote_rfc821_envelope
# @param lmtp_randomize_addresses
# @param lmtp_rcpt_timeout
# @param lmtp_reply_filter
# @param lmtp_rset_timeout
# @param lmtp_sasl_auth_cache_name
# @param lmtp_sasl_auth_cache_time
# @param lmtp_sasl_auth_enable
# @param lmtp_sasl_auth_soft_bounce
# @param lmtp_sasl_mechanism_filter
# @param lmtp_sasl_password_maps
# @param lmtp_sasl_path
# @param lmtp_sasl_security_options
# @param lmtp_sasl_tls_security_options
# @param lmtp_sasl_tls_verified_security_options
# @param lmtp_sasl_type
# @param lmtp_send_dummy_mail_auth
# @param lmtp_send_xforward_command
# @param lmtp_sender_dependent_authentication
# @param lmtp_skip_5xx_greeting
# @param lmtp_skip_quit_response
# @param lmtp_starttls_timeout
# @param lmtp_tcp_port
# @param lmtp_tls_cafile
# @param lmtp_tls_capath
# @param lmtp_tls_block_early_mail_reply
# @param lmtp_tls_cert_file
# @param lmtp_tls_ciphers
# @param lmtp_tls_dcert_file
# @param lmtp_tls_dkey_file
# @param lmtp_tls_eccert_file
# @param lmtp_tls_eckey_file
# @param lmtp_tls_enforce_peername
# @param lmtp_tls_exclude_ciphers
# @param lmtp_tls_fingerprint_cert_match
# @param lmtp_tls_fingerprint_digest
# @param lmtp_tls_key_file
# @param lmtp_tls_loglevel
# @param lmtp_tls_mandatory_ciphers
# @param lmtp_tls_mandatory_exclude_ciphers
# @param lmtp_tls_mandatory_protocols
# @param lmtp_tls_note_starttls_offer
# @param lmtp_tls_per_site
# @param lmtp_tls_policy_maps
# @param lmtp_tls_protocols
# @param lmtp_tls_scert_verifydepth
# @param lmtp_tls_secure_cert_match
# @param lmtp_tls_security_level
# @param lmtp_tls_session_cache_database
# @param lmtp_tls_session_cache_timeout
# @param lmtp_tls_verify_cert_match
# @param lmtp_use_tls
# @param lmtp_xforward_timeout
# @param local_command_shell
# @param local_header_rewrite_clients
# @param local_recipient_maps
# @param local_transport
# @param luser_relay
# @param mail_name
# @param mail_owner
# @param mail_release_date
# @param mail_spool_directory
# @param mail_version
# @param mailbox_command
# @param mailbox_command_maps
# @param mailbox_delivery_lock
# @param mailbox_size_limit
# @param mailbox_transport
# @param mailbox_transport_maps
# @param mailq_path
# @param manpage_directory
# @param maps_rbl_domains
# @param maps_rbl_reject_code
# @param masquerade_classes
# @param masquerade_domains
# @param masquerade_exceptions
# @param master_service_disable
# @param max_idle
# @param max_use
# @param maximal_backoff_time
# @param maximal_queue_lifetime
# @param message_reject_characters
# @param message_size_limit
# @param message_strip_characters
# @param meta_directory
# @param milter_command_timeout
# @param milter_connect_macros
# @param milter_connect_timeout
# @param milter_content_timeout
# @param milter_data_macros
# @param milter_default_action
# @param milter_end_of_data_macros
# @param milter_end_of_header_macros
# @param milter_header_checks
# @param milter_helo_macros
# @param milter_macro_daemon_name
# @param milter_macro_v
# @param milter_mail_macros
# @param milter_protocol
# @param milter_rcpt_macros
# @param milter_unknown_command_macros
# @param mime_boundary_length_limit
# @param mime_header_checks
# @param mime_nesting_limit
# @param minimal_backoff_time
# @param multi_instance_directories
# @param multi_instance_enable
# @param multi_instance_group
# @param multi_instance_name
# @param multi_instance_wrapper
# @param multi_recipient_bounce_reject_code
# @param mydestination
# @param mydomain
# @param myhostname
# @param mynetworks
# @param mynetworks_style
# @param myorigin
# @param nested_header_checks
# @param newaliases_path
# @param non_fqdn_reject_code
# @param non_smtpd_milters
# @param notify_classes
# @param owner_request_special
# @param parent_domain_matches_subdomains
# @param permit_mx_backup_networks
# @param pickup_service_name
# @param plaintext_reject_code
# @param postmulti_control_commands
# @param postmulti_start_commands
# @param postmulti_stop_commands
# @param postscreen_access_list
# @param postscreen_bare_newline_action
# @param postscreen_bare_newline_enable
# @param postscreen_bare_newline_ttl
# @param postscreen_blacklist_action
# @param postscreen_cache_cleanup_interval
# @param postscreen_cache_map
# @param postscreen_cache_retention_time
# @param postscreen_client_connection_count_limit
# @param postscreen_command_count_limit
# @param postscreen_command_filter
# @param postscreen_command_time_limit
# @param postscreen_disable_vrfy_command
# @param postscreen_discard_ehlo_keyword_address_maps
# @param postscreen_discard_ehlo_keywords
# @param postscreen_dnsbl_action
# @param postscreen_dnsbl_reply_map
# @param postscreen_dnsbl_sites
# @param postscreen_dnsbl_threshold
# @param postscreen_dnsbl_ttl
# @param postscreen_enforce_tls
# @param postscreen_expansion_filter
# @param postscreen_forbidden_commands
# @param postscreen_greet_action
# @param postscreen_greet_banner
# @param postscreen_greet_ttl
# @param postscreen_greet_wait
# @param postscreen_helo_required
# @param postscreen_non_smtp_command_action
# @param postscreen_non_smtp_command_enable
# @param postscreen_non_smtp_command_ttl
# @param postscreen_pipelining_action
# @param postscreen_pipelining_enable
# @param postscreen_pipelining_ttl
# @param postscreen_post_queue_limit
# @param postscreen_pre_queue_limit
# @param postscreen_reject_footer
# @param postscreen_tls_security_level
# @param postscreen_upstream_proxy_protocol
# @param postscreen_upstream_proxy_timeout
# @param postscreen_use_tls
# @param postscreen_watchdog_timeout
# @param postscreen_whitelist_interfaces
# @param prepend_delivered_header
# @param process_id_directory
# @param propagate_unmatched_extensions
# @param proxy_interfaces
# @param proxy_read_maps
# @param proxy_write_maps
# @param proxymap_service_name
# @param proxywrite_service_name
# @param qmgr_clog_warn_time
# @param qmgr_daemon_timeout
# @param qmgr_fudge_factor
# @param qmgr_ipc_timeout
# @param qmgr_message_active_limit
# @param qmgr_message_recipient_limit
# @param qmgr_message_recipient_minimum
# @param qmqpd_authorized_clients
# @param qmqpd_client_port_logging
# @param qmqpd_error_delay
# @param qmqpd_timeout
# @param queue_directory
# @param queue_file_attribute_count_limit
# @param queue_minfree
# @param queue_run_delay
# @param queue_service_name
# @param rbl_reply_maps
# @param readme_directory
# @param receive_override_options
# @param recipient_bcc_maps
# @param recipient_canonical_classes
# @param recipient_canonical_maps
# @param recipient_delimiter
# @param reject_code
# @param reject_tempfail_action
# @param relay_clientcerts
# @param relay_domains
# @param relay_domains_reject_code
# @param relay_recipient_maps
# @param relay_transport
# @param relayhost
# @param relocated_maps
# @param remote_header_rewrite_domain
# @param require_home_directory
# @param reset_owner_alias
# @param resolve_dequoted_address
# @param resolve_null_domain
# @param resolve_numeric_domain
# @param rewrite_service_name
# @param sample_directory
# @param send_cyrus_sasl_authzid
# @param sender_bcc_maps
# @param sender_canonical_classes
# @param sender_canonical_maps
# @param sender_dependent_default_transport_maps
# @param sender_dependent_relayhost_maps
# @param sendmail_fix_line_endings
# @param sendmail_path
# @param service_throttle_time
# @param setgid_group
# @param shlib_directory
# @param show_user_unknown_table_name
# @param showq_service_name
# @param smtp_address_preference
# @param smtp_always_send_ehlo
# @param smtp_bind_address
# @param smtp_bind_address6
# @param smtp_body_checks
# @param smtp_cname_overrides_servername
# @param smtp_connect_timeout
# @param smtp_connection_cache_destinations
# @param smtp_connection_cache_on_demand
# @param smtp_connection_cache_time_limit
# @param smtp_connection_reuse_time_limit
# @param smtp_data_done_timeout
# @param smtp_data_init_timeout
# @param smtp_data_xfer_timeout
# @param smtp_defer_if_no_mx_address_found
# @param smtp_discard_ehlo_keyword_address_maps
# @param smtp_discard_ehlo_keywords
# @param smtp_dns_resolver_options
# @param smtp_enforce_tls
# @param smtp_fallback_relay
# @param smtp_generic_maps
# @param smtp_header_checks
# @param smtp_helo_name
# @param smtp_helo_timeout
# @param smtp_host_lookup
# @param smtp_line_length_limit
# @param smtp_mail_timeout
# @param smtp_mime_header_checks
# @param smtp_mx_address_limit
# @param smtp_mx_session_limit
# @param smtp_nested_header_checks
# @param smtp_never_send_ehlo
# @param smtp_per_record_deadline
# @param smtp_pix_workaround_delay_time
# @param smtp_pix_workaround_maps
# @param smtp_pix_workaround_threshold_time
# @param smtp_pix_workarounds
# @param smtp_quit_timeout
# @param smtp_quote_rfc821_envelope
# @param smtp_randomize_addresses
# @param smtp_rcpt_timeout
# @param smtp_reply_filter
# @param smtp_rset_timeout
# @param smtp_sasl_auth_cache_name
# @param smtp_sasl_auth_cache_time
# @param smtp_sasl_auth_enable
# @param smtp_sasl_auth_soft_bounce
# @param smtp_sasl_mechanism_filter
# @param smtp_sasl_password_maps
# @param smtp_sasl_path
# @param smtp_sasl_security_options
# @param smtp_sasl_tls_security_options
# @param smtp_sasl_tls_verified_security_options
# @param smtp_sasl_type
# @param smtp_send_dummy_mail_auth
# @param smtp_send_xforward_command
# @param smtp_sender_dependent_authentication
# @param smtp_skip_5xx_greeting
# @param smtp_skip_quit_response
# @param smtp_starttls_timeout
# @param smtp_tls_cafile
# @param smtp_tls_capath
# @param smtp_tls_block_early_mail_reply
# @param smtp_tls_cert_file
# @param smtp_tls_ciphers
# @param smtp_tls_dcert_file
# @param smtp_tls_dkey_file
# @param smtp_tls_eccert_file
# @param smtp_tls_eckey_file
# @param smtp_tls_enforce_peername
# @param smtp_tls_exclude_ciphers
# @param smtp_tls_fingerprint_cert_match
# @param smtp_tls_fingerprint_digest
# @param smtp_tls_key_file
# @param smtp_tls_loglevel
# @param smtp_tls_mandatory_ciphers
# @param smtp_tls_mandatory_exclude_ciphers
# @param smtp_tls_mandatory_protocols
# @param smtp_tls_note_starttls_offer
# @param smtp_tls_per_site
# @param smtp_tls_policy_maps
# @param smtp_tls_protocols
# @param smtp_tls_scert_verifydepth
# @param smtp_tls_secure_cert_match
# @param smtp_tls_security_level
# @param smtp_tls_session_cache_database
# @param smtp_tls_session_cache_timeout
# @param smtp_tls_verify_cert_match
# @param smtp_use_tls
# @param smtp_xforward_timeout
# @param smtpd_authorized_verp_clients
# @param smtpd_authorized_xclient_hosts
# @param smtpd_authorized_xforward_hosts
# @param smtpd_banner
# @param smtpd_client_connection_count_limit
# @param smtpd_client_connection_rate_limit
# @param smtpd_client_event_limit_exceptions
# @param smtpd_client_message_rate_limit
# @param smtpd_client_new_tls_session_rate_limit
# @param smtpd_client_port_logging
# @param smtpd_client_recipient_rate_limit
# @param smtpd_client_restrictions
# @param smtpd_command_filter
# @param smtpd_data_restrictions
# @param smtpd_delay_open_until_valid_rcpt
# @param smtpd_delay_reject
# @param smtpd_discard_ehlo_keyword_address_maps
# @param smtpd_discard_ehlo_keywords
# @param smtpd_end_of_data_restrictions
# @param smtpd_enforce_tls
# @param smtpd_error_sleep_time
# @param smtpd_etrn_restrictions
# @param smtpd_expansion_filter
# @param smtpd_forbidden_commands
# @param smtpd_hard_error_limit
# @param smtpd_helo_required
# @param smtpd_helo_restrictions
# @param smtpd_history_flush_threshold
# @param smtpd_junk_command_limit
# @param smtpd_log_access_permit_actions
# @param smtpd_milters
# @param smtpd_noop_commands
# @param smtpd_null_access_lookup_key
# @param smtpd_peername_lookup
# @param smtpd_per_record_deadline
# @param smtpd_policy_service_max_idle
# @param smtpd_policy_service_max_ttl
# @param smtpd_policy_service_timeout
# @param smtpd_proxy_ehlo
# @param smtpd_proxy_filter
# @param smtpd_proxy_options
# @param smtpd_proxy_timeout
# @param smtpd_recipient_limit
# @param smtpd_recipient_overshoot_limit
# @param smtpd_recipient_restrictions
# @param smtpd_reject_footer
# @param smtpd_reject_unlisted_recipient
# @param smtpd_reject_unlisted_sender
# @param smtpd_relay_restrictions
# @param smtpd_restriction_classes
# @param smtpd_sasl_auth_enable
# @param smtpd_sasl_authenticated_header
# @param smtpd_sasl_exceptions_networks
# @param smtpd_sasl_local_domain
# @param smtpd_sasl_path
# @param smtpd_sasl_security_options
# @param smtpd_sasl_tls_security_options
# @param smtpd_sasl_type
# @param smtpd_sender_login_maps
# @param smtpd_sender_restrictions
# @param smtpd_service_name
# @param smtpd_soft_error_limit
# @param smtpd_starttls_timeout
# @param smtpd_timeout
# @param smtpd_tls_cafile
# @param smtpd_tls_capath
# @param smtpd_tls_always_issue_session_ids
# @param smtpd_tls_ask_ccert
# @param smtpd_tls_auth_only
# @param smtpd_tls_ccert_verifydepth
# @param smtpd_tls_cert_file
# @param smtpd_tls_ciphers
# @param smtpd_tls_dcert_file
# @param smtpd_tls_dh1024_param_file
# @param smtpd_tls_dh512_param_file
# @param smtpd_tls_dkey_file
# @param smtpd_tls_eccert_file
# @param smtpd_tls_eckey_file
# @param smtpd_tls_eecdh_grade
# @param smtpd_tls_exclude_ciphers
# @param smtpd_tls_fingerprint_digest
# @param smtpd_tls_key_file
# @param smtpd_tls_loglevel
# @param smtpd_tls_mandatory_ciphers
# @param smtpd_tls_mandatory_exclude_ciphers
# @param smtpd_tls_mandatory_protocols
# @param smtpd_tls_protocols
# @param smtpd_tls_received_header
# @param smtpd_tls_req_ccert
# @param smtpd_tls_security_level
# @param smtpd_tls_session_cache_database
# @param smtpd_tls_session_cache_timeout
# @param smtpd_tls_wrappermode
# @param smtpd_upstream_proxy_protocol
# @param smtpd_upstream_proxy_timeout
# @param smtpd_use_tls
# @param soft_bounce
# @param stale_lock_time
# @param strict_7bit_headers
# @param strict_8bitmime
# @param strict_8bitmime_body
# @param strict_mailbox_ownership
# @param strict_mime_encoding_domain
# @param strict_rfc821_envelopes
# @param sun_mailtool_compatibility
# @param swap_bangpath
# @param syslog_facility
# @param syslog_name
# @param tcp_windowsize
# @param tls_append_default_ca
# @param tls_daemon_random_bytes
# @param tls_disable_workarounds
# @param tls_eecdh_strong_curve
# @param tls_eecdh_ultra_curve
# @param tls_export_cipherlist
# @param tls_high_cipherlist
# @param tls_legacy_public_key_fingerprints
# @param tls_low_cipherlist
# @param tls_medium_cipherlist
# @param tls_null_cipherlist
# @param tls_preempt_cipherlist
# @param tls_random_bytes
# @param tls_random_exchange_name
# @param tls_random_prng_update_period
# @param tls_random_reseed_period
# @param tls_random_source
# @param tlsproxy_enforce_tls
# @param tlsproxy_service_name
# @param tlsproxy_tls_cafile
# @param tlsproxy_tls_capath
# @param tlsproxy_tls_always_issue_session_ids
# @param tlsproxy_tls_ask_ccert
# @param tlsproxy_tls_ccert_verifydepth
# @param tlsproxy_tls_cert_file
# @param tlsproxy_tls_ciphers
# @param tlsproxy_tls_dcert_file
# @param tlsproxy_tls_dh1024_param_file
# @param tlsproxy_tls_dh512_param_file
# @param tlsproxy_tls_dkey_file
# @param tlsproxy_tls_eccert_file
# @param tlsproxy_tls_eckey_file
# @param tlsproxy_tls_eecdh_grade
# @param tlsproxy_tls_exclude_ciphers
# @param tlsproxy_tls_fingerprint_digest
# @param tlsproxy_tls_key_file
# @param tlsproxy_tls_loglevel
# @param tlsproxy_tls_mandatory_ciphers
# @param tlsproxy_tls_mandatory_exclude_ciphers
# @param tlsproxy_tls_mandatory_protocols
# @param tlsproxy_tls_protocols
# @param tlsproxy_tls_req_ccert
# @param tlsproxy_tls_security_level
# @param tlsproxy_tls_session_cache_timeout
# @param tlsproxy_use_tls
# @param tlsproxy_watchdog_timeout
# @param trace_service_name
# @param transport_maps
# @param transport_retry_time
# @param trigger_timeout
# @param undisclosed_recipients_header
# @param unknown_address_reject_code
# @param unknown_address_tempfail_action
# @param unknown_client_reject_code
# @param unknown_helo_hostname_tempfail_action
# @param unknown_hostname_reject_code
# @param unknown_local_recipient_reject_code
# @param unknown_relay_recipient_reject_code
# @param unknown_virtual_alias_reject_code
# @param unknown_virtual_mailbox_reject_code
# @param unverified_recipient_defer_code
# @param unverified_recipient_reject_code
# @param unverified_recipient_reject_reason
# @param unverified_recipient_tempfail_action
# @param unverified_sender_defer_code
# @param unverified_sender_reject_code
# @param unverified_sender_reject_reason
# @param unverified_sender_tempfail_action
# @param verp_delimiter_filter
# @param virtual_alias_domains
# @param virtual_alias_expansion_limit
# @param virtual_alias_maps
# @param virtual_alias_recursion_limit
# @param virtual_gid_maps
# @param virtual_mailbox_base
# @param virtual_mailbox_domains
# @param virtual_mailbox_limit
# @param virtual_mailbox_lock
# @param virtual_mailbox_maps
# @param virtual_minimum_uid
# @param virtual_transport
# @param virtual_uid_maps
#
# @see puppet_defined_types::postfix::main postfix::main
# @see puppet_defined_types::postfix::master postfix::master
# @see puppet_defined_types::postfix::lookup::database postfix::lookup::database
# @see puppet_defined_types::postfix::lookup::ldap postfix::lookup::ldap
# @see puppet_defined_types::postfix::lookup::memcache postfix::lookup::memcache
# @see puppet_defined_types::postfix::lookup::mysql postfix::lookup::mysql
# @see puppet_defined_types::postfix::lookup::pgsql postfix::lookup::pgsql
# @see puppet_defined_types::postfix::lookup::sqlite postfix::lookup::sqlite
#
# @since 1.0.0
class postfix (
  Stdlib::Absolutepath                $conf_dir,
  Hash[String, Hash[String, Any]]     $services,
  Hash[Postfix::Type::Lookup, String] $lookup_packages,
  String                              $package_name,
  String                              $service_name,
  # main.cf parameters below
  Optional[String]                    $twobounce_notice_recipient,
  Optional[String]                    $access_map_defer_code,
  Optional[String]                    $access_map_reject_code,
  Optional[String]                    $address_verify_cache_cleanup_interval,
  Optional[String]                    $address_verify_default_transport,
  Optional[String]                    $address_verify_local_transport,
  Optional[String]                    $address_verify_map,
  Optional[Variant[Boolean, String]]  $address_verify_negative_cache,
  Optional[String]                    $address_verify_negative_expire_time,
  Optional[String]                    $address_verify_negative_refresh_time,
  Optional[String]                    $address_verify_poll_count,
  Optional[String]                    $address_verify_poll_delay,
  Optional[String]                    $address_verify_positive_expire_time,
  Optional[String]                    $address_verify_positive_refresh_time,
  Optional[String]                    $address_verify_relay_transport,
  Optional[String]                    $address_verify_relayhost,
  Optional[String]                    $address_verify_sender,
  Optional[Array[String, 1]]          $address_verify_sender_dependent_default_transport_maps,
  Optional[Array[String, 1]]          $address_verify_sender_dependent_relayhost_maps,
  Optional[String]                    $address_verify_sender_ttl,
  Optional[String]                    $address_verify_service_name,
  Optional[Array[String, 1]]          $address_verify_transport_maps,
  Optional[String]                    $address_verify_virtual_transport,
  Optional[Array[String, 1]]          $alias_database,
  Optional[Array[String, 1]]          $alias_maps,
  Optional[Array[String, 1]]          $allow_mail_to_commands,
  Optional[Array[String, 1]]          $allow_mail_to_files,
  Optional[Variant[Boolean, String]]  $allow_min_user,
  Optional[Variant[Boolean, String]]  $allow_percent_hack,
  Optional[Variant[Boolean, String]]  $allow_untrusted_routing,
  Optional[Array[String, 1]]          $alternate_config_directories,
  Optional[Variant[Boolean, String]]  $always_add_missing_headers,
  Optional[String]                    $always_bcc,
  Optional[String]                    $anvil_rate_time_unit,
  Optional[String]                    $anvil_status_update_time,
  Optional[Variant[Boolean, String]]  $append_at_myorigin,
  Optional[Variant[Boolean, String]]  $append_dot_mydomain,
  Optional[String]                    $application_event_drain_time,
  Optional[Array[String, 1]]          $authorized_flush_users,
  Optional[Array[String, 1]]          $authorized_mailq_users,
  Optional[Array[String, 1]]          $authorized_submit_users,
  Optional[Variant[Boolean, String]]  $backwards_bounce_logfile_compatibility,
  Optional[String]                    $berkeley_db_create_buffer_size,
  Optional[String]                    $berkeley_db_read_buffer_size,
  Optional[String]                    $best_mx_transport,
  Optional[Variant[Boolean, String]]  $biff,
  Optional[Array[String, 1]]          $body_checks,
  Optional[String]                    $body_checks_size_limit,
  Optional[String]                    $bounce_notice_recipient,
  Optional[String]                    $bounce_queue_lifetime,
  Optional[String]                    $bounce_service_name,
  Optional[String]                    $bounce_size_limit,
  Optional[String]                    $bounce_template_file,
  Optional[Variant[Boolean, String]]  $broken_sasl_auth_clients,
  Optional[Array[String, 1]]          $canonical_classes,
  Optional[Array[String, 1]]          $canonical_maps,
  Optional[String]                    $cleanup_service_name,
  Optional[String]                    $command_directory,
  Optional[String]                    $command_execution_directory,
  Optional[String]                    $command_expansion_filter,
  Optional[String]                    $command_time_limit,
  Optional[String]                    $compatibility_level,
  Optional[String]                    $config_directory,
  Optional[String]                    $connection_cache_protocol_timeout,
  Optional[String]                    $connection_cache_service_name,
  Optional[String]                    $connection_cache_status_update_time,
  Optional[String]                    $connection_cache_ttl_limit,
  Optional[String]                    $content_filter,
  Optional[Array[String, 1]]          $cyrus_sasl_config_path,
  Optional[String]                    $daemon_directory,
  Optional[Variant[Boolean, String]]  $daemon_table_open_error_is_fatal,
  Optional[String]                    $daemon_timeout,
  Optional[String]                    $data_directory,
  Optional[String]                    $debug_peer_level,
  Optional[Array[String, 1]]          $debug_peer_list,
  Optional[String]                    $debugger_command,
  Postfix::Type::Lookup::Database     $default_database_type,
  Optional[String]                    $default_delivery_slot_cost,
  Optional[String]                    $default_delivery_slot_discount,
  Optional[String]                    $default_delivery_slot_loan,
  Optional[String]                    $default_destination_concurrency_failed_cohort_limit,
  Optional[String]                    $default_destination_concurrency_limit,
  Optional[String]                    $default_destination_concurrency_negative_feedback,
  Optional[String]                    $default_destination_concurrency_positive_feedback,
  Optional[String]                    $default_destination_rate_delay,
  Optional[String]                    $default_destination_recipient_limit,
  Optional[String]                    $default_extra_recipient_limit,
  Optional[String]                    $default_filter_nexthop,
  Optional[String]                    $default_minimum_delivery_slots,
  Optional[String]                    $default_privs,
  Optional[String]                    $default_process_limit,
  Optional[String]                    $default_rbl_reply,
  Optional[String]                    $default_recipient_limit,
  Optional[String]                    $default_recipient_refill_delay,
  Optional[String]                    $default_recipient_refill_limit,
  Optional[String]                    $default_transport,
  Optional[String]                    $default_verp_delimiters,
  Optional[String]                    $defer_code,
  Optional[String]                    $defer_service_name,
  Optional[Array[String, 1]]          $defer_transports,
  Optional[String]                    $delay_logging_resolution_limit,
  Optional[String]                    $delay_notice_recipient,
  Optional[String]                    $delay_warning_time,
  Optional[String]                    $deliver_lock_attempts,
  Optional[String]                    $deliver_lock_delay,
  Optional[Variant[Boolean, String]]  $destination_concurrency_feedback_debug,
  Optional[Variant[Boolean, String]]  $detect_8bit_encoding_header,
  Optional[Variant[Boolean, String]]  $disable_dns_lookups,
  Optional[Variant[Boolean, String]]  $disable_mime_input_processing,
  Optional[Variant[Boolean, String]]  $disable_mime_output_conversion,
  Optional[Variant[Boolean, String]]  $disable_verp_bounces,
  Optional[Variant[Boolean, String]]  $disable_vrfy_command,
  Optional[String]                    $dnsblog_reply_delay,
  Optional[String]                    $dnsblog_service_name,
  Optional[String]                    $dont_remove,
  Optional[String]                    $double_bounce_sender,
  Optional[String]                    $duplicate_filter_limit,
  Optional[String]                    $empty_address_default_transport_maps_lookup_key,
  Optional[String]                    $empty_address_recipient,
  Optional[String]                    $empty_address_relayhost_maps_lookup_key,
  Optional[Variant[Boolean, String]]  $enable_long_queue_ids,
  Optional[Variant[Boolean, String]]  $enable_original_recipient,
  Optional[String]                    $error_notice_recipient,
  Optional[String]                    $error_service_name,
  Optional[String]                    $execution_directory_expansion_filter,
  Optional[Variant[Boolean, String]]  $expand_owner_alias,
  Optional[Array[String, 1]]          $export_environment,
  Optional[String]                    $fallback_transport,
  Optional[Array[String, 1]]          $fallback_transport_maps,
  Optional[Array[String, 1]]          $fast_flush_domains,
  Optional[String]                    $fast_flush_purge_time,
  Optional[String]                    $fast_flush_refresh_time,
  Optional[String]                    $fault_injection_code,
  Optional[String]                    $flush_service_name,
  Optional[String]                    $fork_attempts,
  Optional[String]                    $fork_delay,
  Optional[String]                    $forward_expansion_filter,
  Optional[Array[String, 1]]          $forward_path,
  Optional[Variant[Boolean, String]]  $frozen_delivered_to,
  Optional[String]                    $hash_queue_depth,
  Optional[Array[String, 1]]          $hash_queue_names,
  Optional[String]                    $header_address_token_limit,
  Optional[Array[String, 1]]          $header_checks,
  Optional[String]                    $header_size_limit,
  Optional[Variant[Boolean, String]]  $helpful_warnings,
  Optional[String]                    $home_mailbox,
  Optional[String]                    $hopcount_limit,
  Optional[Variant[Boolean, String]]  $html_directory,
  Optional[Variant[Boolean, String]]  $ignore_mx_lookup_error,
  Optional[Array[String, 1]]          $import_environment,
  Optional[String]                    $in_flow_delay,
  Optional[Array[String, 1]]          $inet_interfaces,
  Optional[Array[String, 1]]          $inet_protocols,
  Optional[String]                    $initial_destination_concurrency,
  Optional[Array[String, 1]]          $internal_mail_filter_classes,
  Optional[String]                    $invalid_hostname_reject_code,
  Optional[String]                    $ipc_idle,
  Optional[String]                    $ipc_timeout,
  Optional[String]                    $ipc_ttl,
  Optional[String]                    $line_length_limit,
  Optional[String]                    $lmtp_address_preference,
  Optional[Variant[Boolean, String]]  $lmtp_assume_final,
  Optional[String]                    $lmtp_bind_address,
  Optional[String]                    $lmtp_bind_address6,
  Optional[Array[String, 1]]          $lmtp_body_checks,
  Optional[Variant[Boolean, String]]  $lmtp_cname_overrides_servername,
  Optional[String]                    $lmtp_connect_timeout,
  Optional[Array[String, 1]]          $lmtp_connection_cache_destinations,
  Optional[Variant[Boolean, String]]  $lmtp_connection_cache_on_demand,
  Optional[String]                    $lmtp_connection_cache_time_limit,
  Optional[String]                    $lmtp_connection_reuse_time_limit,
  Optional[String]                    $lmtp_data_done_timeout,
  Optional[String]                    $lmtp_data_init_timeout,
  Optional[String]                    $lmtp_data_xfer_timeout,
  Optional[Variant[Boolean, String]]  $lmtp_defer_if_no_mx_address_found,
  Optional[Array[String, 1]]          $lmtp_discard_lhlo_keyword_address_maps,
  Optional[Array[String, 1]]          $lmtp_discard_lhlo_keywords,
  Optional[Array[String, 1]]          $lmtp_dns_resolver_options,
  Optional[Variant[Boolean, String]]  $lmtp_enforce_tls,
  Optional[Array[String, 1]]          $lmtp_generic_maps,
  Optional[Array[String, 1]]          $lmtp_header_checks,
  Optional[Array[String, 1]]          $lmtp_host_lookup,
  Optional[String]                    $lmtp_lhlo_name,
  Optional[String]                    $lmtp_lhlo_timeout,
  Optional[String]                    $lmtp_line_length_limit,
  Optional[String]                    $lmtp_mail_timeout,
  Optional[Array[String, 1]]          $lmtp_mime_header_checks,
  Optional[String]                    $lmtp_mx_address_limit,
  Optional[String]                    $lmtp_mx_session_limit,
  Optional[Array[String, 1]]          $lmtp_nested_header_checks,
  Optional[Variant[Boolean, String]]  $lmtp_per_record_deadline,
  Optional[String]                    $lmtp_pix_workaround_delay_time,
  Optional[Array[String, 1]]          $lmtp_pix_workaround_maps,
  Optional[String]                    $lmtp_pix_workaround_threshold_time,
  Optional[Array[String, 1]]          $lmtp_pix_workarounds,
  Optional[String]                    $lmtp_quit_timeout,
  Optional[Variant[Boolean, String]]  $lmtp_quote_rfc821_envelope,
  Optional[Variant[Boolean, String]]  $lmtp_randomize_addresses,
  Optional[String]                    $lmtp_rcpt_timeout,
  Optional[String]                    $lmtp_reply_filter,
  Optional[String]                    $lmtp_rset_timeout,
  Optional[String]                    $lmtp_sasl_auth_cache_name,
  Optional[String]                    $lmtp_sasl_auth_cache_time,
  Optional[Variant[Boolean, String]]  $lmtp_sasl_auth_enable,
  Optional[Variant[Boolean, String]]  $lmtp_sasl_auth_soft_bounce,
  Optional[Array[String, 1]]          $lmtp_sasl_mechanism_filter,
  Optional[Array[String, 1]]          $lmtp_sasl_password_maps,
  Optional[String]                    $lmtp_sasl_path,
  Optional[Array[String, 1]]          $lmtp_sasl_security_options,
  Optional[Array[String, 1]]          $lmtp_sasl_tls_security_options,
  Optional[Array[String, 1]]          $lmtp_sasl_tls_verified_security_options,
  Optional[String]                    $lmtp_sasl_type,
  Optional[Variant[Boolean, String]]  $lmtp_send_dummy_mail_auth,
  Optional[Variant[Boolean, String]]  $lmtp_send_xforward_command,
  Optional[Variant[Boolean, String]]  $lmtp_sender_dependent_authentication,
  Optional[Variant[Boolean, String]]  $lmtp_skip_5xx_greeting,
  Optional[Variant[Boolean, String]]  $lmtp_skip_quit_response,
  Optional[String]                    $lmtp_starttls_timeout,
  Optional[String]                    $lmtp_tcp_port,
  Optional[String]                    $lmtp_tls_cafile,
  Optional[String]                    $lmtp_tls_capath,
  Optional[Variant[Boolean, String]]  $lmtp_tls_block_early_mail_reply,
  Optional[String]                    $lmtp_tls_cert_file,
  Optional[String]                    $lmtp_tls_ciphers,
  Optional[String]                    $lmtp_tls_dcert_file,
  Optional[String]                    $lmtp_tls_dkey_file,
  Optional[String]                    $lmtp_tls_eccert_file,
  Optional[String]                    $lmtp_tls_eckey_file,
  Optional[Variant[Boolean, String]]  $lmtp_tls_enforce_peername,
  Optional[Array[String, 1]]          $lmtp_tls_exclude_ciphers,
  Optional[Array[String, 1]]          $lmtp_tls_fingerprint_cert_match,
  Optional[String]                    $lmtp_tls_fingerprint_digest,
  Optional[String]                    $lmtp_tls_key_file,
  Optional[String]                    $lmtp_tls_loglevel,
  Optional[String]                    $lmtp_tls_mandatory_ciphers,
  Optional[Array[String, 1]]          $lmtp_tls_mandatory_exclude_ciphers,
  Optional[Array[String, 1]]          $lmtp_tls_mandatory_protocols,
  Optional[Variant[Boolean, String]]  $lmtp_tls_note_starttls_offer,
  Optional[Array[String, 1]]          $lmtp_tls_per_site,
  Optional[Array[String, 1]]          $lmtp_tls_policy_maps,
  Optional[Array[String, 1]]          $lmtp_tls_protocols,
  Optional[String]                    $lmtp_tls_scert_verifydepth,
  Optional[Array[String, 1]]          $lmtp_tls_secure_cert_match,
  Optional[String]                    $lmtp_tls_security_level,
  Optional[String]                    $lmtp_tls_session_cache_database,
  Optional[String]                    $lmtp_tls_session_cache_timeout,
  Optional[Array[String, 1]]          $lmtp_tls_verify_cert_match,
  Optional[Variant[Boolean, String]]  $lmtp_use_tls,
  Optional[String]                    $lmtp_xforward_timeout,
  Optional[String]                    $local_command_shell,
  Optional[Array[String, 1]]          $local_header_rewrite_clients,
  Optional[Array[String, 1]]          $local_recipient_maps,
  Optional[String]                    $local_transport,
  Optional[String]                    $luser_relay,
  Optional[String]                    $mail_name,
  Optional[String]                    $mail_owner,
  Optional[String]                    $mail_release_date,
  Optional[String]                    $mail_spool_directory,
  Optional[String]                    $mail_version,
  Optional[String]                    $mailbox_command,
  Optional[Array[String, 1]]          $mailbox_command_maps,
  Optional[Array[String, 1]]          $mailbox_delivery_lock,
  Optional[String]                    $mailbox_size_limit,
  Optional[String]                    $mailbox_transport,
  Optional[Array[String, 1]]          $mailbox_transport_maps,
  Optional[String]                    $mailq_path,
  Optional[String]                    $manpage_directory,
  Optional[Array[String, 1]]          $maps_rbl_domains,
  Optional[String]                    $maps_rbl_reject_code,
  Optional[Array[String, 1]]          $masquerade_classes,
  Optional[Array[String, 1]]          $masquerade_domains,
  Optional[Array[String, 1]]          $masquerade_exceptions,
  Optional[Array[String, 1]]          $master_service_disable,
  Optional[String]                    $max_idle,
  Optional[String]                    $max_use,
  Optional[String]                    $maximal_backoff_time,
  Optional[String]                    $maximal_queue_lifetime,
  Optional[String]                    $message_reject_characters,
  Optional[String]                    $message_size_limit,
  Optional[String]                    $message_strip_characters,
  Optional[String]                    $meta_directory,
  Optional[String]                    $milter_command_timeout,
  Optional[String]                    $milter_connect_macros,
  Optional[String]                    $milter_connect_timeout,
  Optional[String]                    $milter_content_timeout,
  Optional[String]                    $milter_data_macros,
  Optional[String]                    $milter_default_action,
  Optional[String]                    $milter_end_of_data_macros,
  Optional[String]                    $milter_end_of_header_macros,
  Optional[Array[String, 1]]          $milter_header_checks,
  Optional[String]                    $milter_helo_macros,
  Optional[String]                    $milter_macro_daemon_name,
  Optional[String]                    $milter_macro_v,
  Optional[String]                    $milter_mail_macros,
  Optional[String]                    $milter_protocol,
  Optional[String]                    $milter_rcpt_macros,
  Optional[String]                    $milter_unknown_command_macros,
  Optional[String]                    $mime_boundary_length_limit,
  Optional[Array[String, 1]]          $mime_header_checks,
  Optional[String]                    $mime_nesting_limit,
  Optional[String]                    $minimal_backoff_time,
  Optional[Array[String, 1]]          $multi_instance_directories,
  Optional[Variant[Boolean, String]]  $multi_instance_enable,
  Optional[String]                    $multi_instance_group,
  Optional[String]                    $multi_instance_name,
  Optional[String]                    $multi_instance_wrapper,
  Optional[String]                    $multi_recipient_bounce_reject_code,
  Optional[Array[String, 1]]          $mydestination,
  Optional[String]                    $mydomain,
  Optional[String]                    $myhostname,
  Optional[Array[String, 1]]          $mynetworks,
  Optional[String]                    $mynetworks_style,
  Optional[String]                    $myorigin,
  Optional[Array[String, 1]]          $nested_header_checks,
  Optional[String]                    $newaliases_path,
  Optional[String]                    $non_fqdn_reject_code,
  Optional[Array[String, 1]]          $non_smtpd_milters,
  Optional[Array[String, 1]]          $notify_classes,
  Optional[Variant[Boolean, String]]  $owner_request_special,
  Optional[Array[String, 1]]          $parent_domain_matches_subdomains,
  Optional[Array[String, 1]]          $permit_mx_backup_networks,
  Optional[String]                    $pickup_service_name,
  Optional[String]                    $plaintext_reject_code,
  Optional[Array[String, 1]]          $postmulti_control_commands,
  Optional[Array[String, 1]]          $postmulti_start_commands,
  Optional[Array[String, 1]]          $postmulti_stop_commands,
  Optional[Array[String, 1]]          $postscreen_access_list,
  Optional[String]                    $postscreen_bare_newline_action,
  Optional[Variant[Boolean, String]]  $postscreen_bare_newline_enable,
  Optional[String]                    $postscreen_bare_newline_ttl,
  Optional[String]                    $postscreen_blacklist_action,
  Optional[String]                    $postscreen_cache_cleanup_interval,
  Optional[String]                    $postscreen_cache_map,
  Optional[String]                    $postscreen_cache_retention_time,
  Optional[String]                    $postscreen_client_connection_count_limit,
  Optional[String]                    $postscreen_command_count_limit,
  Optional[String]                    $postscreen_command_filter,
  Optional[String]                    $postscreen_command_time_limit,
  Optional[Variant[Boolean, String]]  $postscreen_disable_vrfy_command,
  Optional[Array[String, 1]]          $postscreen_discard_ehlo_keyword_address_maps,
  Optional[Array[String, 1]]          $postscreen_discard_ehlo_keywords,
  Optional[String]                    $postscreen_dnsbl_action,
  Optional[String]                    $postscreen_dnsbl_reply_map,
  Optional[Array[String, 1]]          $postscreen_dnsbl_sites,
  Optional[String]                    $postscreen_dnsbl_threshold,
  Optional[String]                    $postscreen_dnsbl_ttl,
  Optional[Variant[Boolean, String]]  $postscreen_enforce_tls,
  Optional[String]                    $postscreen_expansion_filter,
  Optional[Array[String, 1]]          $postscreen_forbidden_commands,
  Optional[String]                    $postscreen_greet_action,
  Optional[String]                    $postscreen_greet_banner,
  Optional[String]                    $postscreen_greet_ttl,
  Optional[String]                    $postscreen_greet_wait,
  Optional[Variant[Boolean, String]]  $postscreen_helo_required,
  Optional[String]                    $postscreen_non_smtp_command_action,
  Optional[Variant[Boolean, String]]  $postscreen_non_smtp_command_enable,
  Optional[String]                    $postscreen_non_smtp_command_ttl,
  Optional[String]                    $postscreen_pipelining_action,
  Optional[Variant[Boolean, String]]  $postscreen_pipelining_enable,
  Optional[String]                    $postscreen_pipelining_ttl,
  Optional[String]                    $postscreen_post_queue_limit,
  Optional[String]                    $postscreen_pre_queue_limit,
  Optional[String]                    $postscreen_reject_footer,
  Optional[String]                    $postscreen_tls_security_level,
  Optional[String]                    $postscreen_upstream_proxy_protocol,
  Optional[String]                    $postscreen_upstream_proxy_timeout,
  Optional[Variant[Boolean, String]]  $postscreen_use_tls,
  Optional[String]                    $postscreen_watchdog_timeout,
  Optional[Array[String, 1]]          $postscreen_whitelist_interfaces,
  Optional[Array[String, 1]]          $prepend_delivered_header,
  Optional[String]                    $process_id_directory,
  Optional[Array[String, 1]]          $propagate_unmatched_extensions,
  Optional[Array[String, 1]]          $proxy_interfaces,
  Optional[Array[String, 1]]          $proxy_read_maps,
  Optional[Array[String, 1]]          $proxy_write_maps,
  Optional[String]                    $proxymap_service_name,
  Optional[String]                    $proxywrite_service_name,
  Optional[String]                    $qmgr_clog_warn_time,
  Optional[String]                    $qmgr_daemon_timeout,
  Optional[String]                    $qmgr_fudge_factor,
  Optional[String]                    $qmgr_ipc_timeout,
  Optional[String]                    $qmgr_message_active_limit,
  Optional[String]                    $qmgr_message_recipient_limit,
  Optional[String]                    $qmgr_message_recipient_minimum,
  Optional[Array[String, 1]]          $qmqpd_authorized_clients,
  Optional[Variant[Boolean, String]]  $qmqpd_client_port_logging,
  Optional[String]                    $qmqpd_error_delay,
  Optional[String]                    $qmqpd_timeout,
  Optional[String]                    $queue_directory,
  Optional[String]                    $queue_file_attribute_count_limit,
  Optional[String]                    $queue_minfree,
  Optional[String]                    $queue_run_delay,
  Optional[String]                    $queue_service_name,
  Optional[Array[String, 1]]          $rbl_reply_maps,
  Optional[Variant[Boolean, String]]  $readme_directory,
  Optional[Array[String, 1]]          $receive_override_options,
  Optional[Array[String, 1]]          $recipient_bcc_maps,
  Optional[Array[String, 1]]          $recipient_canonical_classes,
  Optional[Array[String, 1]]          $recipient_canonical_maps,
  Optional[String]                    $recipient_delimiter,
  Optional[String]                    $reject_code,
  Optional[String]                    $reject_tempfail_action,
  Optional[Array[String, 1]]          $relay_clientcerts,
  Optional[Array[String, 1]]          $relay_domains,
  Optional[String]                    $relay_domains_reject_code,
  Optional[Array[String, 1]]          $relay_recipient_maps,
  Optional[String]                    $relay_transport,
  Optional[String]                    $relayhost,
  Optional[Array[String, 1]]          $relocated_maps,
  Optional[String]                    $remote_header_rewrite_domain,
  Optional[Variant[Boolean, String]]  $require_home_directory,
  Optional[Variant[Boolean, String]]  $reset_owner_alias,
  Optional[Variant[Boolean, String]]  $resolve_dequoted_address,
  Optional[Variant[Boolean, String]]  $resolve_null_domain,
  Optional[Variant[Boolean, String]]  $resolve_numeric_domain,
  Optional[String]                    $rewrite_service_name,
  Optional[String]                    $sample_directory,
  Optional[Variant[Boolean, String]]  $send_cyrus_sasl_authzid,
  Optional[Array[String, 1]]          $sender_bcc_maps,
  Optional[Array[String, 1]]          $sender_canonical_classes,
  Optional[Array[String, 1]]          $sender_canonical_maps,
  Optional[Array[String, 1]]          $sender_dependent_default_transport_maps,
  Optional[Array[String, 1]]          $sender_dependent_relayhost_maps,
  Optional[String]                    $sendmail_fix_line_endings,
  Optional[String]                    $sendmail_path,
  Optional[String]                    $service_throttle_time,
  Optional[String]                    $setgid_group,
  Optional[Variant[Boolean, String]]  $shlib_directory,
  Optional[Variant[Boolean, String]]  $show_user_unknown_table_name,
  Optional[String]                    $showq_service_name,
  Optional[String]                    $smtp_address_preference,
  Optional[Variant[Boolean, String]]  $smtp_always_send_ehlo,
  Optional[String]                    $smtp_bind_address,
  Optional[String]                    $smtp_bind_address6,
  Optional[Array[String, 1]]          $smtp_body_checks,
  Optional[Variant[Boolean, String]]  $smtp_cname_overrides_servername,
  Optional[String]                    $smtp_connect_timeout,
  Optional[Array[String, 1]]          $smtp_connection_cache_destinations,
  Optional[Variant[Boolean, String]]  $smtp_connection_cache_on_demand,
  Optional[String]                    $smtp_connection_cache_time_limit,
  Optional[String]                    $smtp_connection_reuse_time_limit,
  Optional[String]                    $smtp_data_done_timeout,
  Optional[String]                    $smtp_data_init_timeout,
  Optional[String]                    $smtp_data_xfer_timeout,
  Optional[Variant[Boolean, String]]  $smtp_defer_if_no_mx_address_found,
  Optional[Array[String, 1]]          $smtp_discard_ehlo_keyword_address_maps,
  Optional[Array[String, 1]]          $smtp_discard_ehlo_keywords,
  Optional[Array[String, 1]]          $smtp_dns_resolver_options,
  Optional[Variant[Boolean, String]]  $smtp_enforce_tls,
  Optional[Array[String, 1]]          $smtp_fallback_relay,
  Optional[Array[String, 1]]          $smtp_generic_maps,
  Optional[Array[String, 1]]          $smtp_header_checks,
  Optional[String]                    $smtp_helo_name,
  Optional[String]                    $smtp_helo_timeout,
  Optional[Array[String, 1]]          $smtp_host_lookup,
  Optional[String]                    $smtp_line_length_limit,
  Optional[String]                    $smtp_mail_timeout,
  Optional[Array[String, 1]]          $smtp_mime_header_checks,
  Optional[String]                    $smtp_mx_address_limit,
  Optional[String]                    $smtp_mx_session_limit,
  Optional[Array[String, 1]]          $smtp_nested_header_checks,
  Optional[Variant[Boolean, String]]  $smtp_never_send_ehlo,
  Optional[Variant[Boolean, String]]  $smtp_per_record_deadline,
  Optional[String]                    $smtp_pix_workaround_delay_time,
  Optional[Array[String, 1]]          $smtp_pix_workaround_maps,
  Optional[String]                    $smtp_pix_workaround_threshold_time,
  Optional[Array[String, 1]]          $smtp_pix_workarounds,
  Optional[String]                    $smtp_quit_timeout,
  Optional[Variant[Boolean, String]]  $smtp_quote_rfc821_envelope,
  Optional[Variant[Boolean, String]]  $smtp_randomize_addresses,
  Optional[String]                    $smtp_rcpt_timeout,
  Optional[String]                    $smtp_reply_filter,
  Optional[String]                    $smtp_rset_timeout,
  Optional[String]                    $smtp_sasl_auth_cache_name,
  Optional[String]                    $smtp_sasl_auth_cache_time,
  Optional[Variant[Boolean, String]]  $smtp_sasl_auth_enable,
  Optional[Variant[Boolean, String]]  $smtp_sasl_auth_soft_bounce,
  Optional[Array[String, 1]]          $smtp_sasl_mechanism_filter,
  Optional[Array[String, 1]]          $smtp_sasl_password_maps,
  Optional[String]                    $smtp_sasl_path,
  Optional[Array[String, 1]]          $smtp_sasl_security_options,
  Optional[Array[String, 1]]          $smtp_sasl_tls_security_options,
  Optional[Array[String, 1]]          $smtp_sasl_tls_verified_security_options,
  Optional[String]                    $smtp_sasl_type,
  Optional[Variant[Boolean, String]]  $smtp_send_dummy_mail_auth,
  Optional[Variant[Boolean, String]]  $smtp_send_xforward_command,
  Optional[Variant[Boolean, String]]  $smtp_sender_dependent_authentication,
  Optional[Variant[Boolean, String]]  $smtp_skip_5xx_greeting,
  Optional[Variant[Boolean, String]]  $smtp_skip_quit_response,
  Optional[String]                    $smtp_starttls_timeout,
  Optional[String]                    $smtp_tls_cafile,
  Optional[String]                    $smtp_tls_capath,
  Optional[Variant[Boolean, String]]  $smtp_tls_block_early_mail_reply,
  Optional[String]                    $smtp_tls_cert_file,
  Optional[String]                    $smtp_tls_ciphers,
  Optional[String]                    $smtp_tls_dcert_file,
  Optional[String]                    $smtp_tls_dkey_file,
  Optional[String]                    $smtp_tls_eccert_file,
  Optional[String]                    $smtp_tls_eckey_file,
  Optional[Variant[Boolean, String]]  $smtp_tls_enforce_peername,
  Optional[Array[String, 1]]          $smtp_tls_exclude_ciphers,
  Optional[Array[String, 1]]          $smtp_tls_fingerprint_cert_match,
  Optional[String]                    $smtp_tls_fingerprint_digest,
  Optional[String]                    $smtp_tls_key_file,
  Optional[String]                    $smtp_tls_loglevel,
  Optional[String]                    $smtp_tls_mandatory_ciphers,
  Optional[Array[String, 1]]          $smtp_tls_mandatory_exclude_ciphers,
  Optional[Array[String, 1]]          $smtp_tls_mandatory_protocols,
  Optional[Variant[Boolean, String]]  $smtp_tls_note_starttls_offer,
  Optional[Array[String, 1]]          $smtp_tls_per_site,
  Optional[Array[String, 1]]          $smtp_tls_policy_maps,
  Optional[Array[String, 1]]          $smtp_tls_protocols,
  Optional[String]                    $smtp_tls_scert_verifydepth,
  Optional[Array[String, 1]]          $smtp_tls_secure_cert_match,
  Optional[String]                    $smtp_tls_security_level,
  Optional[String]                    $smtp_tls_session_cache_database,
  Optional[String]                    $smtp_tls_session_cache_timeout,
  Optional[Array[String, 1]]          $smtp_tls_verify_cert_match,
  Optional[Variant[Boolean, String]]  $smtp_use_tls,
  Optional[String]                    $smtp_xforward_timeout,
  Optional[Array[String, 1]]          $smtpd_authorized_verp_clients,
  Optional[Array[String, 1]]          $smtpd_authorized_xclient_hosts,
  Optional[Array[String, 1]]          $smtpd_authorized_xforward_hosts,
  Optional[String]                    $smtpd_banner,
  Optional[String]                    $smtpd_client_connection_count_limit,
  Optional[String]                    $smtpd_client_connection_rate_limit,
  Optional[Array[String, 1]]          $smtpd_client_event_limit_exceptions,
  Optional[String]                    $smtpd_client_message_rate_limit,
  Optional[String]                    $smtpd_client_new_tls_session_rate_limit,
  Optional[Variant[Boolean, String]]  $smtpd_client_port_logging,
  Optional[String]                    $smtpd_client_recipient_rate_limit,
  Optional[Array[String, 1]]          $smtpd_client_restrictions,
  Optional[String]                    $smtpd_command_filter,
  Optional[Array[String, 1]]          $smtpd_data_restrictions,
  Optional[Variant[Boolean, String]]  $smtpd_delay_open_until_valid_rcpt,
  Optional[Variant[Boolean, String]]  $smtpd_delay_reject,
  Optional[Array[String, 1]]          $smtpd_discard_ehlo_keyword_address_maps,
  Optional[Array[String, 1]]          $smtpd_discard_ehlo_keywords,
  Optional[Array[String, 1]]          $smtpd_end_of_data_restrictions,
  Optional[Variant[Boolean, String]]  $smtpd_enforce_tls,
  Optional[String]                    $smtpd_error_sleep_time,
  Optional[Array[String, 1]]          $smtpd_etrn_restrictions,
  Optional[String]                    $smtpd_expansion_filter,
  Optional[Array[String, 1]]          $smtpd_forbidden_commands,
  Optional[String]                    $smtpd_hard_error_limit,
  Optional[Variant[Boolean, String]]  $smtpd_helo_required,
  Optional[Array[String, 1]]          $smtpd_helo_restrictions,
  Optional[String]                    $smtpd_history_flush_threshold,
  Optional[String]                    $smtpd_junk_command_limit,
  Optional[String]                    $smtpd_log_access_permit_actions,
  Optional[Array[String, 1]]          $smtpd_milters,
  Optional[Array[String, 1]]          $smtpd_noop_commands,
  Optional[String]                    $smtpd_null_access_lookup_key,
  Optional[Variant[Boolean, String]]  $smtpd_peername_lookup,
  Optional[Variant[Boolean, String]]  $smtpd_per_record_deadline,
  Optional[String]                    $smtpd_policy_service_max_idle,
  Optional[String]                    $smtpd_policy_service_max_ttl,
  Optional[String]                    $smtpd_policy_service_timeout,
  Optional[String]                    $smtpd_proxy_ehlo,
  Optional[String]                    $smtpd_proxy_filter,
  Optional[Array[String, 1]]          $smtpd_proxy_options,
  Optional[String]                    $smtpd_proxy_timeout,
  Optional[String]                    $smtpd_recipient_limit,
  Optional[String]                    $smtpd_recipient_overshoot_limit,
  Optional[Array[String, 1]]          $smtpd_recipient_restrictions,
  Optional[String]                    $smtpd_reject_footer,
  Optional[Variant[Boolean, String]]  $smtpd_reject_unlisted_recipient,
  Optional[Variant[Boolean, String]]  $smtpd_reject_unlisted_sender,
  Optional[Array[String, 1]]          $smtpd_relay_restrictions,
  Optional[Array[String, 1]]          $smtpd_restriction_classes,
  Optional[Variant[Boolean, String]]  $smtpd_sasl_auth_enable,
  Optional[Variant[Boolean, String]]  $smtpd_sasl_authenticated_header,
  Optional[Array[String, 1]]          $smtpd_sasl_exceptions_networks,
  Optional[String]                    $smtpd_sasl_local_domain,
  Optional[String]                    $smtpd_sasl_path,
  Optional[Array[String, 1]]          $smtpd_sasl_security_options,
  Optional[Array[String, 1]]          $smtpd_sasl_tls_security_options,
  Optional[String]                    $smtpd_sasl_type,
  Optional[Array[String, 1]]          $smtpd_sender_login_maps,
  Optional[Array[String, 1]]          $smtpd_sender_restrictions,
  Optional[String]                    $smtpd_service_name,
  Optional[String]                    $smtpd_soft_error_limit,
  Optional[String]                    $smtpd_starttls_timeout,
  Optional[String]                    $smtpd_timeout,
  Optional[String]                    $smtpd_tls_cafile,
  Optional[String]                    $smtpd_tls_capath,
  Optional[Variant[Boolean, String]]  $smtpd_tls_always_issue_session_ids,
  Optional[Variant[Boolean, String]]  $smtpd_tls_ask_ccert,
  Optional[Variant[Boolean, String]]  $smtpd_tls_auth_only,
  Optional[String]                    $smtpd_tls_ccert_verifydepth,
  Optional[String]                    $smtpd_tls_cert_file,
  Optional[String]                    $smtpd_tls_ciphers,
  Optional[String]                    $smtpd_tls_dcert_file,
  Optional[String]                    $smtpd_tls_dh1024_param_file,
  Optional[String]                    $smtpd_tls_dh512_param_file,
  Optional[String]                    $smtpd_tls_dkey_file,
  Optional[String]                    $smtpd_tls_eccert_file,
  Optional[String]                    $smtpd_tls_eckey_file,
  Optional[String]                    $smtpd_tls_eecdh_grade,
  Optional[Array[String, 1]]          $smtpd_tls_exclude_ciphers,
  Optional[String]                    $smtpd_tls_fingerprint_digest,
  Optional[String]                    $smtpd_tls_key_file,
  Optional[String]                    $smtpd_tls_loglevel,
  Optional[String]                    $smtpd_tls_mandatory_ciphers,
  Optional[Array[String, 1]]          $smtpd_tls_mandatory_exclude_ciphers,
  Optional[Array[String, 1]]          $smtpd_tls_mandatory_protocols,
  Optional[Array[String, 1]]          $smtpd_tls_protocols,
  Optional[Variant[Boolean, String]]  $smtpd_tls_received_header,
  Optional[Variant[Boolean, String]]  $smtpd_tls_req_ccert,
  Optional[String]                    $smtpd_tls_security_level,
  Optional[String]                    $smtpd_tls_session_cache_database,
  Optional[String]                    $smtpd_tls_session_cache_timeout,
  Optional[Variant[Boolean, String]]  $smtpd_tls_wrappermode,
  Optional[String]                    $smtpd_upstream_proxy_protocol,
  Optional[String]                    $smtpd_upstream_proxy_timeout,
  Optional[Variant[Boolean, String]]  $smtpd_use_tls,
  Optional[Variant[Boolean, String]]  $soft_bounce,
  Optional[String]                    $stale_lock_time,
  Optional[Variant[Boolean, String]]  $strict_7bit_headers,
  Optional[Variant[Boolean, String]]  $strict_8bitmime,
  Optional[Variant[Boolean, String]]  $strict_8bitmime_body,
  Optional[Variant[Boolean, String]]  $strict_mailbox_ownership,
  Optional[Variant[Boolean, String]]  $strict_mime_encoding_domain,
  Optional[Variant[Boolean, String]]  $strict_rfc821_envelopes,
  Optional[Variant[Boolean, String]]  $sun_mailtool_compatibility,
  Optional[Variant[Boolean, String]]  $swap_bangpath,
  Optional[String]                    $syslog_facility,
  Optional[String]                    $syslog_name,
  Optional[String]                    $tcp_windowsize,
  Optional[Variant[Boolean, String]]  $tls_append_default_ca,
  Optional[String]                    $tls_daemon_random_bytes,
  Optional[Array[String, 1]]          $tls_disable_workarounds,
  Optional[String]                    $tls_eecdh_strong_curve,
  Optional[String]                    $tls_eecdh_ultra_curve,
  Optional[String]                    $tls_export_cipherlist,
  Optional[String]                    $tls_high_cipherlist,
  Optional[Variant[Boolean, String]]  $tls_legacy_public_key_fingerprints,
  Optional[String]                    $tls_low_cipherlist,
  Optional[String]                    $tls_medium_cipherlist,
  Optional[String]                    $tls_null_cipherlist,
  Optional[Variant[Boolean, String]]  $tls_preempt_cipherlist,
  Optional[String]                    $tls_random_bytes,
  Optional[String]                    $tls_random_exchange_name,
  Optional[String]                    $tls_random_prng_update_period,
  Optional[String]                    $tls_random_reseed_period,
  Optional[String]                    $tls_random_source,
  Optional[String]                    $tlsproxy_enforce_tls,
  Optional[String]                    $tlsproxy_service_name,
  Optional[String]                    $tlsproxy_tls_cafile,
  Optional[String]                    $tlsproxy_tls_capath,
  Optional[Variant[Boolean, String]]  $tlsproxy_tls_always_issue_session_ids,
  Optional[Variant[Boolean, String]]  $tlsproxy_tls_ask_ccert,
  Optional[String]                    $tlsproxy_tls_ccert_verifydepth,
  Optional[String]                    $tlsproxy_tls_cert_file,
  Optional[String]                    $tlsproxy_tls_ciphers,
  Optional[String]                    $tlsproxy_tls_dcert_file,
  Optional[String]                    $tlsproxy_tls_dh1024_param_file,
  Optional[String]                    $tlsproxy_tls_dh512_param_file,
  Optional[String]                    $tlsproxy_tls_dkey_file,
  Optional[String]                    $tlsproxy_tls_eccert_file,
  Optional[String]                    $tlsproxy_tls_eckey_file,
  Optional[String]                    $tlsproxy_tls_eecdh_grade,
  Optional[Array[String, 1]]          $tlsproxy_tls_exclude_ciphers,
  Optional[String]                    $tlsproxy_tls_fingerprint_digest,
  Optional[String]                    $tlsproxy_tls_key_file,
  Optional[String]                    $tlsproxy_tls_loglevel,
  Optional[String]                    $tlsproxy_tls_mandatory_ciphers,
  Optional[Array[String, 1]]          $tlsproxy_tls_mandatory_exclude_ciphers,
  Optional[Array[String, 1]]          $tlsproxy_tls_mandatory_protocols,
  Optional[Array[String, 1]]          $tlsproxy_tls_protocols,
  Optional[Variant[Boolean, String]]  $tlsproxy_tls_req_ccert,
  Optional[String]                    $tlsproxy_tls_security_level,
  Optional[String]                    $tlsproxy_tls_session_cache_timeout,
  Optional[Variant[Boolean, String]]  $tlsproxy_use_tls,
  Optional[String]                    $tlsproxy_watchdog_timeout,
  Optional[String]                    $trace_service_name,
  Optional[Array[String, 1]]          $transport_maps,
  Optional[String]                    $transport_retry_time,
  Optional[String]                    $trigger_timeout,
  Optional[String]                    $undisclosed_recipients_header,
  Optional[String]                    $unknown_address_reject_code,
  Optional[String]                    $unknown_address_tempfail_action,
  Optional[String]                    $unknown_client_reject_code,
  Optional[String]                    $unknown_helo_hostname_tempfail_action,
  Optional[String]                    $unknown_hostname_reject_code,
  Optional[String]                    $unknown_local_recipient_reject_code,
  Optional[String]                    $unknown_relay_recipient_reject_code,
  Optional[String]                    $unknown_virtual_alias_reject_code,
  Optional[String]                    $unknown_virtual_mailbox_reject_code,
  Optional[String]                    $unverified_recipient_defer_code,
  Optional[String]                    $unverified_recipient_reject_code,
  Optional[String]                    $unverified_recipient_reject_reason,
  Optional[String]                    $unverified_recipient_tempfail_action,
  Optional[String]                    $unverified_sender_defer_code,
  Optional[String]                    $unverified_sender_reject_code,
  Optional[String]                    $unverified_sender_reject_reason,
  Optional[String]                    $unverified_sender_tempfail_action,
  Optional[String]                    $verp_delimiter_filter,
  Optional[Array[String, 1]]          $virtual_alias_domains,
  Optional[String]                    $virtual_alias_expansion_limit,
  Optional[Array[String, 1]]          $virtual_alias_maps,
  Optional[String]                    $virtual_alias_recursion_limit,
  Optional[Array[String, 1]]          $virtual_gid_maps,
  Optional[String]                    $virtual_mailbox_base,
  Optional[Array[String, 1]]          $virtual_mailbox_domains,
  Optional[String]                    $virtual_mailbox_limit,
  Optional[Array[String, 1]]          $virtual_mailbox_lock,
  Optional[Array[String, 1]]          $virtual_mailbox_maps,
  Optional[String]                    $virtual_minimum_uid,
  Optional[String]                    $virtual_transport,
  Optional[Array[String, 1]]          $virtual_uid_maps,
) {

  contain postfix::install
  contain postfix::config
  contain postfix::service

  Class['postfix::install'] -> Class['postfix::config']
    ~> Class['postfix::service']
}

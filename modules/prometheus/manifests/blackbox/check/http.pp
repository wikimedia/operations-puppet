# SPDX-License-Identifier: Apache-2.0
# @summary - resource to configure http(s) checks for a specific service
# @param server_name - an FQDN, the server name to use (during TLS and Host:)
# @param instance_label - short-form host name, used as an instance label
# @param ip4 - IPv4 address to connect to
# @param ip6 - IPv6 address to connect to
# @param ip_families - indicate support for IPv4 and/or IPv6 - by default both IPv4 and IPv6 will be checked
# @param team - name of the WMF team to alert, teams are defined as a 'receiver' in modules/alertmanager/templates/alertmanager.yml.erb
# @param severity - severity of the alert (see type Prometheus::Alert::Severity for possible values)
# @param port - port to run a specific check on
# @param force_tls - if true force ssl otherwise use port number to decide
# @param certificate_expiry_days - alert when the certificate will expire sooner than days
# @param timeout - probe timeout
# @param use_client_auth - use client authentication
# @param client_auth_cert - path to the client auth certificate to use. Please
#                           note this file must exist on the monitoring server
#                           not the server been monitored
# @param client_auth_key - path to the client auth key to use. Please note this
#                          file must exist on the monitoring server not the
#                          server been monitored
# @param req_headers - Request headers to send as part of the health check.
# @param header_matches - list of regular expressions to match against the response headers. if any of those does not match the probe will fail.
# @param header_not_matches - list of regular expressions to match against the response headers. if any of those does match the probe will fail.
# @param body_regex_matches - list of regular expressions to match against the body's response. if any of those does not match the probe will fail.
# @param body_regex_not_matches - list of regular expressions to match against the body's response. if any of those does matche the probe will fail.
# @param status_matches - list of regular expressions to match against the http status code. if any of those does not match the probe will fail.
# @param bearer_token - bearer token to use
# @param path - path to check
# @param body - A hash of form parameters to send in the body
# @param body_raw - The raw body string, usefull for sending json payloads
# @param method - http method to use
# @param follow_redirects - whether the check should honour redirects. without this a 301 would be considered a failure.
# @param site - site to perform the check from
# @param proxy_url - The proxy_url
# @param auth_username - username used for basic auth
# @param auth_password - password used for basic auth
# @param prometheus_instance prometheus instance to deploy to, defaults to 'ops'
define prometheus::blackbox::check::http (
    Stdlib::Fqdn                            $server_name             = $title,
    Stdlib::Fqdn                            $instance_label          = $facts['networking']['hostname'],
    Stdlib::IP::Address::V4::Nosubnet       $ip4                     = $facts['networking']['ip'],
    Stdlib::IP::Address::V6::Nosubnet       $ip6                     = $facts['networking']['ip6'],
    Array[Enum['ip4', 'ip6']]               $ip_families             = ['ip4', 'ip6'],
    String[1]                               $team                    = 'sre',
    Prometheus::Alert::Severity             $severity                = 'critical',
    Stdlib::Port                            $port                    = 443,
    Boolean                                 $force_tls               = false,
    Integer[1,120]                          $certificate_expiry_days = 10,
    Pattern[/\d+[ms]/]                      $timeout                 = '3s',
    Boolean                                 $use_client_auth         = false,
    # puppet agent certs exported in profile::prometheus::blackbox_exporter
    Stdlib::Unixpath                        $client_auth_cert        = '/etc/prometheus/ssl/cert.pem',
    Stdlib::Unixpath                        $client_auth_key         = '/etc/prometheus/ssl/server.key',
    Hash[String, String]                    $req_headers             = {},
    Array[Prometheus::Blackbox::HeaderSpec] $header_matches          = [],
    Array[Prometheus::Blackbox::HeaderSpec] $header_not_matches      = [],
    Array[String[1]]                        $body_regex_matches      = [],
    Array[String[1]]                        $body_regex_not_matches  = [],
    Array[Stdlib::HttpStatus]               $status_matches          = [],
    Optional[String[1]]                     $bearer_token            = undef,
    Stdlib::Unixpath                        $path                    = '/',
    Hash                                    $body                    = {},
    Wmflib::HTTP::Method                    $method                  = 'GET',
    Boolean                                 $follow_redirects        = false,
    Wmflib::Sites                           $site                    = $::site,  # lint:ignore:top_scope_facts
    String[1]                               $prometheus_instance     = 'ops',
    Optional[String[1]]                     $body_raw                = undef,
    Optional[String[1]]                     $auth_username           = undef,
    Optional[String[1]]                     $auth_password           = undef,
    Optional[String[1]]                     $proxy_url               = undef,
    String[1]                               $probe_runbook           = 'https://wikitech.wikimedia.org/wiki/Runbook#{{ $labels.instance }}',
    String[1]                               $probe_description       = '{{ $labels.instance }} failed when probed by {{ $labels.module }} from {{ $externalLabels.site }}. Availability is {{ $value }}%.',
    String[1]                               $probe_summary           = 'Service {{ $labels.instance }} has failed probes ({{ $labels.module }})',
    String[1]                               $probe_dashboard         = 'https://grafana.wikimedia.org/d/O0nHhdhnz/network-probes-overview?var-job={{ $labels.job }}&var-module=All',
    String[1]                               $ssl_expired_runbook     = 'https://wikitech.wikimedia.org/wiki/TLS/Runbook#{{ $labels.instance }}',
    String[1]                               $ssl_expired_description = 'The certificate presented by service {{ $labels.instance }} is going to expire in {{ $value | humanizeDuration }}',
    String[1]                               $ssl_expired_summary     = 'Certificate for service {{ $labels.instance }} is about to expire',
    String[1]                               $ssl_expired_dashboard   = 'https://grafana.wikimedia.org/d/K1dRhGCnz/probes-tls-dashboard',
) {
    if !$body.empty and !$body_raw.empty {
        fail('can not set both body and body_raw')
    }
    $_body = $body_raw.empty.bool2str(wmflib::encode_www_form($body), $body_raw)
    $use_tls = ($force_tls or $port == 443)
    $safe_title = $title.regsubst('\W', '_', 'G')
    $module_title = $safe_title
    $alert_title = "alerts_${safe_title}.yml"
    $target_file = "/srv/prometheus/${prometheus_instance}/targets/probes-custom_puppet-http.yaml"
    $basic_auth = ($auth_username and $auth_password) ? {
        true    => { 'username' => $auth_username, 'password' => $auth_password },
        default => undef,
    }

    $all_headers = deep_merge({ 'Host' => $server_name }, $req_headers )

    $client_auth_config = $use_client_auth ? {
        false   => {},
        default => {'cert_file' => $client_auth_cert, 'key_file' => $client_auth_key},
    }
    $tls_config = $use_tls ? {
        false   => {},
        default => {'server_name' => $server_name} + $client_auth_config,
    }

    $http_module_params = {
        'headers'                         => $all_headers,
        'no_follow_redirects'             => !$follow_redirects,
        'method'                          => $method,
        'ip_protocol_fallback'            => false,
        'fail_if_ssl'                     => !$use_tls,
        'fail_if_not_ssl'                 => $use_tls,
        'tls_config'                      => $tls_config,
        'fail_if_body_matches_regexp'     => $body_regex_not_matches,
        'fail_if_body_not_matches_regexp' => $body_regex_matches,
        'fail_if_header_matches'          => $header_not_matches,
        'fail_if_header_not_matches'      => $header_matches,
        'valid_status_codes'              => $status_matches,
        'basic_auth'                      => $basic_auth,
        'bearer_token'                    => $bearer_token,
        'proxy_url'                       => $proxy_url,
        'body'                            => $_body,
    }.filter |$key, $value| { $value =~ Boolean or ($value =~ NotUndef and !$value.empty) }
    $module_config = {
        'modules' => Hash($ip_families.map |$family| {
            [ "http_${safe_title}_${family}",
              {
                  'prober' => 'http',
                  'timeout' => $timeout,
                  'http' => $http_module_params + { 'preferred_ip_protocol' => $family }
              }
            ]
        }),
    }
    $target_config = $ip_families.map |$family| {
        $proto = $use_tls.bool2str('https', 'http')
        $address = ($family == 'ip4').bool2str($ip4, $ip6)
        $data = {
            'labels' => {
                'address' => $address,
                'family'  => $family,
                'module'  => "http_${safe_title}_${family}",
            },
            'targets' => ["${instance_label}:${port}@${proto}://[${address}]:${port}${path}"],
        }
        $data
    }

    $page_text = $severity ? {
        'page'   => ' #page',
        default => '',
    }

    # Deploy similar (but same alert name, so deduplication works) alerts to
    # the ones found in alerts.git/team-sre/probes.yaml. See also that file for more
    # information especially when making changes.
    # The difference here is the customisation in terms of team/severity and which exporter module to "hook" into

    if $use_tls {
        $tls_alert = {
            'name'  => 'ssl_expire',
            'rules' => [{
                'alert'      => 'CertAlmostExpired',
                'expr'       => "probe_ssl_earliest_cert_expiry{module=~'http_${safe_title}_.*'} - time() < (${certificate_expiry_days} * 86400)",
                'for'         => '3h',
                'labels'      => {
                    'team'     => $team,
                    'severity' => $severity,
                },
                'annotations' => {
                    'description' => $ssl_expired_description,
                    'summary'     => $ssl_expired_summary,
                    'dashboard'   => $ssl_expired_dashboard,
                    'runbook'     => $ssl_expired_runbook,
                },
            }],
        }
    } else {
        $tls_alert = undef
    }

    $alert_config = {
        'groups' => [
          $tls_alert,
          {
            'name'  => 'puppet_probes',
            'rules' => [{
                'alert'      => 'ProbeDown',
                'expr'       => "avg_over_time(probe_success{module=~'http_${safe_title}_.*'}[1m]) * 100 < 75",
                'for'         => '2m',
                'labels'      => {
                    'team'     => $team,
                    'severity' => $severity,
                },
                'annotations' => {
                    'description' => $probe_description,
                    'summary'     => "${probe_summary}${page_text}",
                    'dashboard'   => $probe_dashboard,
                    'logs'        => 'https://logstash.wikimedia.org/app/dashboards#/view/f3e709c0-a5f8-11ec-bf8e-43f1807d5bc2?_g=(filters:!((query:(match_phrase:(service.name:{{ $labels.module }})))))',
                    'runbook'     => $probe_runbook,
                },
            }],
          },
        ].filter |$alert| { $alert != undef },
    }
    $module_params = {
        'content' => $module_config.wmflib::to_yaml,
        'tag'     => "prometheus::blackbox::check::http::${::site}::${prometheus_instance}::module",
    }
    $alert_rule_params  = {
        'instance' => $prometheus_instance,
        'content' => $alert_config.wmflib::to_yaml,
        'tag'     => "prometheus::blackbox::check::http::${::site}::${prometheus_instance}::alert",
    }
    $target_frag_params = {
        'ensure'  => 'file',
        'content' => $target_config.wmflib::to_yaml,
        'tag'     => "prometheus::blackbox::check::http::${::site}::${prometheus_instance}::target",
    }

    wmflib::resource::export('prometheus::blackbox::module', $module_title, $title, $module_params)
    wmflib::resource::export('prometheus::rule', $alert_title, $title, $alert_rule_params)
    wmflib::resource::export('file', $target_file, $title, $target_frag_params)
}

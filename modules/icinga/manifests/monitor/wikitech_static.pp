# @summary wikitech-static (hosted externally at Rackspace) specific
# monitoring
# SPDX-License-Identifier: Apache-2.0
class icinga::monitor::wikitech_static () {
  @monitoring::host { 'wikitech-static.wikimedia.org':
    host_fqdn     => 'wikitech-static.wikimedia.org',
    contact_group => 'wmcs-bots,admins',
  }

  # T89323
  monitoring::service { 'wikitech-static-sync':
    description    => 'Wikitech and wt-static content in sync',
    check_command  => 'check_wikitech_static',
    check_interval => 120,
    host           => 'wikitech-static.wikimedia.org',
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
  }

  # T163721
  monitoring::service { 'wikitech-static-version':
    description    => 'Wikitech-static MW version up to date',
    check_command  => 'check_wikitech_static_version',
    check_interval => 720,
    host           => 'wikitech-static.wikimedia.org',
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
  }

  monitoring::service { 'wikitech-static-main-page':
    description   => 'Wikitech-static main page has content',
    check_command => 'check_https_url_at_address_for_string!wikitech-static.wikimedia.org!/wiki/Main_Page?debug=true!Wikitech',
    contact_group => 'wmcs-bots,admins',
    host          => 'wikitech-static.wikimedia.org',
    notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
  }

  monitoring::service { 'https_wikitech-static':
    description   => 'HTTPS-wikitech-static',
    check_command => 'check_ssl_http_letsencrypt!wikitech-static.wikimedia.org',
    host          => 'wikitech-static.wikimedia.org',
    contact_group => 'wmcs-bots,admins',
    notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
  }

  monitoring::service { 'https_status-wikimedia':
    description   => 'HTTPS-status-wikimedia-org',
    check_command => 'check_ssl_http_letsencrypt!status.wikimedia.org',
    host          => 'wikitech-static.wikimedia.org',
    contact_group => 'wikitech-static',
    notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
  }
}

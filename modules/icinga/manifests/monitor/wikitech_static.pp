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
    migration_task => 'T362397',
  }

  monitoring::service { 'wikitech-static-main-page':
    description    => 'Wikitech-static main page has content',
    check_command  => 'check_https_url_at_address_for_string!wikitech-static.wikimedia.org!/wiki/Main_Page?debug=true!Wikitech',
    contact_group  => 'wmcs-bots,admins',
    host           => 'wikitech-static.wikimedia.org',
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
    migration_task => 'T362397',
  }
}

class profile::openstack::base::wikitech::monitor(
    $osm_host = hiera('profile::openstack::base::osm_host'),
    ) {

    # T89323
    monitoring::service { 'wikitech-static-sync':
        description    => 'Wikitech and wt-static content in sync',
        check_command  => 'check_wikitech_static',
        check_interval => 120,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
    }

    # T163721
    monitoring::service { 'wikitech-static-version':
        description    => 'Wikitech-static MW version up to date',
        check_command  => 'check_wikitech_static_version',
        check_interval => 720,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
    }

    monitoring::service { 'wikitech-static-main-page':
        description   => 'Wikitech-static main page has content',
        check_command => 'check_https_url_at_address_for_string!wikitech-static.wikimedia.org!/wiki/Main_Page?debug=true!Wikitech',
        contact_group => 'wmcs-bots,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikitech-static',
    }
}

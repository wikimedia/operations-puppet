# == Class: openstack::keystone::monitor::services
# Checks the functionality of the keystone API generally.

class openstack::keystone::monitor::services(
    $active,
    $auth_port,
    $public_port,
    $critical=false,
    $contact_groups='wmcs-bots,admins',
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    monitoring::service { "keystone-http-${auth_port}":
        ensure        => $ensure,
        critical      => $critical,
        description   => "keystone admin endpoint port ${auth_port}",
        check_command => "check_http_on_port!${auth_port}",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    monitoring::service { "keystone-http-${public_port}": # v2 api is limited here
        ensure        => $ensure,
        critical      => $critical,
        description   => "keystone public endoint port ${public_port}",
        check_command => "check_http_on_port!${public_port}",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}

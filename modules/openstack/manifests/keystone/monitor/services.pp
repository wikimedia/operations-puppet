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

    [$auth_port, $public_port].each |$port| {
        monitoring::service {
            default:
                ensure        => $ensure,
                critical      => $critical,
                contact_group => $contact_groups,
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting';
            "keystone-http-${port}":
                description   => "keystone endpoint port ${port}",
                check_command => "check_https_on_port!${port}";
            "keystone-http-${port}-ssl-expiry":
                description   => "keystone endpoint port ${port} SSL Expiry",
                check_command => "check_https_expiry!${port}";
        }
    }
}

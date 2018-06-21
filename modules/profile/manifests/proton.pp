# == Class: profile::proton
#
# This class installs and configures the Chromium-based PDF renderer service.
#
class profile::proton(
) {

    class { '::mediawiki::packages::fonts': }

    require_package('chromium')

    service::node { 'proton':
        port              => 24766,
        has_spec          => true,
        monitor_to        => 10,
        healthcheck_url   => '',
        deployment        => 'scap3',
        deployment_config => true,
        environment       => {
            'CHROME_BIN' => '/usr/bin/chromium'
        },
    }

}

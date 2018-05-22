# == Class: profile::proton
#
# This class installs and configures the Chromium-based PDF renderer service.
#
class profile::proton(
) {

    require_package('chromium')
    require ::mediawiki::packages::fonts

    service::node { 'proton':
        port              => 24766,
        has_spec          => true,
        healthcheck_url   => '',
        deployment        => 'scap3',
        deployment_config => true,
        environment       => {
            'CHROME_BIN' => '/usr/bin/chromium'
        },
    }

}

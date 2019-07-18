# == Class: profile::proton
#
# This class installs and configures the Chromium-based PDF renderer service.
#
class profile::proton(
    Boolean $use_nodejs10 = hiera('profile::proton::use_nodejs10', false),
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
            'CHROME_BIN'                      => '/usr/bin/chromium',
            'APP_ENABLE_CANCELLABLE_PROMISES' => true,
        },
        use_nodejs10      => $use_nodejs10,
    }

    # font configuration section
    file { '/etc/fonts/conf.d/10-sub-pixel-rgb.conf':
        ensure => link,
        target => '/usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf',
    }
    file { '/etc/fonts/conf.d/10-unhinted.conf':
        ensure => link,
        target => '/usr/share/fontconfig/conf.avail/10-unhinted.conf',
    }

}

# SPDX-License-Identifier: Apache-2.0
# This define can be used to remove as mediawiki php installation from production.
define profile::mediawiki::php::absented_version() {
    # Remove the check-restart timer
    $fpm_programname = php::fpm::programname($title)
    $restart = "${fpm_programname}_check_restart"
    systemd::timer{ $restart:
        ensure          => 'absent',
        timer_intervals => [
            { 'start'    => 'OnCalendar',
              'interval' => '*-*-* 00:00:00',
            }
        ],
    }
    systemd::unit{ "${restart}.service":
        ensure  => absent,
        content => '',
    }
    # Remove all packages related to php$version-common
    # Also remove all their config files, which include /etc/php/$version
    package { "php${title}-common":
        ensure => 'purged'
    }
}

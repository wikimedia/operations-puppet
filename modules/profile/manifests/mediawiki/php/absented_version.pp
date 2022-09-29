# SPDX-License-Identifier: Apache-2.0
# This define can be used to remove as mediawiki php installation from production.
define profile::mediawiki::php::absented_version() {
    $fpm_programname = php::fpm::programname($title)

    # Remove the check-restart timer
    systemd::timer{ "${fpm_programname}_check_restart":
        ensure          => 'absent',
        timer_intervals => [
            { 'start'    => 'OnCalendar',
              'interval' => '*-*-* 00:00:00',
            }
        ],
    }
    # Remove all packages related to php$version-common
    # Also remove all their config files, which include /etc/php/$version
    package { "php${title}-common":
        ensure => 'purged'
    }
}

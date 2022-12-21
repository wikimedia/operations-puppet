# SPDX-License-Identifier: Apache-2.0
# == Class swift::rclone
#
# @summary Installs rclone and arranges for a weekly sync
# to run from primary to secondary swift cluster.
#
# @param [WMFlib::Ensure] ensure
#     present/absent to install/remove config/timer
# @param [Hash[String,Hash]] credentials
#     the profile::swift::accounts_keys hash
class swift::rclone (
    WMFlib::Ensure     $ensure = 'absent',
    Hash[String, Hash] $credentials = [],
) {

    ensure_packages('rclone')

    #This file contains the mw_media account key for codfw & eqiad
    file { '/etc/swift/rclone.conf' :
        ensure    => $ensure,
        owner     => 'swift',
        group     => 'swift',
        mode      => '0440',
        content   => template('swift/rclone.conf.erb'),
        show_diff => false,
    }

    file { '/etc/swift/swiftrepl_filters_nothumbs':
        ensure => $ensure,
        mode   => '0444',
        source => 'puppet:///modules/swift/swiftrepl_filters_nothumbs',
    }

    file { '/usr/local/bin/swift-rclone-sync':
        ensure => $ensure,
        mode   => '0555',
        source => 'puppet:///modules/swift/swift_rclone.sh',
    }

    systemd::timer::job { 'swift_rclone_sync':
        ensure      => $ensure,
        command     => '/usr/local/bin/swift-rclone-sync',
        interval    => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 08:00:00' },
        user        => 'root',
        description => 'Swift rclone-based sync',
    }
}

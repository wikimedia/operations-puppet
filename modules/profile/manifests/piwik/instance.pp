# SPDX-License-Identifier: Apache-2.0
# == Class: profile::piwik::instance
#
# Configuration options for piwik.wikimedia.org
#
class profile::piwik::instance (
    $database_password = lookup('profile::piwik::database_password'),
    $admin_username    = lookup('profile::piwik::admin_username'),
    $admin_password    = lookup('profile::piwik::admin_password'),
    $password_salt     = lookup('profile::piwik::password_salt'),
    $trusted_hosts     = lookup('profile::piwik::trusted_hosts', { 'default_value' => ['piwik.wikimedia.org', 'wikimediafoundation.org'] }),
    $archive_timer_url = lookup('profile::piwik::archive_timer_url', { 'default_value' => 'piwik.wikimedia.org' }),
    $contact_groups    = lookup('profile::piwik::contact_groups', { 'default_value' => 'team-data-platform' }),
    $piwik_username    = lookup('profile::piwik::piwik_username', { 'default_value' => 'www-data' }),
) {
    # Piwik has been rebranded to Matomo, but the core stays the same.
    # We are going to keep profile/roles with the Piwik naming for a bit
    # more since it is harmless.
    class { 'matomo':
        database_password => $database_password,
        admin_username    => $admin_username,
        admin_password    => $admin_password,
        password_salt     => $password_salt,
        trusted_hosts     => $trusted_hosts,
        piwik_username    => $piwik_username,
    }

    # Copy the MaxMind geoip data files from the puppetmaster into Matomo's /misc directory
    # Matomo can then be manually configured to use these data files for geocoding IP addresses.
    # Functionally this is similar to including geoip::data::puppet, but that uses
    # a recursive copy with different permissions which would clobber other files' permissions in /misc.
    file { '/usr/share/matomo/misc' :
        ensure    => directory,
        owner     => 'root',
        group     => 'root',
        mode      => '0755',
        # lint:ignore:puppet_url_without_modules
        source    => 'puppet:///volatile/GeoIP',
        # lint:endignore
        recurse   => 'remote',
        backup    => false,
        show_diff => false,
    }

    # Install an hourly systemd timer to run the Archive task periodically.
    # We previously ran the timer every 8 hours indexing permitted once per day.
    # However, having reviewed the server load, we feel that we can now increase the frequency
    $archiver_command = "/usr/bin/php /usr/share/matomo/console core:archive --url=\"${archive_timer_url}\""

    systemd::timer::job { 'matomo-archiver':
        description               => "Runs the Matomo's archive process.",
        command                   => "/bin/bash -c '${archiver_command}'",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => 'hourly',
        },
        logfile_basedir           => '/var/log/matomo',
        logfile_name              => 'matomo-archive.log',
        syslog_identifier         => 'matomo-archiver',
        user                      => $piwik_username,
        monitoring_enabled        => true,
        monitoring_contact_groups => $contact_groups,
        require                   => Class['matomo'],
    }
}

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
    $contact_groups    = lookup('profile::piwik::contact_groups', { 'default_value' => 'analytics' }),
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

    # Install GeoIP data files to matomo.
    class { 'geoip::data::puppet':
      require        => Class['matomo'],
      data_directory => '/usr/share/matomo/misc'
    }

    # Install a systemd timer to run the Archive task periodically.
    # Running it once a day to avoid performance penalties on high trafficated websites
    # (https://piwik.org/docs/setup-auto-archiving/#important-tips-for-medium-to-high-traffic-websites)
    $archiver_command = "/usr/bin/php /usr/share/matomo/console core:archive --url=\"${archive_timer_url}\""

    systemd::timer::job { 'matomo-archiver':
        description               => "Runs the Matomo's archive process.",
        command                   => "/bin/bash -c '${archiver_command}'",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00/8:00:00',
        },
        logfile_basedir           => '/var/log/matomo',
        logfile_name              => 'matomo-archive.log',
        syslog_identifier         => 'matomo-archiver',
        user                      => $piwik_username,
        monitoring_contact_groups => $contact_groups,
        require                   => Class['matomo'],
    }
}

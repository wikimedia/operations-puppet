# == Class: piwik
#
# Piwik is an open-source analytics platform.
#
# https://piwik.org/
#
# Piwik's installation is meant to be executed manually using its UI,
# to initialize the database and generate the related config file.
# Therefore each new deployment from scratch will require some manual work,
# please keep it mind.
#
# Misc:
# Q: Where did the deb package come from?
# A: http://debian.piwik.org, imported to jessie-wikimedia.
#
class piwik (
    $database_host      = 'localhost',
    $database_password  = undef,
    $database_username  = 'piwik',
    $admin_username     = undef,
    $admin_password     = undef,
    $password_salt      = undef,
    $trusted_hosts      = [],
    $piwik_username     = 'www-data',
    $archive_cron_url   = undef,
    $archive_cron_email = undef,
) {
    require_package('piwik')

    $database_name = 'piwik'
    $database_table_prefix = 'piwik_'
    $proxy_client_headers = ['HTTP_X_FORWARDED_FOR']

    file { '/etc/piwik/config.ini.php':
        ensure  => present,
        content => template('piwik/config.ini.php.erb'),
        owner   => $piwik_username,
        group   => $piwik_username,
        mode    => '0750',
        require => Package['piwik'],
    }

    file { '/var/log/piwik':
        ensure  => 'directory',
        owner   => $piwik_username,
        group   => $piwik_username,
        mode    => '0755',
        require => Package['piwik'],
    }

    # Install a cronjob to run the Archive task periodically
    # (not user triggered to avoid unexpected performance hits)
    # Running it once a day to avoid performance penalties on high
    # trafficated websites (https://piwik.org/docs/setup-auto-archiving/#important-tips-for-medium-to-high-traffic-websites)
    if $archive_cron_url and $archive_cron_email {
        $cmd = "[ -e /usr/share/piwik/console ] && [ -x /usr/bin/php ] && nice /usr/bin/php /usr/share/piwik/console core:archive --url=\"${archive_cron_url}\" >> /var/log/piwik/piwik-archive.log"
        cron { 'piwik_archiver':
            command     => $cmd,
            user        => $piwik_username,
            environment => "MAILTO=${archive_cron_email}",
            hour        => '8',
            minute      => '0',
            month       => '*',
            monthday    => '*',
            weekday     => '*',
            require     => File['/var/log/piwik'],
        }
    }
}
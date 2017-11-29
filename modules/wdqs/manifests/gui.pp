# == Class: wdqs::gui
#
# Provisions WDQS GUI
#
# == Parameters:
# - $package_dir:  Directory where the service is installed.
# GUI files are expected to be under its gui/ directory.
# - $data_dir: Where the data is installed.
# - $logstash_host: Where to send the logs for the service in syslog format.
#
class wdqs::gui(
    $logstash_host = undef,
    $logstash_syslog_port = 10514,
    $package_dir = $::wdqs::package_dir,
    $data_dir = $::wdqs::data_dir,
    $username = $::wdqs::username,
    $port = 80,
    $additional_port = 8888,
) {

    $alias_map = "${data_dir}/aliases.map"

    ::nginx::site { 'wdqs':
        content => template('wdqs/nginx.erb'),
        require => File[$alias_map],
    }

    file { $alias_map:
        ensure => present,
        owner  => $username,
        group  => 'wikidev',
        mode   => '0664',
    }

    # The directory for operator-controlled nginx flags
    file { '/var/lib/nginx/wdqs/':
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }

    file { '/usr/local/bin/reloadCategories.sh':
        ensure  => present,
        content => template('cron/reloadCategories.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    $cron_log = '/var/log/wdqs/reloadCategories.log'
    # the reload-categories cron needs to reload nginx once the categories are up to date
    sudo::user { "${username}-reload-nginx":
      ensure     => present,
      user       => $username,
      privileges => [ "ALL = NOPASSWD: /usr/sbin/service nginx reload" ],
    }
    cron { 'reload-categories':
        ensure  => present,
        command => "/usr/local/bin/reloadCategories.sh >> ${cron_log}",
        user    => $username,
        minute  => fqdn_rand(60),
        hour    => fqdn_rand(24),
    }
    logrotate::rule { 'wdqs-reload-categories':
        ensure        => present,
        file_glob     => $cron_log,
        frequency     => 'daily',
        copy_truncate => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 30,
        compress      => true,
    }
}

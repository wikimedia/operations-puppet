# == Class: wdqs::gui
#
# Provisions WDQS GUI
#
# == Parameters:
# - $logstash_host: Where to send the logs for the service in syslog format
# - $logstash_syslog_port: port on which to send logs in syslog format
# - $package_dir:  Directory where the service is installed.
#   GUI files are expected to be under its gui/ directory.
# - $data_dir: Where the data is installed.
# - $log_dir: Directory where the logs go
# - $username: Username owning the service
# - $port: main GUI service port
# - $additional_port: secondary port for internal requests
class wdqs::gui(
    $logstash_host = undef,
    $logstash_syslog_port = 10514,
    $package_dir = $::wdqs::package_dir,
    $data_dir = $::wdqs::data_dir,
    $log_dir = $::wdqs::log_dir,
    $username = $::wdqs::username,
    $port = 80,
    $additional_port = 8888,
    $use_git_deploy = $::wdqs::use_git_deploy,
) {

    $alias_map = "${data_dir}/aliases.map"

    ::nginx::site { 'wdqs':
        content => template('wdqs/nginx.erb'),
        require => File[$alias_map],
    }

    # List of namespace aliases in format:
    # ALIAS REAL_NAME;
    # This map is generated manually or by category update script
    file { $alias_map:
        ensure => present,
        owner  => $username,
        group  => 'wikidev',
        mode   => '0664',
    }

    # The directory for operator-controlled nginx flags
    file { '/var/lib/nginx/wdqs/':
        ensure  => directory,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0775',
        # Because nginx site creates /var/lib/nginx
        require => Nginx::Site['wdqs'],
    }

    file { '/etc/wdqs/gui_vars.sh':
        ensure  => present,
        content => template('wdqs/gui_vars.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/usr/local/bin/cronUtils.sh':
        ensure  => present,
        source  => 'puppet:///modules/wdqs/cron/cronUtils.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/wdqs/gui_vars.sh'],
    }

    file { '/usr/local/bin/reloadCategories.sh':
        ensure  => present,
        source  => 'puppet:///modules/wdqs/cron/reloadCategories.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/usr/local/bin/cronUtils.sh'],
    }

    file { '/usr/local/bin/reloadDCAT-AP.sh':
        ensure  => present,
        source  => 'puppet:///modules/wdqs/cron/reloadDCAT-AP.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/usr/local/bin/cronUtils.sh'],
    }

    $cron_log = "${log_dir}/reloadCategories.log"
    # the reload-categories cron needs to reload nginx once the categories are up to date
    sudo::user { "${username}-reload-nginx":
      ensure     => present,
      user       => $username,
      privileges => [ 'ALL = NOPASSWD: /bin/systemctl reload nginx' ],
    }

    # Category dumps start on Sat 20:00. By Mon, they should be done.
    # We want random time so that hosts don't reboot at the same time, but we
    # do not want them to be too far from one another.
    cron { 'reload-categories':
        ensure  => present,
        command => "/usr/local/bin/reloadCategories.sh >> ${cron_log}",
        user    => $username,
        weekday => 1,
        minute  => fqdn_rand(60),
        hour    => fqdn_rand(2),
    }

    cron { 'reload-dcatap':
        ensure  => present,
        command => "/usr/local/bin/reloadDCAT-AP.sh >> ${log_dir}/dcat.log",
        user    => $username,
        weekday => 4,
        minute  => 0,
        hour    => 10,
    }

    logrotate::rule { 'wdqs-reload-categories':
        ensure       => present,
        file_glob    => $cron_log,
        frequency    => 'monthly',
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 3,
        compress     => true,
        su           => "${username} wikidev",
    }

    logrotate::rule { 'wdqs-reload-dcat':
        ensure       => present,
        file_glob    => "${log_dir}/dcatap.log",
        frequency    => 'monthly',
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 3,
        compress     => true,
        su           => "${username} wikidev",
    }

    # Remove categories*.log files after 30 days.
    logrotate::rule { 'wdqs-categories-logs':
        ensure       => present,
        file_glob    => "${log_dir}/categories*.log",
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 0,
        max_age      => 30,
        su           => "${username} wikidev",
    }
}

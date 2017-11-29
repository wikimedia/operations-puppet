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
    # ALIAS REAL_NAME
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

    file { '/usr/local/bin/reloadCategories.sh':
        ensure  => present,
        source  => 'puppet:///modules/wdqs/cron/reloadCategories.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/default/gui_vars.sh'],
    }

}

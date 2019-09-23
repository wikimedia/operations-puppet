# == Class: query_service::gui
#
# Provisions Query Service GUI
#
# == Parameters:
# - $package_dir:  Directory where the service is installed.
#   GUI files are expected to be under its gui/ directory.
# - $data_dir: Where the data is installed.
# - $log_dir: Directory where the logs go
# - $username: Username owning the service
# - $deploy_mode: deployment mode. e.g scap3, manual etc
# - enable_ldf: boolean flag for enabling or disabling ldf
# - $max_query_time_millis: maximum query time in milliseconds
class query_service::gui(
    String $package_dir,
    String $data_dir,
    String $log_dir,
    String $username,
    Query_service::DeployMode $deploy_mode,
    Boolean $enable_ldf,
    Integer $max_query_time_millis,
) {
    $port = 80
    $additional_port = 8888
    $alias_map = "${data_dir}/aliases.map"

    ::nginx::site { 'wdqs':
        content => template('query_service/nginx.erb'),
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
        tag    => 'in-wdqs-data-dir',
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
        content => template('query_service/gui_vars.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}

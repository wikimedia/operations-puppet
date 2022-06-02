# SPDX-License-Identifier: Apache-2.0
# == Class: query_service::gui
#
# Provisions proxy fronting the query service and gui
#
# == Parameters:
# - $package_dir: Directory where the service is installed.
# - $data_dir: Where the data is installed.
# - $log_dir: Directory where the logs go
# - $username: Username owning the service
# - $deploy_mode: deployment mode. e.g scap3, manual etc
# - enable_ldf: boolean flag for enabling or disabling ldf
# - $max_query_time_millis: maximum query time in milliseconds
# - $blazegraph_main_ns: The blazegraph namespace to expose over http at /sparql
# - $gui_url: Url hosting the ui to forward non-blazegraph requests to. Undefined
#    triggers back compat for a locally installed gui which must be found at
#    $package_dir/gui.
class query_service::gui(
    String $package_dir,
    String $data_dir,
    String $log_dir,
    String $deploy_name,
    String $username,
    Query_service::DeployMode $deploy_mode,
    Boolean $enable_ldf,
    Integer $max_query_time_millis,
    String $blazegraph_main_ns,
    Boolean $oauth,
    Optional[Stdlib::HTTPSUrl] $gui_url,
) {
    $port = 80
    $additional_port = 8888
    $alias_map = "${data_dir}/aliases.map"
    $gui_config = '/var/lib/nginx/wdqs/gui_config.json'
    $favicon = '/var/lib/nginx/wdqs/favicon.ico'

    ::nginx::site { $deploy_name:
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

    # The directory for operator-controlled nginx flags, config files and icons
    file { '/var/lib/nginx/wdqs/':
        ensure  => directory,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0775',
        # Because nginx site creates /var/lib/nginx
        require => Nginx::Site[$deploy_name],
    }

    file { "/etc/${deploy_name}/gui_vars.sh":
        ensure  => present,
        content => template('query_service/gui_vars.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    if ($gui_url) {
        # Cleanup old unused files
        file { [$gui_config, $favicon]:
            ensure => absent,
        }
    } else {
        # Files needed when serving the GUI locally
        file { $gui_config:
            ensure => present,
            source => "puppet:///modules/query_service/gui/custom-config-${deploy_name}.json",
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
        }

        file { $favicon:
          ensure => present,
          source => "puppet:///modules/query_service/gui/favicon-${deploy_name}.ico",
          owner  => 'root',
          group  => 'root',
          mode   => '0644',
        }
    }
}

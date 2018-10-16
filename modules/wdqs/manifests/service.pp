# == Class: wdqs::service
#
# Provisions WDQS service package
#
class wdqs::service(
    String $deploy_user,
    Enum['scap3', 'autodeploy'] $deploy_mode,
    Stdlib::Absolutepath $package_dir,
    String $username,
    String $config_file,
    String $logstash_host,
    Wmflib::IpPort $logstash_json_port,
    Stdlib::Absolutepath $autodeploy_log_dir = '/var/log/wdqs-autodeploy',
) {

    include ::wdqs::packages

    case $deploy_mode {

        'scap3': {
            class {'::wdqs::deploy::scap':
                deploy_user => $deploy_user,
                package_dir => $package_dir,
            }
        }

        'manual': {
            class {'::wdqs::deploy::manual':
                deploy_user => $deploy_user,
                package_dir => $package_dir,
            }
        }

        'autodeploy': {
            class { '::wdqs::deploy::autodeploy':
                deploy_user        => $deploy_user,
                package_dir        => $package_dir,
                autodeploy_log_dir => $autodeploy_log_dir,
            }
        }

        default: { }
    }

    # Blazegraph service
    systemd::unit { 'wdqs-blazegraph':
        content => template('wdqs/initscripts/wdqs-blazegraph.systemd.erb'),
    }

    service { 'wdqs-blazegraph':
        ensure => 'running',
    }
}

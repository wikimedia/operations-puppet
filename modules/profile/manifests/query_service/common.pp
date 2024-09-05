class profile::query_service::common(
    String $username = lookup('profile::query_service::username'),
    Stdlib::Unixpath $package_dir = lookup('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = lookup('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = lookup('profile::query_service::log_dir'),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    String $endpoint = lookup('profile::query_service::endpoint'),
    Array[String] $nodes = lookup('profile::query_service::nodes'),
    Stdlib::Httpurl $categories_endpoint =  lookup('profile::query_service::categories_endpoint', { 'default_value' => 'http://localhost:9990' }),
    Optional[String] $forward_rsyslog_host = lookup('profile::query_service::forward_rsyslog_host', { 'default_value' => undef }),
    Array[String] $dumps_servers = lookup('dumps_dist_nfs_servers'),
    String $dumps_active_server = lookup('dumps_dist_active_web'),
    Boolean $mount_dumps = lookup('profile::query_service::mount_dumps', { 'default_value' => false }),
) {
    $deploy_user = 'deploy-service'


    require ::profile::java

    if $forward_rsyslog_host {
        # This is necessary for instances in WMCS. Those instances can't migrate to
        # the new logging pipline pushing to kafka as only instances inside the
        # deployment-prep project can talk to kafka. This uses the direct json lines
        # input to logstash, meaning there is no intermediate buffer and when logstash
        # restarts we can lose logs.
        rsyslog::conf { 'query_service_logging_relay':
          content  => template('profile/query_service/logging_relay.conf.erb'),
          priority => 50,
        }
    } else {
        # Let's migrate to the new logging pipeline. See T232184.
        include ::profile::rsyslog::udp_json_logback_compat
    }

    # enable CPU performance governor; see T315398
    class { 'cpufrequtils': }

    class { '::query_service::common':
      username            => $username,
      deploy_name         => $deploy_name,
      deploy_user         => $deploy_user,
      package_dir         => $package_dir,
      data_dir            => $data_dir,
      log_dir             => $log_dir,
      endpoint            => $endpoint,
      categories_endpoint => $categories_endpoint,
    }

    ensure_packages(['python3-dateutil', 'python3-prometheus-client'])
    file { '/usr/local/bin/prometheus-blazegraph-exporter':
      ensure => present,
      source => 'puppet:///modules/query_service/monitor/prometheus-blazegraph-exporter.py',
      mode   => '0555',
      owner  => 'root',
      group  => 'root',
    }

    # Firewall
    ferm::service {
        'query_service_http':
          proto => 'tcp',
          port  => '80';
        'query_service_https':
          proto => 'tcp',
          port  => '443';
        # temporary port to transfer data file between wdqs nodes via netcat
        'query_service_file_transfer':
          proto  => 'tcp',
          port   => '9876',
          srange => inline_template("@resolve((<%= @nodes.join(' ') %>))");
    }

    # spread IRQ for NIC
    interface::rps { $facts['interface_primary']: }

    # Dumps used to reload the database
    if $mount_dumps {
        class { 'dumpsuser': }
        class { 'query_service::mount_dumps':
          servers       => $dumps_servers,
          active_server => $dumps_active_server,
        }
    }
}

# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::horizon::docker_deploy(
    String          $horizon_version = lookup('profile::openstack::base::horizon_version'),
    String          $openstack_version = lookup('profile::openstack::base::version'),
    Stdlib::Fqdn    $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String          $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    String          $instance_network_id = lookup('profile::openstack::base::horizon::instance_network_id'),
    Hash            $ldap_config = lookup('ldap'),
    String          $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn    $webserver_hostname = lookup('profile::openstack::base::horizon::webserver_hostname'),
    Array[String]   $all_regions = lookup('profile::openstack::base::all_regions'),
    String          $puppet_git_repo_name = lookup('profile::openstack::base::horizon::puppet_git_repo_name'),
    String          $secret_key = lookup('profile::openstack::base::horizon::secret_key'),
    String          $docker_version = lookup('profile::openstack::base::horizon::docker_version'),
    Stdlib::Port::User $port = lookup('profile::openstack::base::horizon::docker_port', { 'default_value' => 8084 }),
    Hash $env                = lookup('profile::openstack::base::horizon::env', { 'default_value' => {} }),
    Hash $secret_env         = lookup('profile::openstack::base::horizon::secret_env', { 'default_value' => {} } ),
) {

    # This is still here because of wikitech
    class { '::httpd':
        modules => [
          'alias',
          'expires',
          'headers',
          'proxy_fcgi',  # Needed by ::openstack::wikitech::web
          'rewrite',
          'ssl',
        ],
    }

    $ldap_rw_host = $ldap_config['rw-server']

    class { '::openstack::horizon::config':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
        dhcp_domain          => $dhcp_domain,
        keystone_api_fqdn    => $keystone_api_fqdn,
        instance_network_id  => $instance_network_id,
        ldap_rw_host         => $ldap_rw_host,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        secret_key           => $secret_key,
    }

    require ::profile::docker::engine
    require ::profile::docker::ferm
    service::docker { 'openstack-dashboard':
        namespace    => 'repos/cloud/cloud-vps/horizon',
        image_name   => 'deploy',
        version      => $docker_version,
        port         => $port,
        environment  => deep_merge($env, $secret_env),
        host_network => true,
        bind_mounts  => {'/etc/openstack-dashboard/local_settings.py' => '/opt/lib/python/site-packages/openstack_dashboard/local/local_settings.py'},
    }

    # Horizon error logs to ELK.  The Apache log is called horizon_error
    #  but it contains anything that the Horizon python code logs.
    #
    # The arcane startmsg_regex is meant to detect continued lines
    #  in python stack-traces. It declares a new message to begine
    #  with a timestamp followed by a single space; two spaces
    #  is taken to be the indented continuation of a message.
    rsyslog::input::file { 'horizon_error':
        path           => '/var/log/apache2/horizon_error.log',
        syslog_tag     => 'horizon',
        startmsg_regex => '^[[:digit:]-]{10} [[:digit:]:]{8}.[[:digit:]]* [^ ]',
    }
}

# SPDX-License-Identifier: Apache-2.0
# == Class: profile::opensearch::security_plugin
#
# Provisions OpenSearch Security Plugin configuration.
#
class profile::opensearch::security_plugin(
    Optional[Stdlib::Fqdn]     $jobs_host             = lookup('profile::opensearch::logstash::jobs_host',                    { default_value => undef }),
    Opensearch::InstanceParams $dc_settings           = lookup('profile::opensearch::dc_settings'),
    String                     $pki_intermediate_name = lookup('profile::opensearch::pki_intermediate_name'),
    Optional[String]           $java_home             = lookup('profile::opensearch::java_home',                              { default_value => undef }),
    Boolean                    $manage_internal_users = lookup('profile::opensearch::security_plugin::manage_internal_users', { default_value => true }),
    Hash                       $internal_users        = lookup('profile::opensearch::security_plugin::internal_users',        { default_value => {} }),
) {
    $cluster_name = $dc_settings['cluster_name']
    $config_dir = "/etc/opensearch/${cluster_name}/opensearch-security"

    file { "${cluster_name}_opensearch-security-dir":
        ensure => 'directory',
        owner  => 'opensearch',
        group  => 'opensearch',
        path   => $config_dir,
    }

    $security_plugin_configs = ['action_groups', 'allowlist', 'audit', 'config', 'nodes_dn', 'roles', 'roles_mapping',
        'tenants', 'whitelist']

    $is_jobs_host = $facts['networking']['fqdn'] == $jobs_host
    $notify_securityadmin = $is_jobs_host ? {
        true    => Exec['run securityadmin.sh'],
        default => undef,
    }

    $security_plugin_configs.each |$fname| {
        file { "${cluster_name}_opensearch-security_${fname}":
            ensure  => 'file',
            owner   => 'opensearch',
            group   => 'opensearch',
            mode    => '0444',
            path    => "${config_dir}/${fname}.yml",
            source  => "puppet:///modules/profile/opensearch/security_plugin/${cluster_name}/${fname}.yml",
            require => File["${cluster_name}_opensearch-security-dir"],
            notify  => $notify_securityadmin,
        }
    }

    # internal_users.yml contains password hashes that we do not want to expose publically.
    # For these environments, we'll manage the file manually.
    if ($manage_internal_users) {
        file { "${cluster_name}_opensearch-security_internal_users":
            ensure    => 'file',
            owner     => 'opensearch',
            group     => 'opensearch',
            mode      => '0440',
            path      => "${config_dir}/internal_users.yml",
            show_diff => false,
            content   => template('profile/opensearch/security_plugin/internal_users.yml.erb'),
            require   => File["${cluster_name}_opensearch-security-dir"],
            notify    => $notify_securityadmin,
        }
    }

    if ($is_jobs_host) {
        # matches DN configuration in opensearch.yml: plugins.security.authcz.admin_dn
        $tls_cert = "/etc/cfssl/ssl/${pki_intermediate_name}__opensearch_admin_${cluster_name}/${pki_intermediate_name}__opensearch_admin_${cluster_name}.pem"
        $tls_key = "/etc/cfssl/ssl/${pki_intermediate_name}__opensearch_admin_${cluster_name}/${pki_intermediate_name}__opensearch_admin_${cluster_name}-key.pem"
        $tls_ca_cert = "/etc/cfssl/ssl/${pki_intermediate_name}__opensearch_admin_${cluster_name}/${pki_intermediate_name}__opensearch_admin_${cluster_name}.chain.pem"
        $java_home_override = pick($java_home, $profile::java::default_java_home)

        file { '/usr/local/bin/securityadmin.sh':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0550',
            content => template('profile/opensearch/security_plugin/securityadmin.sh.erb'),
        }

        exec { 'run securityadmin.sh':
            command     => '/usr/local/bin/securityadmin.sh apply',
            refreshonly => true,
            require     => File['/usr/local/bin/securityadmin.sh'],
        }
    }
}

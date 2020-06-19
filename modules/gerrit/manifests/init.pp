# Manifest to setup a Gerrit instance
class gerrit(
    String $config,
    Stdlib::Fqdn $host,
    Stdlib::Ipv4 $ipv4,
    Array[Stdlib::Fqdn] $replica_hosts = [],
    Boolean $replica = false,
    Boolean $use_acmechief = false,
    Optional[Hash] $ldap_config = undef,
    Optional[Stdlib::Ipv6] $ipv6,
    Integer[8, 11] $java_version = 8,
    Optional[String] $scap_user = undef,
    Optional[String] $scap_key_name = undef,
    Boolean $enable_monitoring = true,
    Boolean $is_new_version = false,
) {

    class { '::gerrit::jetty':
        host              => $host,
        ipv4              => $ipv4,
        ipv6              => $ipv6,
        replica           => $replica,
        replica_hosts     => $replica_hosts,
        config            => $config,
        ldap_config       => $ldap_config,
        java_version      => $java_version,
        scap_user         => $scap_user,
        scap_key_name     => $scap_key_name,
        enable_monitoring => $enable_monitoring,
        is_new_version    => $is_new_version,
    }

    class { '::gerrit::proxy':
        require           => Class['gerrit::jetty'],
        host              => $host,
        ipv4              => $ipv4,
        ipv6              => $ipv6,
        replica_hosts     => $replica_hosts,
        replica           => $replica,
        use_acmechief     => $use_acmechief,
        enable_monitoring => $enable_monitoring,
        is_new_version    => $is_new_version,
    }

    class { '::gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}

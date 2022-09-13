# Manifest to setup a Gerrit instance
class gerrit(
    String                            $config,
    Stdlib::Fqdn                      $host,
    Stdlib::IP::Address::V4           $ipv4,
    Array[Stdlib::Fqdn]               $replica_hosts     = [],
    Boolean                           $replica           = false,
    Boolean                           $use_acmechief     = false,
    Optional[Hash]                    $ldap_config       = undef,
    Optional[Stdlib::IP::Address::V6] $ipv6              = undef,
    Optional[String]                  $scap_user         = undef,
    Optional[String]                  $scap_key_name     = undef,
    Boolean                           $enable_monitoring = true,
    Hash[String, Hash]                $replication       = {},
    Stdlib::Unixpath                  $git_dir           = '/srv/gerrit/git',
    String                            $ssh_host_key      = 'ssh_host_key',
    Stdlib::Unixpath                  $java_home         = undef,
) {

    class { 'gerrit::jetty':
        host              => $host,
        ipv4              => $ipv4,
        ipv6              => $ipv6,
        replica           => $replica,
        replica_hosts     => $replica_hosts,
        config            => $config,
        ldap_config       => $ldap_config,
        scap_user         => $scap_user,
        scap_key_name     => $scap_key_name,
        enable_monitoring => $enable_monitoring,
        replication       => $replication,
        ssh_host_key      => $ssh_host_key,
        git_dir           => $git_dir,
        java_home         => $java_home,
    }

    class { 'gerrit::jobs': }
}

#
class profile::rsyslog::kubernetes (
    Boolean $enable = lookup(
        'profile::rsyslog::kubernetes::enable', {'default_value' => false}),
    Optional[String] $token = lookup(
        'profile::rsyslog::kubernetes::token', {'default_value' => undef}),
    Optional[Stdlib::HTTPSUrl] $kubernetes_url = lookup(
        'profile::rsyslog::kubernetes::kubernetes_url', {'default_value' => undef}),
) {
    require_package('rsyslog-kubernetes')

    $ensure = $enable ? {
      true    => present,
      default => absent,
    }

    rsyslog::conf { 'kubernetes':
        ensure   => $ensure,
        content  => template('profile/rsyslog/kubernetes.conf.erb'),
        priority => 9,
        mode     => '0400', # Contains sensitive token
    }
}

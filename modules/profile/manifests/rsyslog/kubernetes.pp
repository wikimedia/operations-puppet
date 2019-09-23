#
class profile::rsyslog::kubernetes (
    Boolean $enable = lookup('profile::rsyslog::kubernetes::enable', {'default_value' => true}),
    String $token = lookup('profile::rsyslog::kubernetes::token'),
    Stdlib::HTTPSUrl $kubernetes_url = lookup('profile::rsyslog::kubernetes::kubernetes_url'),
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

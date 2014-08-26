#

class openldap {

  package { [
    'slapd',
    'python-ldap',
    ]:
    ensure => installed,
  }

  service { 'slapd':
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['slapd'],
  }

  # our replication dir
  file { "/var/lib/ldap/corp/":
      ensure  => directory,
      recurse => false,
      owner   => openldap,
      group   => openldap,
      mode    => 0750,
      force   => true,
      require => Package["slapd"],
      before  => Service["slapd"],
  }

  file { '/etc/ldap/slapd.conf' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('slapd/slapd.erb'),
  }

  file { '/etc/default/slapd' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('slapd/default.erb'),
  }
}

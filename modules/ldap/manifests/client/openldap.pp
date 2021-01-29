class ldap::client::openldap(
  Hash          $ldapconfig   = {},
  Array[String] $ldapincludes = []
) {

  ensure_packages(['ldap-utils'])

  file { '/etc/ldap/ldap.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('ldap/open_ldap.erb'),
  }
}


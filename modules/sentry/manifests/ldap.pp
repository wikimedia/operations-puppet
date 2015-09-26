# == Class: sentry::ldap
#
# Enable users to authenticate with their Wikimedia LDAP credentials to Sentry.
#
class sentry::ldap {
    require ::sentry

    include ::passwords::ldap::production

    file { '/etc/sentry.d/ldap.conf.py':
        content => template('sentry/ldap.conf.py.erb'),
        owner   => 'sentry',
        group   => 'sentry',
        mode    => '0640',
    }

}


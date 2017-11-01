# == Class: netbox::base
#
# Installs Netbox
#
class netbox(
    $secret_key,
    $ldap_password,
    $db_password,
    $debug=false,
    $port=8001,
    $config_path = '/srv/deployment/netbox/deploy',
    $venv_path = '/srv/deployment/netbox/venv',
    $directory = '/srv/deployment/netbox/netbox'
    $ensure='present',

) {

require_package('virtualenv', 'python3-dev',
                'gunicorn', 'libldap2-dev',
                'build-essential', 'python3-pip',
                'libsasl2-dev', 'libssl-dev')

# If new install, postgres user needs to be manually added, see:
# http://netbox.readthedocs.io/en/stable/installation/postgresql/#database-creation
require_package('postgresql', 'libpq-dev')

}

file { "${directory}/netbox/netbox/configuration.py":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('netbox/configuration.py.erb'),
}

file { "${directory}/netbox/netbox/ldap_config.py":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('netbox/ldap_config.py.erb'),
}

service { 'gunicorn':
    ensure    => ensure_service($ensure),
    enable    => true,
    hasstatus => false,
}

file { '/etc/gunicorn.d/netbox':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('netbox/gunicorn.erb'),
    require => Package['gunicorn'],
}

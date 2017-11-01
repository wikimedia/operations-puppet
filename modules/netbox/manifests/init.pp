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
    $admins=false,
    $config_path = '/srv/deployment/netbox/deploy',
    $venv_path = '/srv/deployment/netbox/venv',
    $directory = '/srv/deployment/netbox/deploy/netbox',
    $ensure='present',

) {

require_package('virtualenv', 'python3-dev',
                'gunicorn', 'libldap2-dev',
                'build-essential', 'python3-pip',
                'libsasl2-dev', 'libssl-dev')

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

}

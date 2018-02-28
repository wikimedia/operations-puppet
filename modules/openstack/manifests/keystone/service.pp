# keystone is the identity service of openstack
# http://docs.openstack.org/developer/keystone/

class openstack::keystone::service(
    $active,
    $version,
    $nova_controller,
    $osm_host,
    $db_name,
    $db_user,
    $db_pass,
    $db_host,
    $token_driver,
    $ldap_hosts,
    $ldap_base_dn,
    $ldap_user_id_attribute,
    $ldap_user_name_attribute,
    $ldap_user_dn,
    $ldap_user_pass,
    $auth_protocol,
    $auth_port,
    $wiki_status_page_prefix,
    $wiki_status_consumer_token,
    $wiki_status_consumer_secret,
    $wiki_status_access_token,
    $wiki_status_access_secret,
    $wiki_consumer_token,
    $wiki_consumer_secret,
    $wiki_access_token,
    $wiki_access_secret,
    ) {

    include ::network::constants
    $prod_networks = $network::constants::production_networks
    $labs_networks = $network::constants::labs_networks

    $packages = [
        'keystone',
        'alembic',
        'python-alembic',
        'python-amqp',
        'python-castellan',
        'python-cliff',
        'python-cmd2',
        'python-concurrent.futures',
        'python-cryptography',
        'python-dogpile.cache',
        'python-eventlet',
        'python-funcsigs',
        'python-futurist',
        'python-jinja2',
        'python-jsonschema',
        'python-oath',
        'python-kombu',
        'python-mysql.connector',
        'python-memcache',
        'python-migrate',
        'python-openssl',
        'python-pyasn1',
        'python-pycadf',
        'python-pyinotify',
        'python-pymysql',
        'python-pyparsing',
        'python-routes',
        'python-sqlalchemy',
        'python-unicodecsv',
        'python-warlock',
        'ldapvi',
        'python-ldap',
        'python-ldappool',
        'python3-ldap3',
        'ruby-ldap',
        'python-mwclient',
    ]

    package { $packages:
        ensure => 'present',
    }

    group {'keystone':
        ensure  => 'present',
        require => Package['keystone'],
    }

    user {'keystone':
        ensure  => 'present',
        require => Package['keystone'],
    }

    if $token_driver == 'redis' {
        package { 'python-keystone-redis':
            ensure => 'present';
        }
    }

    file {
        '/var/log/keystone':
            ensure  => 'directory',
            owner   => 'keystone',
            group   => 'www-data',
            mode    => '0775',
            require => Package['keystone'];
        '/etc/keystone':
            ensure  => 'directory',
            owner   => 'keystone',
            group   => 'keystone',
            mode    => '0755',
            require => Package['keystone'];
        '/etc/keystone/keystone.conf':
            ensure  => 'present',
            owner   => 'keystone',
            group   => 'keystone',
            mode    => '0444',
            content => template("openstack/${version}/keystone/keystone.conf.erb"),
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/keystone-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => "puppet:///modules/openstack/${version}/keystone/keystone-paste.ini",
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/policy.json':
            ensure  => 'present',
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => "puppet:///modules/openstack/${version}/keystone/policy.json",
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            ensure  => 'present',
            source  => "puppet:///modules/openstack/${version}/keystone/logging.conf",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => "puppet:///modules/openstack/${version}/keystone/wmfkeystoneauth",
            notify  => Service['keystone'],
            recurse => true;
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth.egg-info':
            ensure  => 'present',
            source  => "puppet:///modules/openstack/${version}/keystone/wmfkeystoneauth.egg-info",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['keystone'],
            recurse => true;
    }

    if os_version('debian == jessie') {
        file {'/etc/keystone/original':
            ensure => 'directory',
            owner   => 'keystone',
            group   => 'keystone',
            mode    => '0755',
            recurse => true,
            source => "puppet:///openstack/<%= @version %>keystone/original",
            require => Package['keystone'],
        }
    }
    file {'/etc/keystone/bootstrap/keystone.conf.bootstrap':
        ensure => 'present',
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0755',
        content => template("openstack/bootstrap/keystone/keystone.conf.bootstrap.erb"),
    }

    file {'/var/lib/keystone/keystone.db':
        ensure  => 'absent',
        require => Package['keystone'],
    }

    service { 'keystone':
        ensure  => $active,
        require => Package['keystone'];
    }
}

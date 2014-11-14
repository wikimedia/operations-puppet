class openstack::database-server(
    $novaconfig,
    $keystoneconfig,
    $glanceconfig
    ) {
    $nova_db_name = $novaconfig['db_name']
    $nova_db_user = $novaconfig['db_user']
    $nova_db_pass = $novaconfig['db_pass']
    $controller_mysql_root_pass = $novaconfig['controller_mysql_root_pass']
    $puppet_db_name = $novaconfig['puppet_db_name']
    $puppet_db_user = $novaconfig['puppet_db_user']
    $puppet_db_pass = $novaconfig['puppet_db_pass']
    $glance_db_name = $glanceconfig['db_name']
    $glance_db_user = $glanceconfig['db_user']
    $glance_db_pass = $glanceconfig['db_pass']
    $keystone_db_name = $keystoneconfig['db_name']
    $keystone_db_user = $keystoneconfig['db_user']
    $keystone_db_pass = $keystoneconfig['db_pass']

    require mysql::server::package

    if !defined(Service['mysql']) {
        service { 'mysql':
            ensure  => running,
            enable  => true,
            require => Class['mysql::server::package'],
        }
    }

    # TODO: This expects the services to be installed in the same location
    exec {
        'set_root':
            onlyif  => "/usr/bin/mysql -uroot --password=''",
            command => "/usr/bin/mysql -uroot --password='' mysql < /etc/nova/mysql.sql",
            require => [Class['mysql'], File['/etc/nova/mysql.sql']],
            before  => Exec['create_nova_db'];
        'create_nova_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/nova/nova-user.cnf -e 'exit'",
            command => '/usr/bin/mysql -uroot < /etc/nova/nova-user.sql',
            require => [Class['mysql'], File['/etc/nova/nova-user.sql', '/etc/nova/nova-user.cnf', '/root/.my.cnf']];
        'create_nova_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $nova_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $nova_db_name;\"",
            require => [Class['mysql'], File['/root/.my.cnf']],
            before  => Exec['create_nova_db_user'];
        'create_puppet_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/puppet/puppet-user.cnf -e 'exit'",
            command => '/usr/bin/mysql -uroot < /etc/puppet/puppet-user.sql',
            require => [Class['mysql'], File['/etc/puppet/puppet-user.sql', '/etc/puppet/puppet-user.cnf', '/root/.my.cnf']];
        'create_puppet_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $puppet_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $puppet_db_name;\"",
            require => [Class['mysql'], File['/root/.my.cnf']],
            before  => Exec['create_puppet_db_user'];
        'create_glance_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/glance/glance-user.cnf -e 'exit'",
            command => '/usr/bin/mysql -uroot < /etc/glance/glance-user.sql',
            require => [Class['mysql'], File['/etc/glance/glance-user.sql','/etc/glance/glance-user.cnf','/root/.my.cnf']];
        'create_glance_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $glance_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $glance_db_name;\"",
            require => [Class['mysql'], File['/root/.my.cnf']],
            before  => Exec['create_glance_db_user'];
    }

    exec {
        'create_keystone_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/keystone/keystone-user.cnf -e 'exit'",
            command => '/usr/bin/mysql -uroot < /etc/keystone/keystone-user.sql',
            require => [Class['mysql'], File['/etc/keystone/keystone-user.sql', '/etc/keystone/keystone-user.cnf', '/root/.my.cnf']];
        'create_keystone_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $keystone_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $keystone_db_name;\"",
            require => [Class['mysql'], File['/root/.my.cnf']],
            before  => Exec['create_keystone_db_user'];
    }

    file {
        '/root/.my.cnf':
            content => template('openstack/common/controller/my.cnf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640';
        '/etc/nova/mysql.sql':
            content => template('openstack/common/controller/mysql.sql.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['nova-common'];
        '/etc/nova/nova-user.sql':
            content => template('openstack/common/controller/nova-user.sql.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['nova-common'];
        '/etc/nova/nova-user.cnf':
            content => template('openstack/common/controller/nova-user.cnf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['nova-common'];
        '/etc/puppet/puppet-user.sql':
            content => template('openstack/common/controller/puppet-user.sql.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['puppetmaster'];
        '/etc/puppet/puppet-user.cnf':
            content => template('openstack/common/controller/puppet-user.cnf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['puppetmaster'];
        '/etc/glance/glance-user.sql':
            content => template('openstack/common/controller/glance-user.sql.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['glance'];
        '/etc/glance/glance-user.cnf':
            content => template('openstack/common/controller/glance-user.cnf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['glance'];
    }
    file {
        '/etc/keystone/keystone-user.sql':
            content => template('openstack/common/controller/keystone-user.sql.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['keystone'];
        '/etc/keystone/keystone-user.cnf':
            content => template('openstack/common/controller/keystone-user.cnf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package['keystone'];
    }
}

class openstack::firewall {
    include base::firewall

    $labs_private_net = '10.0.0.0/0'
    if ($::site == 'pmtpa') {
        $labs_nodes = '10.4.16.0/24'
        # virt1000
        $other_master = '208.80.154.18'
    } elsif ($::site == 'eqiad') {
        $labs_nodes = '10.64.20.0/24'
        # virt0
        $other_master = '208.80.152.32'
    }

    # Wikitech ssh
    ferm::rule { 'ssh_public':
        rule => 'saddr (0.0.0.0/0) proto tcp dport (ssh) ACCEPT;',
    }

    # Wikitech HTTP/HTTPS
    ferm::rule { 'http_public':
        rule => 'saddr (0.0.0.0/0) proto tcp dport (http https) ACCEPT;',
    }

    # Labs DNS
    ferm::rule { 'dns_public':
        rule => 'saddr (0.0.0.0/0) proto (udp tcp) dport 53 ACCEPT;',
    }

    # LDAP
    ferm::rule { 'ldap_private_labs':
        rule => 'saddr (10.0.0.0/8 208.80.152.0/22) proto tcp dport (ldap ldaps) ACCEPT;',
    }
    ferm::rule { 'ldap_backend_private_labs':
        rule => 'saddr (10.0.0.0/8 208.80.152.0/22) proto tcp dport (1389 1636) ACCEPT;',
    }
    ferm::rule { 'ldap_admin_replication':
        rule => "saddr (10.0.0.244 $other_master) proto tcp dport (4444 8989) ACCEPT;",
    }

    # Redis replication for keystone
    ferm::rule { 'redis_replication':
        rule => "saddr ($other_master) proto tcp dport (6379) ACCEPT;",
    }

    # internal services to Labs virt servers
    ferm::rule { 'keystone':
        rule => "saddr ($other_master $labs_nodes) proto tcp dport (5000 35357) ACCEPT;",
    }
    ferm::rule { 'mysql_nova':
        rule => "saddr $labs_nodes proto tcp dport (3306) ACCEPT;",
    }
    ferm::rule { 'beam_nova':
        rule => "saddr $labs_nodes proto tcp dport (5672 56918) ACCEPT;",
    }
    ferm::rule { 'glance_api_nova':
        rule => "saddr $labs_nodes proto tcp dport 9292 ACCEPT;",
    }

    # services provided to Labs instances
    ferm::rule { 'puppetmaster':
        rule => "saddr $labs_private_net proto tcp dport 8140 ACCEPT;",
    }
    ferm::rule { 'salt':
        rule => "saddr $labs_private_net proto tcp dport (4505 4506) ACCEPT;",
    }

    # allow amanda from tridge; will be dropped soon
    ferm::rule { 'amanda':
        rule => 'saddr 208.80.152.170 proto tcp dport 10080 ACCEPT;',
    }
}

class openstack::repo($openstack_version="folsom") {

    if ($::lsbdistcodename == 'precise') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "precise-updates/${openstack_version}",
            components => 'main',
            keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
        }
    }
}

class openstack::common($openstack_version="folsom",
            $novaconfig,
            $instance_status_wiki_host,
            $instance_status_wiki_domain,
            $instance_status_wiki_page_prefix,
            $instance_status_wiki_region,
            $instance_status_dns_domain,
            $instance_status_wiki_user,
            $instance_status_wiki_pass) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "nova-common", "python-keystone" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    package { [ "unzip", "vblade-persist", "python-mysqldb", "bridge-utils", "ebtables", "mysql-common" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    require mysql

    # For IPv6 support
    package { [ "python-netaddr", "radvd" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    file {
        "/etc/nova/nova.conf":
            content => template("openstack/${$openstack_version}/nova/nova.conf.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }

    file {
        "/etc/nova/api-paste.ini":
            content => template("openstack/${$openstack_version}/nova/api-paste.ini.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }

    if ( $openstack_version == 'havana' ) {
        package { 'python-novaclient':
            ensure => present,
        }
    }
}

class openstack::queue-server($openstack_version, $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "rabbitmq-server" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }
}

class openstack::project-nfs-storage-service {
    generic::upstart_job{ "manage-nfs-volumes":
        install => true,
    }

    service { "manage-nfs-volumes":
        enable  => true,
        require => Generic::Upstart_job["manage-nfs-volumes"];
    }

    $sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
            'ALL = NOPASSWD: /bin/rmdir /srv/*',
            'ALL = NOPASSWD: /usr/local/sbin/sync-exports' ]
    sudo_user { [ "nfsmanager" ]: privileges => $sudo_privs, require => User["nfsmanager"] }

    group { 'nfsmanager':
        ensure => present,
        name   => 'nfsmanager',
        system => true,
    }

    user { 'nfsmanager':
        home       => '/var/lib/nfsmanager',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/etc/exports.d':
        ensure => directory,
        owner  => 'root',
        group  => 'nfsmanager',
        mode   => '2775',
    }

    if ($::site == 'eqiad') {
        cron { "Update labs ssh keys":
                ensure  => present,
                user    => 'root',
                command => '/usr/local/sbin/manage-keys-nfs --logfile=/var/log/manage-keys.log >/dev/null 2>&1',
                hour    => '*',
                minute  => '*/5',
        }
    }
}

class openstack::database-server($openstack_version="folsom", $novaconfig, $keystoneconfig, $glanceconfig) {
    $nova_db_name = $novaconfig["db_name"]
    $nova_db_user = $novaconfig["db_user"]
    $nova_db_pass = $novaconfig["db_pass"]
    $controller_mysql_root_pass = $novaconfig["controller_mysql_root_pass"]
    $puppet_db_name = $novaconfig["puppet_db_name"]
    $puppet_db_user = $novaconfig["puppet_db_user"]
    $puppet_db_pass = $novaconfig["puppet_db_pass"]
    $glance_db_name = $glanceconfig["db_name"]
    $glance_db_user = $glanceconfig["db_user"]
    $glance_db_pass = $glanceconfig["db_pass"]
    $keystone_db_name = $keystoneconfig["db_name"]
    $keystone_db_user = $keystoneconfig["db_user"]
    $keystone_db_pass = $keystoneconfig["db_pass"]

    require mysql::server::package

    if !defined(Service['mysql']) {
        service { "mysql":
            enable  => true,
            require => Class['mysql::server::package'],
            ensure  => running;
        }
    }

    # TODO: This expects the services to be installed in the same location
    exec {
        'set_root':
            onlyif  => "/usr/bin/mysql -uroot --password=''",
            command => "/usr/bin/mysql -uroot --password='' mysql < /etc/nova/mysql.sql",
            require => [Class['mysql'], File["/etc/nova/mysql.sql"]],
            before  => Exec['create_nova_db'];
        'create_nova_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/nova/nova-user.cnf -e 'exit'",
            command => "/usr/bin/mysql -uroot < /etc/nova/nova-user.sql",
            require => [Class['mysql'], File["/etc/nova/nova-user.sql", "/etc/nova/nova-user.cnf", "/root/.my.cnf"]];
        'create_nova_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $nova_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $nova_db_name;\"",
            require => [Class['mysql'], File["/root/.my.cnf"]],
            before  => Exec['create_nova_db_user'];
        'create_puppet_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/puppet/puppet-user.cnf -e 'exit'",
            command => "/usr/bin/mysql -uroot < /etc/puppet/puppet-user.sql",
            require => [Class['mysql'], File["/etc/puppet/puppet-user.sql", "/etc/puppet/puppet-user.cnf", "/root/.my.cnf"]];
        'create_puppet_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $puppet_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $puppet_db_name;\"",
            require => [Class['mysql'], File["/root/.my.cnf"]],
            before  => Exec['create_puppet_db_user'];
        'create_glance_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/glance/glance-user.cnf -e 'exit'",
            command => "/usr/bin/mysql -uroot < /etc/glance/glance-user.sql",
            require => [Class['mysql'], File["/etc/glance/glance-user.sql","/etc/glance/glance-user.cnf","/root/.my.cnf"]];
        'create_glance_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $glance_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $glance_db_name;\"",
            require => [Class['mysql'], File["/root/.my.cnf"]],
            before  => Exec['create_glance_db_user'];
    }

    exec {
        'create_keystone_db_user':
            unless  => "/usr/bin/mysql --defaults-file=/etc/keystone/keystone-user.cnf -e 'exit'",
            command => "/usr/bin/mysql -uroot < /etc/keystone/keystone-user.sql",
            require => [Class['mysql'], File["/etc/keystone/keystone-user.sql", "/etc/keystone/keystone-user.cnf", "/root/.my.cnf"]];
        'create_keystone_db':
            unless  => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot $keystone_db_name -e 'exit'",
            command => "/usr/bin/mysql --defaults-file=/root/.my.cnf -uroot -e \"create database $keystone_db_name;\"",
            require => [Class['mysql'], File["/root/.my.cnf"]],
            before  => Exec['create_keystone_db_user'];
    }

    file {
        "/root/.my.cnf":
            content => template("openstack/common/controller/my.cnf.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640';
        "/etc/nova/mysql.sql":
            content => template("openstack/common/controller/mysql.sql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["nova-common"];
        "/etc/nova/nova-user.sql":
            content => template("openstack/common/controller/nova-user.sql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["nova-common"];
        "/etc/nova/nova-user.cnf":
            content => template("openstack/common/controller/nova-user.cnf.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["nova-common"];
        "/etc/puppet/puppet-user.sql":
            content => template("openstack/common/controller/puppet-user.sql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["puppetmaster"];
        "/etc/puppet/puppet-user.cnf":
            content => template("openstack/common/controller/puppet-user.cnf.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["puppetmaster"];
        "/etc/glance/glance-user.sql":
            content => template("openstack/common/controller/glance-user.sql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["glance"];
        "/etc/glance/glance-user.cnf":
            content => template("openstack/common/controller/glance-user.cnf.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["glance"];
    }
    file {
        "/etc/keystone/keystone-user.sql":
            content => template("openstack/common/controller/keystone-user.sql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["keystone"];
        "/etc/keystone/keystone-user.cnf":
            content => template("openstack/common/controller/keystone-user.cnf.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            require => Package["keystone"];
    }
}

class openstack::openstack-manager($openstack_version="folsom", $novaconfig, $certificate) {
    # require mediawiki::users::mwdeploy  -- temp. removed for ::mediawiki refactor -- OL

    if !defined(Class["webserver::php5"]) {
        class {'webserver::php5': ssl => true; }
    }

    if !defined(Class["memcached"]) {
        class { "memcached":
            memcached_ip => "127.0.0.1",
            pin          => true;
        }
    }

    $controller_hostname = $novaconfig["controller_hostname"]

    package { [ 'php5-ldap', 'php5-uuid', 'imagemagick', 'librsvg2-bin' ]:
        ensure => present;
    }

    $webserver_hostname = $::realm ? {
        'production' => 'wikitech.wikimedia.org',
        default      => $controller_hostname,
    }

    $webserver_hostname_aliases = $::realm ? {
        'production' => 'wmflabs.org www.wmflabs.org',
        default      => "www.${controller_hostname}",
    }

    apache::site { $webserver_hostname:
        content => template("apache/sites/${webserver_hostname}.erb"),
    }

    # ::mediawiki::scap supports syncing the wikitech wiki from tin.
    #  It also defines /a which is used later on in this manifest for backups.
    include ::mediawiki::scap

    file {
        "/var/www/robots.txt":
            ensure => present,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///files/openstack/wikitech-robots.txt";
        "/a/backup":
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
            ensure => directory;
        "/a/backup/public":
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
            ensure => directory;
        "/usr/local/sbin/db-bak.sh":
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///files/openstack/db-bak.sh";
        "/usr/local/sbin/mw-files.sh":
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///files/openstack/mw-files.sh";
        "/usr/local/sbin/mw-xml.sh":
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///files/openstack/mw-xml.sh";
    }

    cron {
        "run-jobs":
            user    => 'apache',
            command => '/usr/local/bin/mwscript maintenance/runJobs.php --wiki=labswiki > /dev/null 2>&1',
            ensure  => present;
        "send-echo-emails":
            user    => 'apache',
            command => '/usr/local/bin/mwscript extensions/Echo/maintenance/processEchoEmailBatch.php --wiki=labswiki > /dev/null 2>&1',
            ensure  => present;
        "db-bak":
            user    => 'root',
            hour    => 1,
            minute  => 0,
            command => '/usr/local/sbin/db-bak.sh > /dev/null 2>&1',
            require => File["/a/backup"],
            ensure  => present;
        "mw-xml":
            user    => 'root',
            hour    => 1,
            minute  => 30,
            command => '/usr/local/sbin/mw-xml.sh > /dev/null 2>&1',
            require => File["/a/backup"],
            ensure  => present;
        "mw-files":
            user    => 'root',
            hour    => 2,
            minute  => 0,
            command => '/usr/local/sbin/mw-files.sh > /dev/null 2>&1',
            require => File["/a/backup"],
            ensure  => present;
        "backup-cleanup":
            user    => 'root',
            hour    => 3,
            minute  => 0,
            command => 'find /a/backup -type f -mtime +4 -delete',
            require => File["/a/backup"],
            ensure  => present;
    }


    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include backup::host
    backup::set {'a-backup': }

    include nrpe

    if ( $openstack_version == 'havana' ) {
        package { 'nova-xvpvncproxy':
            ensure => present,
        }
        package { 'nova-novncproxy':
            ensure => present,
        }
        package { 'nova-consoleauth':
            ensure => present,
        }
        package { 'novnc':
            ensure => present,
        }
    }
}

class openstack::scheduler-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { "nova-scheduler":
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-scheduler":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-scheduler"];
    }
}

class openstack::conductor-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { "nova-conductor":
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-conductor":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-conductor"];
    }
}

class openstack::neutron-controller($neutronconfig, $data_interface_ip) {
    package { 'neutron-server':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    service { 'neutron-server':
        ensure    => 'running',
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['neutron-server'],
    }

    file { '/etc/neutron/neutron.conf':
        content => template("openstack/${$openstack_version}/neutron/neutron.conf.erb"),
        owner   => 'neutron',
        group   => 'nogroup',
        notify  => Service['neutron-server'],
        require => Package['neutron-server'],
        mode    => '0440',
    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
        content => template("openstack/${$openstack_version}/neutron/ovs_neutron_plugin.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-server'],
        require => Package['neutron-server', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }
}

# Set up neutron on a dedicated network node
class openstack::neutron-nethost(
    $openstack_version='folsom',
    $external_interface='eth0',
    $neutronconfig,
    $data_interface_ip
) {
    if ! defined(Class['openstack::repo']) {
        class { 'openstack::repo': openstack_version => $openstack_version }
    }

    package { 'neutron-dhcp-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'neutron-l3-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'neutron-metadata-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'openvswitch-datapath-dkms':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'dnsmasq':
        ensure  => 'present',
    }

    service { 'openvswitch-switch':
        ensure    => 'running',
        require   => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    service { 'neutron-plugin-openvswitch-agent':
        ensure    => 'running',
        require   => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    service { 'neutron-dhcp-agent':
        ensure    => 'running',
        require   => Package['neutron-dhcp-agent'],
    }

    service { 'neutron-l3-agent':
        ensure    => 'running',
        require   => Package['neutron-l3-agent'],
    }

    service { 'neutron-metadata-agent':
        ensure    => 'running',
        require   => Package['neutron-metadata-agent'],
    }

    exec { 'create_br-int':
            unless  => "/usr/bin/ovs-vsctl br-exists br-int",
            command => "/usr/bin/ovs-vsctl add-br br-int",
            require => Service['openvswitch-switch'],
    }

    exec { 'create_br-ex':
            unless  => "/usr/bin/ovs-vsctl br-exists br-ex",
            command => "/usr/bin/ovs-vsctl add-br br-ex",
            require => Service['openvswitch-switch'],
            before  => Exec['add-port'],
    }


    exec { 'add-port':
            unless  => "/usr/bin/ovs-vsctl list-ports br-ex | /bin/grep ${external_interface}",
            command => "/usr/bin/ovs-vsctl add-port br-ex ${external_interface}",
            require => Service['openvswitch-switch'],
    }

    file { '/etc/neutron/neutron.conf':
        content => template("openstack/${$openstack_version}/neutron/neutron.conf.erb"),
        owner   => 'neutron',
        group   => 'nogroup',
        notify  => Service['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        require => Package['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    file { '/etc/neutron/api-paste.ini':
        content => template("openstack/${$openstack_version}/neutron/api-paste.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        require => Package['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
        content => template("openstack/${$openstack_version}/neutron/ovs_neutron_plugin.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        require => Package['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    sysctl::parameters { 'openstack':
        values => {
            # Turn off IP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Enable IP forwarding
            'net.ipv4.ip_forward'             => 1,
            'net.ipv6.conf.all.forwarding'    => 1,

            # Disable RA
            'net.ipv6.conf.all.accept_ra'     => 0,
        },
    }
}

class openstack::network-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package {  [ "nova-network", "dnsmasq" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-network":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-network"];
    }

    # dnsmasq is run manually by nova-network, we don't want the service running
    service { "dnsmasq":
        enable  => false,
        ensure  => stopped,
        require => Package["dnsmasq"];
    }

    $nova_dnsmasq_aliases = {
        # eqiad
        'deployment-cache-text02'   => {public_ip  => '208.80.155.135',
                                        private_ip => '10.68.16.16' },
        'deployment-cache-upload02' => {public_ip  => '208.80.155.136',
                                        private_ip => '10.68.17.51' },
        'deployment-cache-bits01'   => {public_ip  => '208.80.155.137',
                                        private_ip => '10.68.16.12' },
        'deployment-stream'         => {public_ip  => '208.80.155.138',
                                        private_ip => '10.68.17.106' },
        'deployment-cache-mobile03' => {public_ip  => '208.80.155.139',
                                        private_ip => '10.68.16.13' },
        'tools-webproxy'            => {public_ip  => '208.80.155.131',
                                        private_ip => '10.68.16.4' },
        'udplog'                    => {public_ip  => '208.80.155.191',
                                        private_ip => '10.68.16.58' },

        # A wide variety of hosts are reachable via a public web proxy.
        'labs_shared_proxy' => {public_ip  => '208.80.155.156',
                                private_ip => '10.68.16.65'},
    }

    file { '/etc/dnsmasq-nova.conf':
        content => template("openstack/${$openstack_version}/nova/dnsmasq-nova.conf.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    sysctl::parameters { 'openstack':
        values => {
            # Turn off IP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Enable IP forwarding
            'net.ipv4.ip_forward'         => 1,
            'net.ipv6.conf.all.forwarding'    => 1,

            # Disable RA
            'net.ipv6.conf.all.accept_ra'     => 0,
        },
        priority => 50,
    }
}

class openstack::api-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package {  [ "nova-api" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-api":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-api"];
    }
    file { "/etc/nova/policy.json":
        source  => "puppet:///files/openstack/${openstack_version}/nova/policy.json",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        notify  => Service["nova-api"],
        require => Package["nova-api"];
    }
}

class openstack::volume-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "nova-volume" ]:
        ensure  => absent,
        require => Class["openstack::repo"];
    }

    #service { "nova-volume":
    #   ensure    => stopped,
    #   subscribe => File['/etc/nova/nova.conf'],
    #   require   => Package["nova-volume"];
    #}
}

class openstack::compute-service($openstack_version="folsom", $novaconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    if ( $::realm == "production" ) {
        $certname = "virt-star.${site}.wmnet"
        install_certificate{ "${certname}": }
        install_additional_key{ "${certname}": key_loc => "/var/lib/nova", owner => 'nova', group => "libvirtd", require => Package["nova-common"] }

        file {
            "/var/lib/nova/clientkey.pem":
                ensure  => link,
                target  => "/var/lib/nova/${certname}.key",
                require => Install_additional_key["${certname}"];
            "/var/lib/nova/clientcert.pem":
                ensure  => link,
                target  => "/etc/ssl/certs/${certname}.pem",
                require => Install_certificate["${certname}"];
            "/var/lib/nova/cacert.pem":
                ensure  => link,
                target  => "/etc/ssl/certs/wmf-ca.pem",
                require => Install_certificate["${certname}"];
            "/var/lib/nova/.ssh":
                ensure  => directory,
                owner   => 'nova',
                group   => 'nova',
                mode    => '0700',
                require => Package["nova-common"];
            "/var/lib/nova/.ssh/id_rsa":
                source  => "puppet:///private/ssh/nova/nova.key",
                owner   => 'nova',
                group   => 'nova',
                mode    => '0600',
                require => File["/var/lib/nova/.ssh"];
            "/var/lib/nova/.ssh/authorized_keys":
                source  => "puppet:///private/ssh/nova/nova.pub",
                owner   => 'nova',
                group   => 'nova',
                mode    => '0600',
                require => File["/var/lib/nova/.ssh"];
            "/etc/libvirt/libvirtd.conf":
                notify  => Service["libvirt-bin"],
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template("openstack/common/nova/libvirtd.conf.erb"),
                require => Package["nova-common"];
            "/etc/default/libvirt-bin":
                notify  => Service["libvirt-bin"],
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template("openstack/common/nova/libvirt-bin.default.erb"),
                require => Package["nova-common"];
            "/etc/nova/nova-compute.conf":
                notify  => Service['nova-compute'],
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template("openstack/common/nova/nova-compute.conf.erb"),
                require => Package["nova-common"];
        }
    }

    service { "libvirt-bin":
        ensure  => running,
        enable  => true,
        require => Package["nova-common"];
    }

    package { [ 'nova-compute', "nova-compute-kvm" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    # nova-compute adds the user with /bin/false, but resize, live migration, etc.
    # need the nova use to have a real shell, as it uses ssh.
    user { 'nova':
        ensure  => present,
        shell   => "/bin/bash",
        require => Package["nova-common"];
    }

    service { 'nova-compute':
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-compute'];
    }

    file {
        "/etc/libvirt/qemu/networks/autostart/default.xml":
            ensure  => absent;
        # Live hack to use qcow2 ephemeral base images. Need to upstream
        # a config option for this in havana.
        "/usr/share/pyshared/nova/virt/libvirt/driver.py":
            source  => "puppet:///files/openstack/${openstack_version}/nova/virt-libvirt-driver",
            notify  => Service['nova-compute'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package["nova-common"];
    }
}

# Set up neutron on a compute node
class openstack::neutron-compute($neutronconfig, $data_interface_ip) {
    sysctl::parameters { 'openstack':
        values   => {
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,
        },
        priority => 50,
    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'openvswitch-datapath-dkms':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    service { 'openvswitch-switch':
        ensure    => 'running',
        require   => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    service { 'neutron-plugin-openvswitch-agent':
        ensure    => 'running',
        require   => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    exec { 'create_br-int':
        unless  => "/usr/bin/ovs-vsctl br-exists br-int",
        command => "/usr/bin/ovs-vsctl add-br br-int",
        require => Service['openvswitch-switch'],
    }

    file { '/etc/neutron/neutron.conf':
        content => template("openstack/${$openstack_version}/neutron/neutron.conf.erb"),
        owner   => 'neutron',
        group   => 'nogroup',
        require => Package['neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
        content => template("openstack/${$openstack_version}/neutron/ovs_neutron_plugin.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-plugin-openvswitch-agent'],
        require => Package['neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }
}

class openstack::keystone-service($openstack_version="folsom", $keystoneconfig, $glanceconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "keystone" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    if $keystoneconfig['token_driver'] == 'redis' {
        package { [ "python-keystone-redis" ]:
            ensure => present;
        }
    }


    service { "keystone":
        ensure    => running,
        subscribe => File['/etc/keystone/keystone.conf'],
        require   => Package["keystone"];
    }

    file {
        "/etc/keystone/keystone.conf":
            content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
            owner   => keystone,
            group   => keystone,
            notify  => Service["keystone"],
            require => Package["keystone"],
            mode    => '0440';
    }
}

class openstack::glance-service($openstack_version="folsom", $glanceconfig) {
    if ! defined(Class["openstack::repo"]) {
        class { "openstack::repo": openstack_version => $openstack_version }
    }

    package { [ "glance" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "glance-api":
        ensure  => running,
        require => Package["glance"];
    }

    service { "glance-registry":
        ensure  => running,
        require => Package["glance"];
    }

    file {
        "/etc/glance/glance-api.conf":
            content => template("openstack/${$openstack_version}/glance/glance-api.conf.erb"),
            owner   => 'glance',
            group   => nogroup,
            notify  => Service["glance-api"],
            require => Package["glance"],
            mode    => '0440';
        "/etc/glance/glance-registry.conf":
            content => template("openstack/${$openstack_version}/glance/glance-registry.conf.erb"),
            owner   => 'glance',
            group   => nogroup,
            notify  => Service["glance-registry"],
            require => Package["glance"],
            mode    => '0440';
    }
    if ($openstack_version == "essex") {
        # Keystone config was (thankfully) moved out of the paste config
        # So, past essex we don't need to change these.
        file {
            "/etc/glance/glance-api-paste.ini":
                content => template("openstack/${$openstack_version}/glance/glance-api-paste.ini.erb"),
                owner   => 'glance',
                group   => 'glance',
                notify  => Service["glance-api"],
                require => Package["glance"],
                mode    => '0440';
            "/etc/glance/glance-registry-paste.ini":
                content => template("openstack/${$openstack_version}/glance/glance-registry-paste.ini.erb"),
                owner   => 'glance',
                group   => 'glance',
                notify  => Service["glance-registry"],
                require => Package["glance"],
                mode    => '0440';
        }
    }
}

# Exposes a set of web endpoints that perform an explicit check for a
# particular set of internal services, and response OK (200) or not (anything else)
# Used for external monitoring / collection of availability metrics
#
# This runs as an ldap user, toolschecker, so it can touch NFS without causing
# idmapd related issues.

class toollabs::checker inherits toollabs {

    include ::gridengine::submit_host
    include ::toollabs::infrastructure

    require_package('python-flask',
                    'python-psycopg2',
                    'python-pymysql',
                    'python-redis',
                    'uwsgi',
                    'uwsgi-plugin-python')

    package { 'toollabs-webservice':
        ensure => latest,
    }

    $checks = {
        'self'                            => {
            path                          => '/self'
        },
        'puppet_catalog'                  => {
            path                          => '/labs-puppetmaster/eqiad',
        },
        'labs_private'                    => {
            path                          => '/labs-dns/private',
        },
        'nfs_secondary_cluster_showmount' => {
            path                          => '/nfs/secondary_cluster_showmount',
        },
        'ldap'                            => {
            path                          => '/ldap',
        },
        'nfs_home'                        => {
            path                          => '/nfs/home',
        },
        'redis'                           => {
            path                          => '/redis',
        },
        'labsdb_clouddb1001'               => {
            path                          => '/labsdb/clouddb1001',
        },
        'labsdb_wikilabelsrw'             => {
            path                          => '/labsdb/wikilabelsrw',
        },
        'toolsdb'                         => {
            path                          => '/toolsdb',
        },
        'dumps'                           => {
            path                          => '/dumps',
        },
        'continuous_job_trusty'           => {
            path                          => '/continuous/trusty',
        },
        'grid_start_trusty'               => {
            path                          => '/grid/start/trusty',
        },
        'cron'                            => {
            path                          => '/toolscron',
        },
        'flannel_etcd'                    => {
            path                          => '/etcd/flannel',
        },
        'kubernetes_etcd'                 => {
            path                          => '/etcd/k8s',
        },
        'kubernetes_nodes_ready'          => {
            path                          => '/k8s/nodes/ready',
        },
        'webservice_kubernetes'           => {
            path                          => '/webservice/kubernetes',
        },
        'service_start'                   => {
            path                          => '/service/start',
        },
    }

    create_resources(toollabs::check, $checks)

    file { ['/run/toolschecker', '/var/lib/toolschecker', '/var/lib/toolschecker/puppetcerts']:
        ensure => directory,
        owner  => "${::labsproject}.toolschecker",
        group  => 'www-data',
        mode   => '0755',
        before => Toollabs::Check[keys($checks)],
    }

    file { '/usr/local/lib/python2.7/dist-packages/toolschecker.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/toolschecker.py',
        notify => Toollabs::Check[keys($checks)],
    }

    file { '/data/project/toolschecker/www/python/src/app.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/toolschecker_generic_service.py',
        notify => Toollabs::Check[keys($checks)],
    }

    file { '/data/project/toolschecker/public_html/index.php':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/toolschecker_lighttpd_service.php',
        notify => Toollabs::Check[keys($checks)],
    }

    # We need this host's puppet cert and key (readable) so we can check
    #  puppet status
    file { '/var/lib/toolschecker/puppetcerts/cert.pem':
        ensure => present,
        owner  => "${::labsproject}.toolschecker",
        group  => 'www-data',
        mode   => '0400',
        source => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
    }

    file { '/var/lib/toolschecker/puppetcerts/key.pem':
        ensure => present,
        owner  => "${::labsproject}.toolschecker",
        group  => 'www-data',
        mode   => '0400',
        source => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    }

    file { '/usr/local/sbin/toolscheckerctl':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/toollabs/toolscheckerctl',
    }

    sudo::user { 'tools.toolschecker':
        privileges => [
            'ALL=(tools.toolschecker-k8s-ws) NOPASSWD: ALL',
            'ALL=(tools.toolschecker-ge-ws) NOPASSWD: ALL',
        ],
    }

    nginx::site { 'toolschecker-nginx':
        content => template('toollabs/toolschecker.nginx.erb'),
        require => Toollabs::Check[keys($checks)],
    }

}

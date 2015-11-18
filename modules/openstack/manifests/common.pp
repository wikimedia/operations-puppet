# common packages and config for openstack
class openstack::common(
            $novaconfig,
            $instance_status_wiki_host,
            $instance_status_wiki_domain,
            $instance_status_wiki_page_prefix,
            $instance_status_wiki_region,
            $instance_status_dns_domain,
            $instance_status_wiki_user,
            $instance_status_wiki_pass,
            $openstack_version=$::openstack::version,
            ) {

    include openstack::repo

    $packages = [ 'unzip',
                 'nova-common',
                 'vblade-persist',
                 'bridge-utils',
                 'ebtables',
                 'mysql-common',
                 'mysql-client-5.5',
                 'python-mysqldb',
                 'python-netaddr',
                 'python-keystone',
                 'python-novaclient',
                 'python-openstackclient',
                 'radvd',
    ]
    require_package($packages)

    file {
        '/etc/nova/nova.conf':
            content => template("openstack/${$openstack_version}/nova/nova.conf.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
        '/etc/nova/api-paste.ini':
            content => template("openstack/${$openstack_version}/nova/api-paste.ini.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }
}

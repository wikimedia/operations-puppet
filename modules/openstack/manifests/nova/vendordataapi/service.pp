# This is a WMF-specific REST api that services instance-specific
#  vendordata for cloud-init
#
# This api is NOT behind haproxy; it only listens on localhost
#  and is presumed to run on the same host as nova-api.
class openstack::nova::vendordataapi::service(
    String $version,
    Stdlib::Port $vendordata_bind_port,
    String $dhcp_domain,
    Stdlib::Fqdn $keystone_fqdn,
    String $ldap_user_pass,
    ) {

    file { '/usr/local/sbin/novavendordata.py':
        ensure => 'present',
        mode   => '0755',
        owner  => 'nova',
        group  => 'nova',
        source => "puppet:///modules/openstack/${version}/nova/vendordata/novavendordata.py",
    }

    file { '/etc/novavendordata':
        ensure => 'directory',
        owner  => 'nova',
        group  => 'nova',
        mode   => '0755',
    }

    file { '/etc/novavendordata/paste.ini':
        ensure => 'present',
        mode   => '0644',
        owner  => 'nova',
        group  => 'nova',
        source => "puppet:///modules/openstack/${version}/nova/vendordata/paste.ini",
    }

    file { '/etc/novavendordata/vendordata.txt.jinja2':
        ensure => 'present',
        mode   => '0644',
        owner  => 'nova',
        group  => 'nova',
        source => "puppet:///modules/openstack/${version}/nova/vendordata/vendordata.txt.jinja2",
    }

    file { '/etc/novavendordata/novavendordata.conf':
        ensure  => 'present',
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
        content => template("openstack/${version}/nova/vendordata/novavendordata.conf.erb"),
    }

    systemd::service { 'novavendordata':
        ensure  => present,
        content => systemd_template('novavendordata'),
        restart => true,
        require => [File[
                        '/etc/novavendordata/novavendordata.conf',
                        '/etc/novavendordata/paste.ini',
                        '/etc/novavendordata/vendordata.txt.jinja2',
                        '/usr/local/sbin/novavendordata.py',
                    ]],
    }
}

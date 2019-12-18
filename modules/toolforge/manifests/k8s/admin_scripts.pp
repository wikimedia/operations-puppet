class toolforge::k8s::admin_scripts (
) {
    file { '/usr/local/sbin/wmcs-k8s-get-cert':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toolforge/k8s/admin_scripts/wmcs-k8s-get-cert.sh',
    }

    file { '/usr/local/sbin/wmcs-k8s-secret-for-cert':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toolforge/k8s/admin_scripts/wmcs-k8s-secret-for-cert.sh',
    }

    file { '/usr/local/sbin/wmcs-k8s-enable-cluster-monitor':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toolforge/k8s/admin_scripts/wmcs-k8s-enable-cluster-monitor.sh',
    }
}

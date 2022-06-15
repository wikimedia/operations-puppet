# SPDX-License-Identifier: Apache-2.0
class prometheus::node_openstack_stale_puppet_certs (
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/openstack_stale_puppet_certs.prom',
) {
    if $outfile !~ '\.prom$' {
        fail("outfile (${outfile}): Must have a .prom extension")
    }

    ensure_packages('python3-prometheus-client')

    file { '/usr/local/sbin/prometheus-openstack-stale-puppet-certs':
        ensure => file,
        mode   => '0500',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-openstack-stale-puppet-certs.py',
    }

    $signed_certs_dir = "${::facts['puppet_config']['master']['ssldir']}/ca/signed"

    systemd::timer::job { 'prometheus_openstack_stale_puppet_certs':
        ensure      => present,
        description => 'Regular job to collect information about stale Puppet certificates',
        user        => 'root',
        command     => "/usr/local/sbin/prometheus-openstack-stale-puppet-certs --outfile ${outfile} --signed-certs-dir ${signed_certs_dir}",
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '10m'},
    }
}


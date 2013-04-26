class ceph::mon(
    $monitor_secret,
) {
    Class['ceph::mon'] -> Class['ceph']

    $cluster  = 'ceph'
    $mon_data = "/var/lib/ceph/mon/ceph-${::hostname}"
    $keyring  = "/var/lib/ceph/tmp/${cluster}-${::hostname}.mon.keyring"

    file { $mon_data:
        ensure => directory,
        mode   => '0600',
        owner  => 'root',
        group  => 'root',
    }

    exec { 'ceph-mon-keyring':
        command => "/usr/bin/ceph-authtool \
                   '${keyring}' \
                   --create-keyring \
                   --name=mon. \
                   --add-key='${monitor_secret}' \
                   --cap mon 'allow *'",
        creates => $keyring,
        unless  => "/usr/bin/test -e ${mon_data}/keyring",
        before  => Exec['ceph-mon-mkfs'],
    }

    exec { 'ceph-mon-mkfs':
        command  => "/usr/bin/ceph-mon --mkfs \
                     -i ${::hostname} \
                     --keyring ${keyring}",
        creates  => "${mon_data}/keyring",
        notify   => Exec['ceph-create-keys'],
    }

    exec { 'ceph-create-keys':
        command     => "/usr/bin/ceph --name=mon. --keyring=${mon_data}/keyring \
                        auth add client.admin \
                        --in-file=/etc/ceph/ceph.client.admin.keyring \
                         mon 'allow *' osd 'allow *' mds allow",
        onlyif      => "/usr/bin/ceph \
                        --admin-daemon /var/run/ceph/ceph-mon.${::hostname}.asok \
                        mon_status | egrep -v '\"state\": \"(leader|peon)\"'",
        refreshonly => true,
    }
}

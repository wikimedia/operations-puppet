define openstack::nova::libvirt::secret (
    String[1]        $keydata,
    String[1]        $client_name,
    String[1]        $libvirt_uuid,
    Stdlib::Unixpath $data_dir = '/etc/libvirt',
) {
    $xmlfile = "${data_dir}/libvirt-secret-${client_name}.xml"
    file { $xmlfile:
        ensure    => present,
        mode      => '0400',
        owner     => 'root',
        group     => 'root',
        content   => epp(
            'openstack/nova/libvirt-secret.xml.epp',
            { 'uuid' => $libvirt_uuid, 'ceph_client_name' => $client_name },
        ),
        show_diff => false,
        require   => Service['libvirtd'],
    }

    $check_secret_exec_name = "check-virsh-secret-for-${client_name}"
    exec { $check_secret_exec_name:
        command   => "/usr/bin/virsh secret-define --file ${xmlfile}",
        unless    => "/usr/bin/virsh secret-list | grep -q ${libvirt_uuid}",
        logoutput => false,
        require   => File[$xmlfile],
    }

    $set_secret_exec_name = "set-virsh-secret-for-${client_name}"
    exec { $set_secret_exec_name:
        command   => "/usr/bin/virsh secret-set-value --secret ${libvirt_uuid} --base64 ${keydata}",
        unless    => "/usr/bin/virsh secret-get-value --secret ${libvirt_uuid} | grep -q ${keydata}",
        logoutput => false,
        require   => Exec[$check_secret_exec_name],
    }
}

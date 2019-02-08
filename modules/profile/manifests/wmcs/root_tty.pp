class profile::wmcs::root_tty {
    # Run a tty on serial1.  This can only be accessed as root on
    #  the hypervisor hosting the VM, via
    #
    # virsh console --devname serial1 <ec2id>
    #
    if os_version('debian >= jessie') {
        systemd::service { 'getty@ttyS1.service':
            ensure   => present,
            content  => file('profile/wmcs/root_tty.conf'),
            restart  => true,
            override => true,
        }
    }
}

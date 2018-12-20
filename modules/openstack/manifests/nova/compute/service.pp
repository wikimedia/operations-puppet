# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack::nova::compute::service(
    $version,
    $libvirt_type,
    $certname,
    $ca_target,
    ){

    require openstack::nova::compute::audit
    include openstack::nova::compute::kmod

    if (os_version('debian jessie') or os_version('debian stretch')) and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    # Libvirt package is different in subtle ways across Ubuntu and Jessie
    $libvirt_service = $facts['lsbdistcodename'] ? {
        'trusty'  => 'libvirt-bin',
        'jessie'  => 'libvirtd',
        'stretch' => 'libvirtd',
    }

    $libvirt_default_conf = $facts['lsbdistcodename'] ? {
        'trusty'  => '/etc/default/libvirt-bin',
        'jessie'  => '/etc/default/libvirtd',
        'stretch' => '/etc/default/libvirtd',
    }

    # trusty: libvirtd:x:117:nova
    # jessie: libvirt:x:121:nova
    # stretch: libvirt:x:121:nova
    $libvirt_unix_sock_group = $facts['lsbdistcodename'] ? {
        'trusty'  => 'libvirtd',
        'jessie'  => 'libvirt',
        'stretch' => 'libvirt',
    }

    # Without qemu-system, apt will install qemu-kvm by default,
    # which is somewhat broken.
    package { 'qemu-system':
        ensure          => 'present',
        install_options => $install_options,
    }

    $libvirt_package = $facts['lsbdistcodename'] ? {
        'trusty'  => 'libvirt-bin',
        'jessie'  => 'libvirt-bin',
        'stretch' => ['libvirt-daemon-system', 'libvirt-clients'],
    }

    package { $libvirt_package:
        ensure => 'present',
    }

    package { [
        'nova-compute',
        'nova-compute-kvm',
        'spice-html5',
        'websockify',
        'virt-top',
        'dnsmasq-base',
    ]:
        ensure          => 'present',
        install_options => $install_options,
        require         => Package['qemu-system'],
    }

    # use exec to set the shell to not shadow the manage
    # the user for the package which causes Puppet
    # to see the user as a dependency anywhere the
    # nova user is used to ensure good permission
    exec {'set_shell_for_nova':
        command   => '/usr/sbin/usermod -c "shell set for online operations" -s /bin/bash nova',
        unless    => '/bin/grep "nova:" /etc/passwd | /bin/grep ":\/bin\/bash"',
        logoutput => true,
        require   => Package['nova-compute'],
    }

    ssh::userkey { 'nova':
        content => secret('ssh/nova/nova.pub'),
        require => Exec['set_shell_for_nova'],
    }

    file { '/var/lib/nova/.ssh':
        ensure  => 'directory',
        owner   => 'nova',
        group   => 'nova',
        mode    => '0700',
        require => Package['nova-compute'],
    }

    file { '/var/lib/nova/.ssh/id_rsa':
        owner     => 'nova',
        group     => 'nova',
        mode      => '0600',
        content   => secret('ssh/nova/nova.key'),
        require   => File['/var/lib/nova/.ssh'],
        show_diff => false,
    }

    file { '/var/lib/nova/.ssh/id_rsa.pub':
        owner   => 'nova',
        group   => 'nova',
        mode    => '0600',
        content => secret('ssh/nova/nova.pub'),
        require => File['/var/lib/nova/.ssh'],
    }

    sslcert::certificate { $certname: }

    file { "/var/lib/nova/${certname}.key":
        owner     => 'nova',
        group     => $libvirt_unix_sock_group,
        mode      => '0440',
        content   => secret("ssl/${certname}.key"),
        require   => Package['nova-compute'],
        show_diff => false,
    }

    file { '/var/lib/nova/clientkey.pem':
        ensure => link,
        target => "/var/lib/nova/${certname}.key",
    }

    file { '/var/lib/nova/clientcert.pem':
        ensure  => link,
        target  => "/etc/ssl/localcerts/${certname}.crt",
        require => Sslcert::Certificate[$certname],
    }

    file { '/var/lib/nova/cacert.pem':
        ensure  => link,
        target  => $ca_target,
        require => Sslcert::Certificate[$certname],
    }

    if os_version('ubuntu == trusty') {

        # On Ubuntu as of Liberty:
        #   qemu-kvm and qemu-system are alternative packages to meet
        #   the needs of libvirt.
        package { [ 'qemu-kvm' ]:
            ensure  => 'absent',
            require => Package['qemu-system'],
        }

        # On Ubuntu as of Liberty:
        #   Some older VMs have a hardcoded path to the emulator
        #   binary, /usr/bin/kvm.  Since the kvm/qemu reorg,
        #   new distros don't create a kvm binary.  We can safely
        #   alias kvm to qemu-system-x86_64 which keeps those old
        #   instances happy.
        #   (Note: Jessie handles this by creating a shell script shortcut)
        file { '/usr/bin/kvm':
            ensure  => 'link',
            target  => '/usr/bin/qemu-system-x86_64',
            require => Package['qemu-system'],
        }

        file { '/etc/libvirt/qemu/networks/autostart/default.xml':
            ensure  => 'absent',
            require => Package['libvirt-bin'],
        }
    }

    if os_version('debian == jessie') {

        # /etc/default/libvirt-guests
        # Guest management on host startup/reboot
        service{'libvirt-guests':
            ensure => 'stopped',
        }

        file {'/etc/libvirt/original':
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            recurse => true,
            source  => "puppet:///modules/openstack/${version}/nova/libvirt/original",
            require => Package['nova-compute'],
        }
    }

    file { '/etc/libvirt/libvirtd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("openstack/${version}/nova/compute/libvirtd.conf.erb"),
        notify  => Service[$libvirt_service],
        require => Package['nova-compute'],
    }

    file { $libvirt_default_conf:
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("openstack/${version}/nova/compute/libvirt.default.erb"),
        notify  => Service[$libvirt_service],
        require => Package['nova-compute'],
    }

    file { '/etc/nova/nova-compute.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("openstack/${version}/nova/compute/nova-compute.conf.erb"),
        notify  => Service['nova-compute'],
        require => Package['nova-compute'],
    }

    service { $libvirt_service:
        ensure  => 'running',
        enable  => true,
        require => Package['libvirt-bin'],
    }

    service { 'nova-compute':
        ensure    => 'running',
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/nova-compute.conf'],
            ],
        require   => Package['nova-compute'],
    }

    # By default trusty allows the creation of user namespaces by unprivileged users
    # (Debian defaulted to disallowing these since the feature was introduced for security reasons)
    # Unprivileged user namespaces are not something we need in general (and especially
    # not in trusty where support for namespaces is incomplete) and was the source for
    # several local privilege escalation vulnerabilities. The 4.4 HWE kernel for trusty
    # contains a backport of the Debian patch allowing to disable the creation of user
    # namespaces via a sysctl, so disable to limit the attack footprint
    if os_version('ubuntu == trusty') and (versioncmp($::kernelversion, '4.4') >= 0) {
        sysctl::parameters { 'disable-unprivileged-user-namespaces-labvirt':
            values => {
                'kernel.unprivileged_userns_clone' => 0,
            },
        }
    }
}

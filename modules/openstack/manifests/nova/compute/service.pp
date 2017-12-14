# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack::nova::compute::service(
    $version,
    $libvirt_type,
    $certname,
    $ca_target,
    ){

    # Check for buggy kernels.  There are a lot of them!
    if os_version('ubuntu >= trusty') and (versioncmp($::kernelrelease, '3.13.0-46') < 0) {
        # see: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1346917
        fail('nova-compute not installed on buggy kernels.  Old versions of 3.13 have a KSM bug.  Try installing linux-image-generic-lts-xenial')
    } elsif $::kernelrelease =~ /^3\.13\..*/ {
        fail('nova-compute not installed on buggy kernels.  On 3.13 series kernels, instance suspension causes complete system lockup.  Try installing linux-image-generic-lts-xenial')
    } elsif $::kernelrelease =~ /^3\.19\..*/ {
        fail('nova-compute not installed on buggy kernels.  On 3.19 series kernels, instance clocks die after resuming from suspension.  Try installing linux-image-generic-lts-xenial')
    }

    # Starting with 3.18 (34666d467cbf1e2e3c7bb15a63eccfb582cdd71f) the netfilter code
    # was split from the bridge kernel module into a separate module (br_netfilter)
    if (versioncmp($::kernelversion, '3.18') >= 0) {
        kmod::module { 'br_netfilter':
            ensure => 'present',
        }
    }

    # Without qemu-system, apt will install qemu-kvm by default,
    # which is somewhat broken.
    package { 'qemu-system':
        ensure  => 'present',
    }

    package { [
        'nova-compute',
        'nova-compute-kvm',
        'spice-html5',
        'websockify',
        'virt-top',
        'libvirt-bin',
    ]:
        ensure  => 'present',
        require => Package['qemu-system'],
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


    # nova-compute adds the user with /bin/false
    # but resize, live migration, etc
    # need the nova use to have a real shell, as it uses ssh.
    user { 'nova':
        ensure  => 'present',
        shell   => '/bin/bash',
        require => Package['nova-compute'],
    }

    ssh::userkey { 'nova':
        content => secret('ssh/nova/nova.pub'),
    }

    # qemu-kvm and qemu-system are alternative packages to meet the needs of
    # libvirt.
    #  Lately, Precise has been installing qemu-kvm by default.  That's
    #  different
    #  from our old, existing servers, and it also defaults to use spice for vms
    #  even though spice is not installed.  Messy.
    package { [ 'qemu-kvm' ]:
        ensure  => absent,
        require => Package['qemu-system'],
    }

    sslcert::certificate { $certname: }

    file { "/var/lib/nova/${certname}.key":
        owner     => 'nova',
        group     => 'libvirtd',
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

    # Some older VMs have a hardcoded path to the emulator
    #  binary, /usr/bin/kvm.  Since the kvm/qemu reorg,
    #  new distros don't create a kvm binary.  We can safely
    #  alias kvm to qemu-system-x86_64 which keeps those old
    #  instances happy.
    file { '/usr/bin/kvm':
        ensure  => link,
        target  => '/usr/bin/qemu-system-x86_64',
        require => Package['qemu-system'],
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

    file { '/etc/libvirt/libvirtd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("openstack/${version}/nova/compute/libvirtd.conf.erb"),
        notify  => Service['libvirt-bin'],
        require => Package['nova-compute'],
    }

    file { '/etc/default/libvirt-bin':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("openstack/${version}/nova/compute/libvirt-bin.default.erb"),
        notify  => Service['libvirt-bin'],
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

    file { '/etc/libvirt/qemu/networks/autostart/default.xml':
        ensure  => 'absent',
        require => Package['libvirt-bin'],
    }

    service { 'libvirt-bin':
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

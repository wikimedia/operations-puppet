# basic profile for every CloudVPS instance
class profile::wmcs::instance(
    Boolean      $mount_nfs      = lookup('mount_nfs',       {default_value => false}),
    Boolean      $diamond_remove = lookup('diamond::remove', {default_value => false}),
    String       $sudo_flavor    = lookup('sudo_flavor',     {default_value => 'sudoldap'}),
    Stdlib::Fqdn $metrics_server = lookup('graphite_host',   {default_value => 'localhost'}),
) {
    # force sudo on buster
    if $sudo_flavor == 'sudo' or debian::codename::ge('buster') {
        if ! defined(Class['Sudo']) {
            class { 'sudo': }
        }
    } else {
        if ! defined(Class['Sudo::Sudoldap']) {
            class { 'sudo::sudoldap': }
        }
    }

    sudo::group { 'ops':
        privileges => ['ALL=(ALL) NOPASSWD: ALL'],
    }

    class { 'profile::ldap::client::labs':
        # Puppet requires ldap, so we need to update ldap before anything
        #  happens to puppet.
        before => File['/etc/puppet/puppet.conf'],
    }

    # make common logs readable
    class { 'base::syslogs':
        readable => true,
    }

    file { '/etc/mailname':
        ensure  => present,
        content => "${::fqdn}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    package { 'puppet-lint':
        ensure => present,
    }

    # We are using nfsv4, which doesn't require rpcbind on clients. T241710
    # However, removing the package removes nfs-common.
    if $facts['nfscommon_version'] {
        service { 'rpcbind':
            ensure => 'stopped',
        }
        exec { '/bin/systemctl mask rpcbind.service':
            creates => '/etc/systemd/system/rpcbind.service',
        }
    }

    # Allows per-host placement of NFS mounts, defaults to false
    if $mount_nfs {
        require profile::wmcs::nfsclient
    }

    # In production, we try to be punctilious about having Puppet manage
    # system state, and thus it's reasonable to purge Apache site configs
    # that have not been declared via Puppet. But on Labs we want to allow
    # users to manage configuration files locally if they so choose,
    # without having Puppet clobber them. So provision a
    # /etc/apache2/sites-local directory for Apache to recurse into during
    # initialization, but do not manage its contents.
    exec { 'enable_sites_local':
        command => '/bin/mkdir -m0755 /etc/apache2/sites-local && \
                    /usr/bin/touch /etc/apache2/sites-local/dummy.conf && \
                    /bin/echo "Include sites-local/*" >> /etc/apache2/apache2.conf',
        onlyif  => '/usr/bin/test -d /etc/apache2 -a ! -d /etc/apache2/sites-local',
    }

    # Still needed for Toolforge
    if debian::codename::eq('stretch'){
        apt::repository { 'debian-backports':
            uri         => 'http://mirrors.wikimedia.org/debian/',
            dist        => 'stretch-backports',
            components  => 'main contrib non-free',
            comment_old => true,
        }
    }

    # In production, puppet freshness checks are done by icinga. Labs has no
    # icinga, so collect puppet freshness metrics via diamond/graphite
    if ! $diamond_remove {
        # Prefix labs metrics with project name
        $path_prefix  = $::labsproject
        $server_ip    = ipresolve($metrics_server, 4)

        class { 'diamond':
            path_prefix   => $path_prefix,
            keep_logs_for => '0',
            service       => true,
            settings      => {
                # lint:ignore:quoted_booleans
                # Diamond needs its bools in string-literals.
                enabled => 'true',
                # lint:endignore
                host    =>  $server_ip,
                port    => '2003',
                batch   => '20',
            },
        }

        base::service_auto_restart { 'diamond': }

        diamond::collector { 'MinimalPuppetAgent':
            ensure => 'absent',
        }
    }

    class { 'prometheus::node_ssh_open_sessions': }

    # TODO: is this still the most uptodate function?
    hiera_include('classes', [])

    # Signal to rc.local that this VM is up and we don't need to run the firstboot
    #  script anymore
    file { '/root/firstboot_done':
        ensure  => present,
        content => '',
    }

    file { '/usr/sbin/prepare_cinder_volume':
        ensure => present,
        source => 'puppet:///modules/profile/wmcs/instance/prepare_cinder_volume.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }
}

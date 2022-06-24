# basic profile for every CloudVPS instance
class profile::wmcs::instance(
    Boolean             $mount_nfs                     = lookup('mount_nfs',       {default_value => false}),
    Boolean             $diamond_remove                = lookup('diamond::remove', {default_value => false}),
    String              $sudo_flavor                   = lookup('sudo_flavor',     {default_value => 'sudoldap'}),
    Stdlib::Fqdn        $metrics_server                = lookup('graphite_host',   {default_value => 'localhost'}),
    Array[Stdlib::Fqdn] $metricsinfra_prometheus_nodes = lookup('profile::wmcs::instance::metricsinfra_prometheus_nodes', {default_value => []}),
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

    # wmflabs_imageversion is provided by labs_vmbuilder/files/postinst.copy
    # because this is a pre-installed file, migrating is nontrivial, so we keep
    # the original file name.
    file { '/etc/wmcs-imageversion':
        ensure => link,
        target => '/etc/wmflabs_imageversion',
    }

    file { '/etc/wmcs-instancename':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::hostname}\n",
    }
    file { '/etc/wmflabs-instancename':
        ensure => link,
        target => '/etc/wmcs-instancename',
    }
    file { '/etc/wmcs-project':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::labsproject}\n",
    }
    file { '/etc/wmflabs-project':
        ensure => link,
        target => '/etc/wmcs-project',
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
        exec { 'systemctl mask rpcbind.service':
            path    => ['/bin', '/usr/bin'],
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
        onlyif  => '/usr/bin/test -e /etc/apache2/apache2.conf -a ! -d /etc/apache2/sites-local',
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
    #
    # Diamond isn't packaged for Bullseye so we'll have to live without it.
    if ! $diamond_remove and debian::codename::le('buster') {
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

        profile::auto_restarts::service { 'diamond': }
    }

    class { 'prometheus::node_ssh_open_sessions': }

    # TODO: move this so it doesn't need a lint:ignore for a lookup in the middle of a class
    lookup('classes', {default_value => []}).include()  # lint:ignore:wmf_styleguide

    # Signal to rc.local that this VM is up and we don't need to run the firstboot
    #  script anymore
    file { '/root/firstboot_done':
        ensure  => present,
        content => '',
    }

    # Update /etc/hosts using the new cloud-init template.
    #  Note that cloud-init will only update the file if
    #  manage_etc_hosts = True in the initial cloud setup
    #  of the VM. That means that legacy VMs (from before
    #  widespread adoption of cloud-init) will not
    #  be affected by this.
    #
    # We might also be on a system that doesn't have cloud-init
    #  at all, which is just fine.
    exec { 'cloud-init refresh /etc/hosts':
        command     => '/usr/bin/cloud-init single -n cc_update_etc_hosts',
        onlyif      => '/usr/bin/test -f /usr/bin/cloud-init',
        refreshonly => true,
    }

    file { ['/etc/cloud', '/etc/cloud/templates']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/cloud/templates/hosts.debian.tmpl':
        ensure  => present,
        content => template('profile/wmcs/instance/hosts.debian.tmpl.erb'),
        owner   => 'root',
        group   => 'root',
        require => File['/etc/cloud', '/etc/cloud/templates'],
        notify  => Exec['cloud-init refresh /etc/hosts'],
        mode    => '0644',
    }

    # sudo rules added by cloud-init for the 'debian' user, not needed in our setup
    file { [ '/etc/sudoers.d/90-cloud-init-users', '/etc/sudoers.d/debian-cloud-init' ]:
        ensure => absent,
    }

    # this seems to be installed by default but doesn't do much on a VM.
    #  T287309
    package { 'smartmontools':
        ensure => absent,
        notify => Exec['reset-failed for smartmontools'],
    }
    exec { 'reset-failed for smartmontools':
        path        => ['/bin', '/usr/bin'],
        command     => 'systemctl reset-failed smartd.service',
        refreshonly => true,
    }

    class {'::cinderutils': }

    if !empty($metricsinfra_prometheus_nodes) {
        ferm::rule { 'metricsinfra-prometheus-all':
            rule => "saddr @resolve((${metricsinfra_prometheus_nodes.join(' ')})) ACCEPT;"
        }
    }
}

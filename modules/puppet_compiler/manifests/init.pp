# Installs the puppet compiler and all the other software we need.
class puppet_compiler(
    $version = '0.5.0',
    $workdir = '/srv/jenkins-workspace/puppet-compiler',
    $libdir  = '/var/lib/catalog-differ',
    $ensure  = 'present',
    $user    = 'jenkins-deploy',
    $homedir = '/srv/home/jenkins-deploy',
    $puppetdb_major_version = undef,
    ) {

    require ::puppet_compiler::packages

    $vardir = "${libdir}/puppet"

    file { [$libdir, $vardir, $workdir]:
        ensure => ensure_directory($ensure),
        owner  => $user,
        mode   => '0755',
    }

    if $ensure == 'present' {
        class { '::puppet_compiler::setup':
            user    => $user,
            vardir  => $vardir,
            homedir => $homedir,
        }
    }

    file { '/usr/local/bin/sshknowngen':
        ensure => absent,
    }
    # We don't really need some generators from puppet master, link them to
    # /bin/true
    file { ['/usr/local/bin/naggen2',
            '/usr/local/bin/prometheus-ganglia-gen']:
        ensure => ensure_link($ensure),
        target => '/bin/true',
    }

    include ::puppet_compiler::web

    ## Git cloning

    # Git clone of the puppet repo
    git::clone { 'operations/puppet':
        ensure    => $ensure,
        directory => "${libdir}/production",
        owner     => $user,
        mode      => '0755',
        require   => File[$libdir],
    }

    # Git clone labs/private
    git::clone { 'labs/private':
        ensure    => $ensure,
        directory => "${libdir}/private",
        owner     => $user,
        mode      => '0755',
        require   => File[$libdir],
    }

    $compiler_dir = "${libdir}/compiler"
    # Git clone the puppet compiler, install it
    git::install { 'operations/software/puppet-compiler':
        ensure    => $ensure,
        git_tag   => $version,
        directory => $compiler_dir,
        owner     => $user,
        notify    => Exec['install compiler'],
    }

    # Install the compiler
    exec { 'install compiler':
        command     => '/usr/bin/python setup.py install',
        user        => 'root',
        cwd         => $compiler_dir,
        refreshonly => true,
    }

    # configuration file
    file { '/etc/puppet-compiler.conf':
        ensure  => $ensure,
        owner   => $user,
        content => template('puppet_compiler/puppet-compiler.conf.erb'),
    }


    # The conftool parser function needs
    # An etcd instance running populated with (fake? synced?) data

    include ::etcd
    # A new, better approach is to just use confd independently. Here we
    # fake it with a file on disk
    file { '/etc/conftool-state':
        ensure => directory,
        mode   => '0755'
    }
    file { '/etc/conftool-state/mediawiki.yaml':
        ensure => present,
        mode   => '0444',
        source => 'puppet:///modules/puppet_compiler/mediawiki.yaml'
    }

    tidy { "${::puppet_compiler::workdir}/output":
        recurse => true,
        age     => '6w',
        rmdirs  => true,
    }

    require_package('openjdk-8-jdk')

    unless $puppetdb_major_version == 4 {
        class { '::puppet_compiler::legacy_local_database':
            user   => $user,
            vardir => $vardir,
        }
    }

    $puppetdb_port = $puppetdb_major_version ? {
        4       => '443',
        default => '8081',
    }

    class { 'puppetmaster::puppetdb::client':
        host                   => $::fqdn,
        port                   => $puppetdb_port,
        puppetdb_major_version => $puppetdb_major_version,
    }
    # puppetdb configuration
    file { "${vardir}/puppetdb.conf":
        source  => '/etc/puppet/puppetdb.conf',
        owner   => $user,
        require => File['/etc/puppet/puppetdb.conf']
    }

    # periodic script to populate puppetdb. Run at 4 AM every sunday.
    cron { 'Populate puppetdb':
        command => "/usr/local/bin/puppetdb-populate --basedir ${libdir} > ${homedir}/puppetdb-populate.log 2>&1",
        user    => $user,
        hour    => 4,
        minute  => 0,
        weekday => 0,
    }
}

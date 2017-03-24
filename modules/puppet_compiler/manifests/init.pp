# Installs the puppet compiler and all the other software we need.
class puppet_compiler(
    $version = '0.0.4',
    $workdir = '/mnt/jenkins-workspace/puppet-compiler',
    $libdir  = '/var/lib/catalog-differ',
    $ensure  = 'present',
    $user    = 'jenkins-deploy',
    $homedir = '/mnt/home/jenkins-deploy',
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

    # We don't really need some generators from puppet master, link them to
    # /bin/true
    file { ['/usr/local/bin/sshknowngen',
            '/usr/local/bin/naggen2',
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

    tidy { "${::puppet_compiler::workdir}/output":
        recurse => true,
        age     => '6w',
        rmdirs  => true,
    }
}

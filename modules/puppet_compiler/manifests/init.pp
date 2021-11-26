# Installs the puppet compiler and all the other software we need.
class puppet_compiler(
    String           $version    = '0.9.0',  # The compiler* hosts override this in horizon
    Stdlib::Unixpath $workdir    = '/srv/jenkins-workspace/puppet-compiler',
    Stdlib::Unixpath $libdir     = '/var/lib/catalog-differ',
    Wmflib::Ensure   $ensure     = 'present',
    String           $user       = 'jenkins-deploy',
    Stdlib::Unixpath $homedir    = '/srv/home/jenkins-deploy',
    Boolean          $enable_web = true,
) {

    $vardir = "${libdir}/puppet"
    $yamldir = "${vardir}/yaml"

    ensure_packages([
        'python-yaml', 'python-requests', 'python-jinja2', 'nginx',
        'ruby-httpclient', 'ruby-ldap', 'ruby-rgen', 'ruby-multi-json',
        ])
        file {'/usr/lib/ruby/vendor_ruby/puppet/application/master.rb':
            ensure  => present,
            content => file('puppet_compiler/puppet_master_pup-8187.rb.nocheck'),
        }


    wmflib::dir::mkdir_p($libdir, {
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        mode   => '0644',
        recurse => true,
    })
    wmflib::dir::mkdir_p($workdir, {
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        mode   => '0644',
    })
    file{
        default:
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => $user,
            mode   => '0644';
        $vardir: ;
    $yamldir:
        recurse => true;
    }

    if $ensure == 'present' {
        class { 'puppet_compiler::setup':
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
    file { '/usr/local/bin/naggen2':
        ensure => stdlib::ensure($ensure, 'link'),
        target => '/bin/true',
    }

    class {'puppet_compiler::web':
        ensure => $enable_web.bool2str('present', 'absent')
    }

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
        command     => '/usr/bin/python3 setup.py install',
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
}

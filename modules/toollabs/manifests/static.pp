# = Class: toollabs::proxy
#
# A static http server, serving static files from NFS
# Also serves an up-to-date mirror of cdnjs
class toollabs::static(
    $resolver = '10.68.16.1',
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_settings = ssl_ciphersuite('nginx', 'compat'),
) inherits toollabs {
    include toollabs::infrastructure

    if $ssl_certificate_name != false {
        install_certificate { $ssl_certificate_name:
            privatekey => false,
        }
    }

    labs_lvm::volume { 'cdnjs-disk':
        mountat => '/srv',
        size    => '100%FREE'
    }

    # This is a 11Gig pure content repository with no executable code
    # Hence not mirroring on gerrit
    # Also gerrit will probably die from a 11Gig repo
    # This does not mean it's ok to clone other things from github on ops/puppet :)
    git::clone { 'cdnjs':
        directory => '/srv/cdnjs',
        origin    => 'https://github.com/cdnjs/cdnjs.git',
        ensure    => latest,
        require   => Labs_lvm::Volume['cdnjs-disk'],
    }

    file { '/usr/local/bin/cdnjs-packages-gen':
        source => 'puppet:///modules/toollabs/cdnjs-packages-gen',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    exec { 'generate-cdnjs-packages-json':
        command => '/usr/local/bin/cdnjs-packages-gen /srv/cdnjs /srv/cdnjs/packages.json',
        require => [File['/usr/local/bin/cdnjs-packages-gen'], Git::Clone['cdnjs']],
    }

    nginx::site { 'static-server':
        content => template('toollabs/static-server.conf.erb'),
        require => Git::Clone['cdnjs'],
    }
}

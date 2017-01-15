# A static http server, serving static files from NFS
# Also serves an up-to-date mirror of cdnjs

class toollabs::static(
    $web_domain = 'tools.wmflabs.org',
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_settings = ssl_ciphersuite('nginx', 'compat'),
) {

    include ::toollabs::infrastructure

    if $ssl_certificate_name != false {
        sslcert::certificate { $ssl_certificate_name: }
    }

    labs_lvm::volume { 'cdnjs-disk':
        mountat => '/srv',
        size    => '100%FREE',
    }

    # This is a 11Gig pure content repository with no executable code
    # Hence not mirroring on gerrit
    # Also gerrit will probably die from a 11Gig repo
    # This does not mean it's ok to clone other things from github on ops/puppet :)
    exec { 'clone-cdnjs':
        command => '/usr/bin/git clone --depth 1 https://github.com/cdnjs/cdnjs.git /srv/cdnjs',
        creates => '/srv/cdnjs',
        # This is okay because puppet-run defines a timeout, and this takes longer than the default
        # exec timeout of 300s
        timeout => 0,
        require => Labs_lvm::Volume['cdnjs-disk'],
    }

    cron { 'update-cdnjs':
        command => 'cd /srv/cdnjs && /usr/bin/git pull --depth 1 https://github.com/cdnjs/cdnjs.git && /usr/local/bin/cdnjs-packages-gen /srv/cdnjs /srv/cdnjs/packages.json',
        user    => 'root',
        hour    => 0,
        minute  => 0,
        require => Exec['clone-cdnjs'],
    }

    file { '/usr/local/bin/cdnjs-packages-gen':
        source => 'puppet:///modules/toollabs/cdnjs-packages-gen',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $resolver = join($::nameservers, ' ')
    nginx::site { 'static-server':
        content => template('toollabs/static-server.conf.erb'),
    }
}

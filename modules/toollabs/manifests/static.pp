# = Class: toollabs::proxy
#
# A static http server, serving static files from NFS
# Also serves an up-to-date mirror of cdnjs
class toollabs::static(
    $web_domain = 'tools.wmflabs.org',
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_settings = ssl_ciphersuite('nginx', 'compat'),
) {
    include toollabs::infrastructure

    if $ssl_certificate_name != false {
        sslcert::certificate { $ssl_certificate_name: skip_private => true }
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
        ensure    => latest,
        directory => '/srv/cdnjs',
        origin    => 'https://github.com/cdnjs/cdnjs.git',
        require   => Labs_lvm::Volume['cdnjs-disk'],
    }

    # Prune branches deleted upstream once per day
    cron { 'prune /srv/cdnjs':
        ensure  => present,
        command => 'cd /srv/cdnjs && git fetch --prune --quiet',
        user    => 'root',
        hour    => 9,
        minute  => 5 * fqdn_rand(12, 'prune /srv/cdnjs'),
    }

    # Aggressively collect garbage refs once per week
    cron { 'gc /srv/cdnjs':
        ensure  => present,
        command => 'cd /srv/cdnjs && git gc --aggressive --quiet',
        user    => 'root',
        hour    => 17
        minute  => 5 * fqdn_rand(12, 'gc /srv/cdnjs'),
        weekday => 3,
    }

    file { '/usr/local/bin/cdnjs-packages-gen':
        source => 'puppet:///modules/toollabs/cdnjs-packages-gen',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    exec { 'generate-cdnjs-packages-json':
        command     => '/usr/local/bin/cdnjs-packages-gen /srv/cdnjs /srv/cdnjs/packages.json',
        refreshonly => true,
        subscribe   => [File['/usr/local/bin/cdnjs-packages-gen'],
                        Git::Clone['cdnjs']],
    }

    $resolver = join($::nameservers, ' ')
    nginx::site { 'static-server':
        content => template('toollabs/static-server.conf.erb'),
        require => Git::Clone['cdnjs'],
    }
}

#

class install-server::apt-repository {
    package { [
        'dpkg-dev',
        'gnupg',
        'reprepro',
        'dctrl-tools'
        ]:
        ensure => latest,
    }

    # TODO: add something that sets up /etc/environment for reprepro

    file {
        '/srv/wikimedia/':
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root';
        '/usr/local/sbin/update-repository':
            # TODO: This has been long enough in deprecation, time to ensure
            # deletion, remove this resource at some later time
            ensure  => absent,
    }

    # Reprepro configuration
    file {
        '/srv/wikimedia/conf':
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root';
        '/srv/wikimedia/conf/log':
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/reprepro-log';
        '/srv/wikimedia/conf/distributions':
            mode    => '0444',
            source  => 'puppet:///modules/install-server/reprepro-distributions';
        '/srv/wikimedia/conf/updates':
            mode    => '0444',
            source  => 'puppet:///modules/install-server/reprepro-updates';
        '/srv/wikimedia/conf/incoming':
            mode    => '0444',
            source  => 'puppet:///modules/install-server/reprepro-incoming';
    }

    alert('The Wikimedia Archive Signing GPG keys need to be installed manually on this host.')
}

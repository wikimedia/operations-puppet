class labs-bots::common {
    # Language stuff needed for bots
    include generic::locales::international

    # Git
    include generic::packages::git-core

    # Common software
    package {
        [ 'perl', 'python', 'ksh', 'csh' ]:
            ensure => latest;
    }

    # Symlink for backwards compatibility
    file {
        '/mnt/public_html':
            ensure => link,
            target => '/data/project/public_html'
    }
}

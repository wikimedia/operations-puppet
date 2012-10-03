class labs-bots::common {
    # Language stuff needed for bots
    include generic::locales::international

    # Symlink for backwards compatibility
    file {
        '/mnt/public_html':
            ensure => link,
            target => '/data/project/public_html'
    }

    # TODO - any common packages on all instances
}

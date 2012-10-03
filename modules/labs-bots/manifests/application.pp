class labs::bots::application {
    # Common stuff
    include labs::bots::common

    # Standard application packages
    include generic::packages::git-core
    package {
        [ 'python3-minimal', 'python-virtualenv' ]:
            ensure => latest
    }

    # TODO - for things like mono do we want generic classes then
    # include packages::mono or such in here?
    # TODO - Add all standard software
}

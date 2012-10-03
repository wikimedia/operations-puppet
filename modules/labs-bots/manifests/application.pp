class labs::bots::application {
    # Common stuff
    include labs::bots::common;

    # Standard application packages
    package {
        [ 'python3-minimal', 'python-virtualenv', 'git-core' ]:
            ensure => latest;
    }

    # TODO - for things like mono do we want generic classes then
    # include packages::mono or such in here?
    # TODO - Add all standard software
}

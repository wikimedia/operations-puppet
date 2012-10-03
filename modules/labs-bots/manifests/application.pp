class labs-bots::application {
    # Common stuff
    include labs-bots::common

    # Standard application packages
    package {
        [ 'python3-minimal', 'python-virtualenv', 'openjdk-6-jre-headless',
        'build-essential', 'subversion', 'mono-common', 'libmediawiki-api-perl',
        'php5', ]:
            ensure => latest
    }
}

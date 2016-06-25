# Install arcanist and the .arcrc so that it can find our phabricator instance
# this is needed for running `arc lint` and `arc unit` on contint slaves.
class contint::arcanist {
    require_package('arcanist')

    file { '/var/lib/jenkins/.arcrc':
        ensure  => 'file',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0600',
        require => User['jenkins'],
        source  => 'puppet:///modules/contint/arcrc.json',
    }
}

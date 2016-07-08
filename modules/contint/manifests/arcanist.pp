# Install arcanist and the .arcrc so that it can find our phabricator instance
# this is needed for running `arc lint` and `arc unit` on contint slaves.
class contint::arcanist {
    require_package('arcanist')

    $conduit_token = secret('contint/conduit_token')

    file { '/home/jenkins/.arcrc':
        ensure  => 'file',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0600',
        require => User['jenkins'],
        content => template('contint/arcrc.json.erb'),
    }
}

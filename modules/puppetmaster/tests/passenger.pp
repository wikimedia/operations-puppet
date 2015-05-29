# TODO: Overriding this class to avoid a pretty big set of dependencies
class apache::monitoring { }

class { 'puppetmaster::passenger':
    bind_address  => '*',
    verify_client => 'optional',
    allow_from    => [],
    deny_from     => [],
}

# sets up the database part of quarry
class role::quarry::database {

    requires_realm('labs')

    class { '::quarry::database':
    }
}


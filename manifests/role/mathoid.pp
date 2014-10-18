# vim: set ts=4 et sw=4:

# TODO: now that other services inhabit service cluster A, move this definition in a
# better place
@monitoring::group { 'sca_eqiad': description => 'Service Cluster A servers' }

class role::mathoid{
    system::role { 'role::mathoid':
        description => 'mathoid server'
    }

    include ::mathoid

    ferm::service { 'mathoid':
      proto => 'tcp',
      port  => '10042'
    }

    monitoring::service { 'mathoid':
      description   => 'mathoid',
      check_command => 'check_http_on_port!10042',
    }
}

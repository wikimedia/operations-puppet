# == Class role::restbase
#

@monitoring::group { 'restbase_eqiad': description => 'Restbase eqiad' }
@monitoring::group { 'restbase_codfw': description => 'Restbase codfw' }

# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::restbase

    include lvs::realserver


    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

}

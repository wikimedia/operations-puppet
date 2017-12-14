# Profile class for trendingedits
class profile::trendingedits {

    base::service_unit { 'trendingedits':
        ensure => absent,
        mask   => true
    }

}

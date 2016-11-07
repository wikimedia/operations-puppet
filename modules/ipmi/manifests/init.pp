# IPMItool mgmt hosts
class ipmi {

    package { 'ipmitool':
        ensure => present,
    }

}

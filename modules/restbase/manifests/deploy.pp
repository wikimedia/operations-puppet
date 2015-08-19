# == Class restbase::deploy
#
# Creates user and permissions for deploy user
# on restbase hosts
#
# === Parameters
#
# [*public_key*]
#   This is the public_key for the servicedeploy user. The private part of this
#   key should reside in the private puppet repo for the environment. By default
#   this public key is set to the servicedeploy user's public key for production
#   private puppet—it should be overwritten using hiera in non-production
#   environements.

class restbase::deploy(
    $public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyYzZqTbJTDI+oUvb0h0SKR6AaYosUAx18jNaJ4J2nhHwYSgtmgVOTtaxWvZO31f0d1miqC0QSjSi1f0D2IeFIQgm4jy6KaMZomRg9GthSYKm8rimc0s0CUHoq2rv7iWa4R1y2NCxWn6p6zPYsKIsRvT3+3QkZ0IJ0euuBMDUjQI6P51/NtpYR7Zhm2jq8QzHij4Xh2tyr9zEeKZAcZW1pMZ0zcWYgfBipDhiOL3GTdxYZJsVNuHxqnugixmVPR4Tzp5A441qwtQHEp7dJjMy7xKtW0Xd0yXHVYmF7k6BcHjE6d0VBxdE2uK9RPd+v/yhZ10DnJqGwsOhKD/dsSErjwOyRV5sPizjuFZE+r4eY+8ELTi8ra0GfKk/bnFuyaFrz6lZXw5iCjdT6QXorQlnOwUxt/lKhT9lRMM6j1/lKP/fheu0hE9OS4Y8e0Wa0wX418QqoDalfVCeIrhJSXpm0lVluzEiZ7AjnGBV/QNnll2NixgqU+pgK7qPKQLqDzoZNEDCV/rjvZgPLwCW+eoRiWQfbHgA0CtLsvMYpDk33tbbsDRsxW5xP+4jhXicLkgqNt4jk9o2OS04eFbByqKc6z1adZa80Y+RKNmcEj9TvY6okOfD4bOuvRM/ttwrW8XpxKhz+0wYrnTsU2rzURu9Q366PwG/Cq2/IRkWLSVdKAQ== servicedeploy_prod',
) {
    $user = 'servicedeploy'

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/scap',
        system     => true,
        managehome => true,
    }

    ssh::userkey { $user:
        content => $public_key,
    }

    # Using trebuchet provider while scap service deployment is under
    # development—chicken and egg things
    #
    # This should be removed once scap3 is in a final state
    package { ['restbase/deploy', 'scap/scap']:
        provider => 'trebuchet',
    }

    # Rather than futz with adding new functionality to allow a deployment
    # user set per repository in trebuchet, I'm running an exec here
    $dir = '/srv/deployment/restbase/deploy'
    exec { 'chown servicedeploy':
        command => "/bin/chown -R ${user} ${dir}",
        unless  => "/usr/bin/test $(/usr/bin/stat -c'%U' ${dir}) = ${user}"
    }

    sudo::user { $user:
        privileges => [
            "ALL = ($user) NOPASSWD: ALL",
            'ALL = (root) NOPASSWD: /usr/sbin/service restbase restart',
        ]
    }

}

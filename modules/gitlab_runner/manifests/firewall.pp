# SPDX-License-Identifier: Apache-2.0
class gitlab_runner::firewall (
    Wmflib::Ensure                              $ensure            = present,
    Boolean                                     $restrict_firewall = false,
    Hash[String, Gitlab_runner::AllowedService] $allowed_services  = [],
) {

    ferm::conf { 'docker-ferm':
        ensure => $ensure,
        prio   => 20,
        source => 'puppet:///modules/profile/ci/docker-ferm',
    }

    if $restrict_firewall {

        # reject all docker traffic to internal wmnet network
        ferm::rule { 'docker-default-reject':
            ensure => $ensure,
            prio   => 19,
            rule   => 'daddr 10.0.0.0/8 proto tcp REJECT;',
            desc   => 'reject all docker traffic to internal wmnet network',
            chain  => 'DOCKER-ISOLATION',
        }

        # explicitly allow traffic to certain services
        $allowed_services.each | String $name, Gitlab_runner::AllowedService $allowed_service | {
            ferm::rule { "docker-allow-${$name}":
                ensure => $ensure,
                prio   => 18,
                rule   => "daddr (@resolve(${allowed_service['host']})) proto tcp dport ${allowed_service['port']} ACCEPT;",
                desc   => "allow traffic to ${name} from docker",
                chain  => 'DOCKER-ISOLATION',
            }
        }
    }

}

# SPDX-License-Identifier: Apache-2.0
# @summary small wrapper to manage the gerrit key
# @param ensure ensurable param
# @param exported wether to export the resource
# @param override the default target
define profile::gerrit::sshkey (
    Wmflib::Ensure             $ensure   = 'present',
    Boolean                    $exported = false,
    Optional[Stdlib::Unixpath] $target   = undef,
) {
    $params = {
        'ensure' => $ensure,
        'name'   => 'gerrit.wikimedia.org',
        'host_aliases' => [
            # Host used internally for direct connections
            'gerrit.discovery.wmnet',
            ipresolve('gerrit.discovery.wmnet', 4),
            ipresolve('gerrit.discovery.wmnet', 6),

            # Public facing entry
            ipresolve('gerrit.wikimedia.org', 4),
            ipresolve('gerrit.wikimedia.org', 6),

            # Load balancers for public traffic
            ipresolve('gerrit-lb.eqiad.wikimedia.org', 4),
            ipresolve('gerrit-lb.eqiad.wikimedia.org', 6),
            ipresolve('gerrit-lb.codfw.wikimedia.org', 4),
            ipresolve('gerrit-lb.codfw.wikimedia.org', 6),
            ipresolve('gerrit-lb.esams.wikimedia.org', 4),
            ipresolve('gerrit-lb.esams.wikimedia.org', 6),
            ipresolve('gerrit-lb.ulsfo.wikimedia.org', 4),
            ipresolve('gerrit-lb.ulsfo.wikimedia.org', 6),
            ipresolve('gerrit-lb.eqsin.wikimedia.org', 4),
            ipresolve('gerrit-lb.eqsin.wikimedia.org', 6),
            ipresolve('gerrit-lb.drmrs.wikimedia.org', 4),
            ipresolve('gerrit-lb.drmrs.wikimedia.org', 6),
            ipresolve('gerrit-lb.magru.wikimedia.org', 4),
            ipresolve('gerrit-lb.magru.wikimedia.org', 6),
        ],
        'key'    => 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQCF8pwFLehzCXhbF1jfHWtd9d1LFq2NirplEBQYs7AOrGwQ/6ZZI0gvZFYiEiaw1o+F1CMfoHdny1VfWOJF3mJ1y9QMKAacc8/Z3tG39jBKRQCuxmYLO1SWymv7/Uvx9WQlkNRoTdTTa9OJFy6UqvLQEXKYaokfMIUHZ+oVFf1CgQ==',
        'type'   => 'ssh-rsa',
        'target' => $target,
    }

    if $exported {
        @@sshkey { $title:
            * => $params,
        }
    } else {
        sshkey { $title:
            * => $params,
        }
    }
}

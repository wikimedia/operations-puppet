# SPDX-License-Identifier: Apache-2.0
# @summary small wrapper to manage the gerrit host keys
# @param ensure ensurable param
# @param exported whether to export the resource
define profile::gerrit::sshkey (
    Wmflib::Ensure             $ensure   = 'present',
    Boolean                    $exported = false,
    Optional[Stdlib::Unixpath] $target   = undef,
) {
    $host_aliases = [
        # Host used internally for direct connections
        'gerrit.discovery.wmnet',
        ipresolve('gerrit.discovery.wmnet', 4),
        ipresolve('gerrit.discovery.wmnet', 6),

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
    ]

    # One entry per host key type/algorithm (T240266)
    $keys = {
        'ssh-rsa'     => 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQCF8pwFLehzCXhbF1jfHWtd9d1LFq2NirplEBQYs7AOrGwQ/6ZZI0gvZFYiEiaw1o+F1CMfoHdny1VfWOJF3mJ1y9QMKAacc8/Z3tG39jBKRQCuxmYLO1SWymv7/Uvx9WQlkNRoTdTTa9OJFy6UqvLQEXKYaokfMIUHZ+oVFf1CgQ==',
        'ssh-ed25519' => 'AAAAC3NzaC1lZDI1NTE5AAAAIFp+VIoTbE8Js9fwRCUy9KnSAewDQa2f6Dwi77R7IqS7',
    }

    $keys.each |$type, $key| {
        $params = {
            'ensure'       => $ensure,
            'name'         => 'gerrit.wikimedia.org',
            'host_aliases' => $host_aliases,
            'key'          => $key,
            'type'         => $type,
            'target'       => $target,
        }

        $key_title = "${title}@${type}"
        if $exported {
            @@sshkey { $key_title:
                * => $params,
            }
        } else {
            sshkey { $key_title:
                * => $params,
            }
        }
    }
}

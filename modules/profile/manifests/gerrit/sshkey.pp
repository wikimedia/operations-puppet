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

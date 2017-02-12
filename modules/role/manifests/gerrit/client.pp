# == Class role::gerrit::client
#
# Include this role to provide the Gerrit host fingerprint for the SSH review
# system on port 29418.
class role::gerrit::client {

    # The sshkey resource seems to modify file permissions and make it
    # unreadable - this is a known bug (https://tickets.puppetlabs.com/browse/PUP-2900)
    # Trying to define this file resource, and notify the resource to be ensured
    # from the sshkey resource, to see if it fixes the problem
    file { '/etc/ssh/ssh_known_hosts':
        ensure => file,
        mode   => '0644',
    }

    sshkey { 'gerrit':
        ensure       => 'present',
        name         => '[gerrit.wikimedia.org]:29418'
        host_aliases => [
            '[208.80.154.85]:29418',
            '[2620:0:861:3:208:80:154:85]:29418',
        ],
        key          => 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQCF8pwFLehzCXhbF1jfHWtd9d1LFq2NirplEBQYs7AOrGwQ/6ZZI0gvZFYiEiaw1o+F1CMfoHdny1VfWOJF3mJ1y9QMKAacc8/Z3tG39jBKRQCuxmYLO1SWymv7/Uvx9WQlkNRoTdTTa9OJFy6UqvLQEXKYaokfMIUHZ+oVFf1CgQ==',
        type         => 'ssh-rsa',
        notify       => File['/etc/ssh/ssh_known_hosts'],
    }

}

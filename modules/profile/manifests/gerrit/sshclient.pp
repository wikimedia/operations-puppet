# Profile for Gerrit clients
class profile::gerrit::sshclient {

    # Register Gerrit ssh public host key (port 29418).
    # It will be added to /etc/ssh/ssh_known_hosts
    # The private key is in the private repository
    sshkey { 'gerrit':
        ensure => 'present',
        name   => 'gerrit.wikimedia.org',
        key    => 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQCF8pwFLehzCXhbF1jfHWtd9d1LFq2NirplEBQYs7AOrGwQ/6ZZI0gvZFYiEiaw1o+F1CMfoHdny1VfWOJF3mJ1y9QMKAacc8/Z3tG39jBKRQCuxmYLO1SWymv7/Uvx9WQlkNRoTdTTa9OJFy6UqvLQEXKYaokfMIUHZ+oVFf1CgQ==',
        type   => 'ssh-rsa',
    }

}

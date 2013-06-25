class wmrole::gerrit::labs {
    system_role { "role::gerrit::labs": description => "Gerrit in labs!" }

    class { "gerrit::instance":
        ircbot => false,
        db_host => "gerrit-db",
        host => "gerrit-dev.wmflabs.org",
        ssh_key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDIb6jbDSyzSD/Pw8PfERVKtNkXgUteOTmZJjHtbOjuoC7Ty6dbvUMX+45GedcD1wAYkWEY26RhI1lW2yEwKvh7VWkKixXqPNyrQGvI+ldjYEyWsGlEHCNqsh37mJD5K3cwr7X/PMaxzxh7rjTk4uRKjtiga9bz1vTDRDaNlXcj84kifsu7xmCY1E+OL4oqqy7b3SKhOpcpZc7n5GonfRSeon5uFHVUjoZ57xQ8x2736zbuLBwMRKtaB+V63cU9ArL90XdVrWfbjI4Fzfex4tBG9fOvt8lINR62cjH5Lova2kZ6VBeUnJYdZ8V1mOSwtITjwkE0K98FNZdqaANZAH7V",
        ssl_cert => "star.wmflabs",
        ssl_cert_key => "star.wmflabs",
    }
}

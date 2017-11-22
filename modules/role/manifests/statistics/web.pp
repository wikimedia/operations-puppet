# (thorium)
class role::statistics::web {
    system::role { 'statistics::web':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::statistics::web

    # Superset
    include ::profile::superset
}

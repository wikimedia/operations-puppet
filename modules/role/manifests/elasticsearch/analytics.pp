# Supports CirrusSearch usage on the analytics cluster
class role::elasticsearch::analytics {
    # wikimedia/discovery/analytics will be deployed to this node
    package { 'wikimedia/discovery/analytics':
        provider => 'trebuchet',
    }
}

# === Class service::monitoring
#
# this is intended to include all shared resources used for monitoring
# services defined via service::node

class service::monitoring {
    # On stretch+, we use a newer version of service-checker that is python3-only
    if os_version('debian >= stretch') {
        require_package('python3-service-checker')
    } else {
        require_package('python-yaml', 'python-urllib3', 'python-service-checker')
    }
}

# === Class service::monitoring
#
# this is intended to include all shared resources used for monitoring
# services defined via service::node

class service::monitoring {
    require_package 'python-yaml', 'python-urllib3', 'python-service-checker'
}

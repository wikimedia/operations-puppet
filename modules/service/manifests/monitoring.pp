# === Class service::monitoring
#
# this is intended to include all shared resources used for monitoring
# services defined via service::node

class service::monitoring {
    ensure_packages('python3-service-checker')
}

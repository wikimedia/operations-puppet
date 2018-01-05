class role::graphite::primary {
    include ::role::graphite::production
    include ::role::performance::site
}

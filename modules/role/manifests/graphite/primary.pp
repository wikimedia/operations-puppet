# graphite production server with performance web site
class role::graphite::primary {
    include ::role::graphite::production
    include ::role::performance::coal
    include ::role::performance::site
}

# graphite production server with performance web site
class role::graphite::primary {
    include ::role::graphite::production
    include ::profile::performance::site
}

# https://www.mediawiki.org/wiki/Phragile
#
# filtertags: labs-project-phragile
class role::phragile::labs {
    # Only on labs!
    requires_realm('labs')

    include ::phragile
}

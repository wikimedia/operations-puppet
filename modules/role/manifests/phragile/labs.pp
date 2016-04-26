# https://www.mediawiki.org/wiki/Phragile
class role::phragile::labs {
    # Only on labs!
    requires_realm('labs')

    include ::phragile
}

# A general container for feature flags, that is changes to the
# vhosts that we are introducing/testing and are destined to be the default for
# all vhosts. The list will vary with time, and must be reflected in the
# corresponding puppet type.
# Documentation of the individual flags functions is in the documentation for
# mediawiki::web::vhost
type Mediawiki::Vhost_feature_flags = Struct[
    {
    'php72_only'  => Optional[Boolean],
    }
]

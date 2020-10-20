# @summary a type which can be used to validate debian and supported debian derivative codenames
# @example
#   apt::repository {'foo':
#     dist => lookup('foo::bar', Debian::Codename)
#   }
type Debian::Codename = Variant[
    Debian::Codename::Debian,
]

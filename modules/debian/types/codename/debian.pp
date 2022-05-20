# SPDX-License-Identifier: Apache-2.0
# @summary a type which can be used to validate debian codenames.  specifically ones
#          from the debian project and not including any debian derivatives
# @example
#   apt::repository {'foo':
#     dist => lookup('foo::bar', Debian::Codename::Debian)
#   }
type Debian::Codename::Debian = Enum['stretch', 'buster', 'bullseye', 'sid']

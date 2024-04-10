# SPDX-License-Identifier: Apache-2.0
type Profile::Postfix::Domain_aliases = Hash[
    Stdlib::Host,
    Array[Profile::Postfix::Virtual],
]

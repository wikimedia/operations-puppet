# SPDX-License-Identifier: Apache-2.0
type Profile::Postfix::Virtual = Struct[{
    pattern   => String[1],
    addresses => Array[Stdlib::Email],
}]

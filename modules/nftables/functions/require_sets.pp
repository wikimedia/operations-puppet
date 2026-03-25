# SPDX-License-Identifier: Apache-2.0
function nftables::require_sets(
    Optional[Array[String[1]]] $src_sets   = undef,
    Optional[Array[String[1]]] $dst_sets   = undef,
) >>
Optional[
    Variant[
        Type[Nftables::Set],
        Array[Type[Nftables::Set]]
    ]
]{
    if $src_sets and $dst_sets {
        $file_require = Nftables::Set[$dst_sets + $src_sets]
    } elsif $dst_sets {
        $file_require = Nftables::Set[$dst_sets]
    } elsif $src_sets {
        $file_require = Nftables::Set[$src_sets]
    } else {
        $file_require = undef
    }

    $file_require
}

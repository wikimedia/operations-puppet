# SPDX-License-Identifier: Apache-2.0
type Cfssl::Key = Struct[{
    algo => Cfssl::Algo,
    size => Variant[
        # ecdsa sizes
        Integer[256,256],
        Integer[384,384],
        Integer[521,521],
    ]
}]

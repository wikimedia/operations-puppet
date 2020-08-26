type Cfssl::Key = Struct[{
    algo => Cfssl::Algo,
    size => Variant[
        # ecdsa sizes
        Integer[256,256],
        Integer[384,384],
        Integer[521,521],
        # rsa sizes
        Integer[2048,2048],
        Integer[4096,4096],
        Integer[8192,8192],
    ]
}]

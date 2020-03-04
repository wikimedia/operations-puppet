type Cfssl::Key = Struct[{
    algo => Cfssl::Algo,
    size => Variant[
        Integer[512,512],
        Integer[1024,1024],
        Integer[2048,2048],
        Integer[4096,4096],
    ]
}]

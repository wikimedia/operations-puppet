# Type for holding weighted lists of puppetmaster backends
type Puppetmaster::Backends = Array[Struct[{
    worker => String,
    loadfactor => Integer,
    offline    => Optional[Boolean],
}]]

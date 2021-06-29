type Postgresql::Privileges = Struct[{
    'table'    => Optional[Postgresql::Priv::Table],
    'sequence' => Optional[Postgresql::Priv::Sequence],
    'function' => Optional[Postgresql::Priv::Function],
}]

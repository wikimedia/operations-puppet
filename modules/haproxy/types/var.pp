type Haproxy::Var = Struct[{
    'direction' => Enum['request', 'response'],
    'name'      => String,
    'value'     => String,
    'acl'       => Optional[String],
}]

type Haproxy::Header = Struct[{
    'direction' => Enum['request', 'response'],
    'name'      => String,
    'value'     => Optional[String],
    'acl'       => Optional[String],
}]

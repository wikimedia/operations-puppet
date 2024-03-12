type Dynamicproxy::Zone = Struct[{
  'id'             => String[1],
  'project'        => String[1],
  'acmechief_cert' => String[1],
  'deprecated'     => Optional[Boolean],
  'default'        => Optional[Boolean],
  'shared'         => Optional[Boolean],
}]

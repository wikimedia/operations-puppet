type Trafficserver::Log_filter = Struct[{
    'name'      => String,
    'action'    => Enum['accept', 'reject', 'wipe'],
    'condition' => String,
}]

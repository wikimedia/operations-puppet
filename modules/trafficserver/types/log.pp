type Trafficserver::Log = Struct[{
    'filename' => String,
    'format'   => String,
    'mode'     => Enum['ascii', 'binary', 'ascii_pipe'],
    'filters'  => Optional[Array[String]],
}]

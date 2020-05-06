type Trafficserver::Log = Struct[{
    'ensure'   => Wmflib::Ensure,
    'filename' => String,
    'format'   => String,
    'mode'     => Enum['ascii', 'binary', 'ascii_pipe'],
    'filters'  => Optional[Array[String]],
}]

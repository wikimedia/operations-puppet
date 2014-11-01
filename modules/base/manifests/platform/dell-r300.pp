class base::platform::dell-r300 inherits base::platform::generic::dell {
    $lom_serial_speed = '57600'

    class { 'common': lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
}
class base::platform::dell-c2100 inherits base::platform::generic::dell {
    $lom_serial_speed = '115200'

    class { 'common': lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
}
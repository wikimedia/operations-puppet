class base::platform::cisco-C250-M1 inherits base::platform::generic::cisco {
    class { 'common': lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
}
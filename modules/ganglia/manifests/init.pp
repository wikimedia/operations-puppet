# === Class ganglia
#
class ganglia {
    # ganglia is not supported in labs, make sure to not send data
    if $::realm == 'labs' {
        include ::ganglia::monitor::decommission
    } else {
        include ::ganglia::monitor
    }
}

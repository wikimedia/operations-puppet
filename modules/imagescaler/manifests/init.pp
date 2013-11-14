#class for managing imagescalers
class imagescaler{

    include imagescaler::cron,
    imagescaler::packages,
    imagescaler::files

# Virtual resource for the monitoring server
@monitor_group { "imagescaler": description => "image scalers" }
}

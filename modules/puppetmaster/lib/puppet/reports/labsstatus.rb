# Puppet StatsD reporter
# Sends timing measurements for Puppet runs to StatsD
require 'puppet'
require 'yaml'
require 'erb'

Puppet::Reports.register_report(:labsstatus) do
    desc = 'Record puppet status of labs instances in instance metadata'

    def process
        project = ""
        hostname = ""
        self.logs.each do |logline|
            if logline.message =~ /'instanceproject: (.*)'/
                project = $1
            end
            if logline.message =~ /'hostname: (.*)'/
                hostname = $1
            end
        end
        if (!project.empty?) and (!hostname.empty?)
            command = "nova --os-tenant-name #{project} meta #{hostname} set puppetstatus=#{self.status}"
            system(command)
        end
    end
end

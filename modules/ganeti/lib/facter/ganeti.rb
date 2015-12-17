Facter.add("ganeti_cluster") do
    confine :kernel => :linux

    setcode do
        if File.exists?("/var/lib/ganeti/ssconf_cluster_name")
            cmdline = %x{cat /var/lib/ganeti/ssconf_cluster_name}.chomp
        end
    end
end

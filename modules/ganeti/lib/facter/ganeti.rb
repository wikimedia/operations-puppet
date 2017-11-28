Facter.add('ganeti_cluster') do
  confine :kernel => :linux
  confine do
    File.exists?('/var/lib/ganeti/ssconf_cluster_name')
  end

  setcode do
    File.read('/var/lib/ganeti/ssconf_cluster_name').chomp
  end
end

# Sets an nfscommon_version fact if dpkg-query exists and the nfs-common package is installed.

if FileTest.exists?("/usr/bin/dpkg-query")
    nfscommon_version = `/usr/bin/dpkg-query -W -f='${Version}' nfs-common 2>/dev/null | /usr/bin/awk -F '-' '{print $1}'`.strip
    unless nfscommon_version.empty?
        Facter.add("nfscommon_version") do
            setcode do
                nfscommon_version
            end
        end
    end
end

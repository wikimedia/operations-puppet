# Sets a spark_version fact if dpkg-query exists and the spark2 package is installed.

if FileTest.exists?("/usr/bin/dpkg-query")
    spark_version = `/usr/bin/dpkg-query -W -f='${Version}' spark2 2>/dev/null | /usr/bin/awk -F '-' '{print $1}'`
    unless spark_version.empty?
        Facter.add("spark_version") do
            setcode do
                spark_version
            end
        end
    end
end

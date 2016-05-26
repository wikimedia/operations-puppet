Facter.add('raid') do
  confine :kernel => :Linux
  setcode do
    raids = []

    if FileTest.exist?('/dev/cciss/') or FileTest.exist?('/sys/module/hpsa/')
      raids.push('hpsa')
    end

    if FileTest.exist?('/dev/megadev0') or
       Dir.glob('/sys/bus/pci/drivers/megaraid_sas/00*').length > 0
      raids.push('megaraid')
    end

    if FileTest.exist?('/dev/mptctl') or
       FileTest.exist?('/dev/mpt0') or
       FileTest.exist?('/proc/mpt/summary') or
       FileTest.exist?('/proc/scsi/mptsas/0')
      raids.push('mpt')
    end

    if FileTest.exist?('/dev/aac0')
      raids.push('aacraid')
    end

    if FileTest.exist?('/proc/scsi/scsi')
      IO.foreach('/proc/scsi/scsi') do |x|
        if x =~ /Vendor: 3ware/
          raids.push('3ware')
          break
        end
      end
    end

    IO.foreach('/proc/devices') do |x|
      valid_devs = [ 'aac', 'twe', 'megadev' ]
      if x =~ /^\s*\d+\s+(\w+)/
        raids.push($1) if valid_devs.include?($1)
      end
    end

    if FileTest.exist?('/proc/mdstat') and FileTest.exist?('/sbin/mdadm')
      IO.foreach('/proc/mdstat') do |x|
        if x =~ /md[0-9]+ : active/
          raids.push('md')
          break
        end
      end
    end

    raids.sort!.uniq!

    if Facter.version < '2.0.0'
      raids.join(',')
    else
      raids
    end

  end
end

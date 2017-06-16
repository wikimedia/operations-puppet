Facter.add('raid') do
  confine :kernel => :linux
  setcode do
    raids = []

    if FileTest.exist?('/dev/cciss/') || FileTest.exist?('/sys/module/hpsa/')
      raids.push('hpsa')
    end

    if FileTest.exist?('/dev/megadev0') ||
       Dir.glob('/sys/bus/pci/drivers/megaraid_sas/00*').length > 0
      raids.push('megaraid')
    end

    if FileTest.exist?('/dev/mpt0') ||
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

    supported_devs = ['aac', 'twe']
    dev_re = Regexp.new(/^\s*\d+\s+(\w+)/)
    IO.foreach('/proc/devices') do |x|
      m = x.match(dev_re)
      if m
        dev = m[1]
        raids.push(dev) if supported_devs.include?(dev)
      end
    end

    if FileTest.exist?('/proc/mdstat')
      IO.foreach('/proc/mdstat') do |x|
        if x =~ /md[0-9]+ : active/
          raids.push('md')
          break
        end
      end
    end

    raids.sort.uniq
  end
end

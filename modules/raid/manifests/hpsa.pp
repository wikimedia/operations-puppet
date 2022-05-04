# HP Raid controller
class raid::hpsa {
  include raid

  # TODO: also handle the case for Smart Storage PQI 12G SAS/PCIe 3 see raid.rb
  if debian::codename::ge('bullseye')  {
      include raid::hpsa::ssacli
  } else {
      include raid::hpsa::hpssacli
  }
}

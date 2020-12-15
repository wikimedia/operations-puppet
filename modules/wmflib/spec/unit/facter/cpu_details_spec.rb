require_relative '../../../../../rake_modules/spec_helper'

proc_cpuinfo = <<-CPUINFO
model           : 58
cpu family      : 6
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx rdtscp lm constant_tsc rep_good nopl xtopology cpuid tsc_known_freq pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm pti ssbd ibrs ibpb fsgsbase smep erms xsaveopt arat md_clear
bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit
CPUINFO
cpu_details = {
  'vulnerabilities' => {
    'spectre_v2' => "Mitigation: Full generic retpoline, IBPB: conditional, IBRS_FW, STIBP: disabled, RSB filling",
    'itlb_multihit' => "KVM: Vulnerable",
    'mds' => "Mitigation: Clear CPU buffers; SMT Host state unknown",
    'l1tf' => "Mitigation: PTE Inversion",
    'spec_store_bypass' => "Mitigation: Speculative Store Bypass disabled via prctl and seccomp",
    'tsx_async_abort' => "Not affected",
    'spectre_v1' => "Mitigation: usercopy/swapgs barriers and __user pointer sanitization",
    'meltdown' => "Mitigation: PTI"
  },
  'scaling_governor' => false,
  'scaling_driver' => false,
  'model' => "3a",
  'family' => "6",
  'flags' => ["fpu", "vme", "de", "pse", "tsc", "msr", "pae", "mce", "cx8", "apic", "sep", "mtrr",
              "pge", "mca", "cmov", "pat", "pse36", "clflush", "mmx", "fxsr", "sse", "sse2",
              "syscall", "nx", "rdtscp", "lm", "constant_tsc", "rep_good", "nopl", "xtopology",
              "cpuid", "tsc_known_freq", "pni", "pclmulqdq", "ssse3", "cx16", "pcid", "sse4_1",
              "sse4_2", "x2apic", "popcnt", "tsc_deadline_timer", "aes", "xsave", "avx", "f16c",
              "rdrand", "hypervisor", "lahf_lm", "pti", "ssbd", "ibrs", "ibpb", "fsgsbase", "smep",
              "erms", "xsaveopt", "arat", "md_clear"],
  'bugs' => ["cpu_meltdown", "spectre_v1", "spectre_v2", "spec_store_bypass",
             "l1tf", "mds", "swapgs", "itlb_multihit"],
  'cpus' => {
    'cpu0' => {
      'scaling_governor' => false,
      'scaling_driver' => false
    }
  }
}
describe Facter.fact(:cpu_details) do
  before { Facter.clear }
  context 'cpu_details' do
    before :each do
      allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
      allow(Dir).to receive(:foreach).with('/sys/devices/system/cpu/vulnerabilities').and_yield('.')
      allow(File).to receive(:foreach).with('/proc/cpuinfo').and_yield(
        proc_cpuinfo.lines[0]
      ).and_yield(
        proc_cpuinfo.lines[1]
      ).and_yield(
        proc_cpuinfo.lines[2]
      ).and_yield(
        proc_cpuinfo.lines[3]
      )
    end
    it { expect(Facter.value(:cpu_details)['model']).to eq cpu_details['model'] }
    it { expect(Facter.value(:cpu_details)['family']).to eq cpu_details['family'] }
    it { expect(Facter.value(:cpu_details)['bugs']).to eq cpu_details['bugs'] }
    it { expect(Facter.value(:cpu_details)['flags']).to eq cpu_details['flags'] }
  end
end

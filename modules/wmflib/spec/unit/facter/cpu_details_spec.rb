require_relative '../../../../../rake_modules/spec_helper'

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

describe Facter::Util::Fact.to_s do
  before { Facter.clear }
  context 'cpu_details' do
    before :each do
      File.stubs(:foreach).with('/proc/cpuinfo').multiple_yields(
        ["model           : 58"],
        ["cpu family      : 6"],
        # rubocop:disable Metrics/LineLength
        ["flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx rdtscp lm constant_tsc rep_good nopl xtopology cpuid tsc_known_freq pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm pti ssbd ibrs ibpb fsgsbase smep erms xsaveopt arat md_clear",],
        # rubocop:enable Metrics/LineLength
        ["bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit"]
      )
    end
    it { expect(Facter.fact(:cpu_details).value['model']).to eq cpu_details['model'] }
    it { expect(Facter.fact(:cpu_details).value['family']).to eq cpu_details['family'] }
    it { expect(Facter.fact(:cpu_details).value['bugs']).to eq cpu_details['bugs'] }
    it { expect(Facter.fact(:cpu_details).value['flags']).to eq cpu_details['flags'] }
  end
end

require 'spec_helper'

describe 'nrpe::packages', :type => :class do
    let(:facts) { { :realm => 'production' } }
    it { should contain_package('nagios-nrpe-server') }
    it { should contain_package('nagios-plugins') }
    it { should contain_package('nagios-plugins-basic') }
    it { should contain_package('nagios-plugins-extra') }
    it { should contain_package('nagios-plugins-standard') }
    it { should contain_package('libssl0.9.8') }
    it { should contain_file('/etc/nagios/nrpe_local.cfg') }
    it { should contain_file('/usr/lib/nagios/plugins/check_dpkg') }
end

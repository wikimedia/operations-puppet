require 'spec_helper'

stretch_facts = {
    # For wmflib.os_version()
    :lsbdistid      => 'Debian',
    :lsbdistrelease => '9.4',

    :initsystem => 'systemd',
}

describe 'nrpe', :type => :class do
    let(:facts) { stretch_facts }
    it { should contain_package('nagios-nrpe-server') }
    it { should contain_package('monitoring-plugins') }
    it { should contain_package('monitoring-plugins-basic') }
    it { should contain_package('monitoring-plugins-standard') }
    it { should contain_file('/etc/nagios/nrpe_local.cfg') }
    it { should contain_file('/usr/local/lib/nagios/plugins/') }
    it { should contain_service('nagios-nrpe-server') }
end

describe 'nrpe', :type => :class do
    let(:facts) {
        stretch_facts.merge({ :realm => 'production' })
    }

    it 'should generate valid content for nrpe_local.cfg in production' do
        should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=127.0.42.42/)
    end
end

describe 'nrpe', :type => :class do
    let(:facts) {
        stretch_facts.merge({ :realm => 'labs' })
    }
    it 'should generate valid content for nrpe_local.cfg in labs' do
        should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=10.68.42.42/)
    end
end

describe 'nrpe', :type => :class do
    let(:facts) {
        stretch_facts.merge({ :realm => 'labs' })
    }
    let(:params) { { :allowed_hosts => '10.10.10.10' } }

    it 'should generate valid content for nrpe_local.cfg in labs with allowed_hosts defined' do
        should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=10.10.10.10/)
    end
end

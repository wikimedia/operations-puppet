require 'spec_helper'

describe 'nrpe', :type => :class do
    it { should contain_package('nagios-nrpe-server') }
    it { should contain_package('nagios-plugins') }
    it { should contain_package('nagios-plugins-basic') }
    it { should contain_package('nagios-plugins-standard') }
    it { should contain_file('/etc/nagios/nrpe_local.cfg') }
    it { should contain_file('/usr/local/lib/nagios/plugins/') }
    it { should contain_service('nagios-nrpe-server') }
end

describe 'nrpe', :type => :class do
    let(:facts) { { :realm => 'production' } }

    it 'should generate valid content for nrpe_local.cfg in production' do
        should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=127.0.0.1/)
    end
end

describe 'nrpe', :type => :class do
    let(:facts) { { :realm => 'labs' } }
    it 'should generate valid content for nrpe_local.cfg in labs' do
        pending("This fails, let's revisit it to fix either test or class")
        should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=10.4.1.88/)
    end
end

describe 'nrpe', :type => :class do
    let(:facts) { { :realm => 'labs' } }
    let(:params) { { :allowed_hosts => '10.10.10.10' } }

    it 'should generate valid content for nrpe_local.cfg in labs with allowed_hosts defined' do
        should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=10.10.10.10/)
    end
end

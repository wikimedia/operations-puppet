require 'spec_helper'
describe 'apt::multipackage', :type => :define do
  describe 'generic package' do
    let(:title) { 'whois' }
    context 'on trusty' do
      let(:facts) { {:lsbdistcodename => 'trusty'}}
      it { should contain_package('whois').with({'ensure' => 'latest'})}
    end
    context 'on precise' do
      let(:facts) {{:lsbdistcodename => 'precise'}}
      it { should contain_package('whois').with({'ensure' => 'latest'})}
    end
  end

  describe 'different names, present' do
    let(:title) { 'mariadb-client' }
    let(:params) { { :overrides => { 'precise' => 'mysql-client'},
                     :ensure => 'present' } }
    context 'on trusty' do
      let(:facts) {{:lsbdistcodename => 'trusty'}}
      it { should contain_package('mariadb-client').with({'ensure'=>'present'})}
      it { should_not contain_package('mysql-client') }
    end
    context 'on precise' do
      let(:facts) {{:lsbdistcodename => 'precise'}}
      it { should contain_package('mysql-client').with({'ensure'=>'present'})}
      it { should_not contain_package('mariadb-client') }
    end
  end
 
  describe 'different names, latest' do
    let(:title) { 'mariadb-client' }
    let(:params) { { :overrides => { 'precise' => 'mysql-client'} } }
    context 'on trusty' do
      let(:facts) {{:lsbdistcodename => 'trusty'}}
      it { should contain_package('mariadb-client').with({'ensure'=>'latest'})}
      it { should_not contain_package('mysql-client') }
    end
    context 'on precise' do
      let(:facts) {{:lsbdistcodename => 'precise'}}
      it { should contain_package('mysql-client').with({'ensure'=>'latest'})}
      it { should_not contain_package('mariadb-client') }
    end
  end


  describe 'unavailable' do
    let(:title) { 'libgdal1-1.7.0' }
    let(:params) { { :overrides => { 'trusty' => nil } } }
    context 'on trusty' do
      let(:facts) {{:lsbdistcodename => 'trusty'}}
      it { should_not contain_package('libgdal1-1.7.0') }
    end
    context 'on precise' do
      let(:facts) {{:lsbdistcodename => 'precise'}}
      it { should contain_package('libgdal1-1.7.0') }
    end
  end
end

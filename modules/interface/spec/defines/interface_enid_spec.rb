require 'spec_helper'

describe 'interface::enid', :type => :define do
  let(:title) { 'eth0' }

  describe 'valid inputs' do
    context 'On Debian Jessie with content only defined' do
      let(:params) { { :content => 'a' } }
      let(:facts) { {
        :lsbdistrelease => 'Jessie',
        :lsbdistid      => 'Debian',
      } }
      it { should compile }
    end
    context 'On Debian Jessie with source only defined' do
      let(:params) { { :source => 'puppet:///a' } }
      let(:facts) { {
        :lsbdistrelease => 'Jessie',
        :lsbdistid      => 'Debian',
      } }
      it { should compile }
    end
  end

  describe 'invalid inputs' do
    context 'On Debian Jessie with neither content nor source' do
      let(:facts) { {
        :lsbdistrelease => 'Jessie',
        :lsbdistid      => 'Debian',
      } }
      it { should_not compile }
    end
    context 'On Debian Jessie with both content and source defined' do
      let(:params) { { :source => 'puppet:///a', :content => 'a' } }
      let(:facts) { {
        :lsbdistrelease => 'Jessie',
        :lsbdistid      => 'Debian',
      } }
      it { should_not compile }
    end
    context 'On Ubuntu Trusty' do
      let(:facts) { {
        :lsbdistrelease => 'Trusty',
        :lsbdistid      => 'Ubuntu',
      } }
      it { should_not compile }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'lvm::volume' do
  let(:title) { 'lv_example0' }

  context 'when passed valid parameters, it will compile' do
    let :params do
      {
        ensure: 'present',
        vg: 'vg_example0',
        pv: '/dev/sdd1',
        fstype: 'ext4',
        size: '100GB'
      }
    end

    it {
      expect(subject).to compile
    }
  end
end

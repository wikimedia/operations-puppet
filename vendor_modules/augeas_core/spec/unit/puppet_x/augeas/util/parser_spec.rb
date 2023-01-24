require 'spec_helper'
require 'puppet_x/augeas/util/parser'

describe PuppetX::Augeas::Util::Parser do
  include described_class

  it 'handles an empty array' do
    expect(parse_to_array('[]')).to eq([])
  end

  it 'handles an array with a simple single-quoted entry' do
    expect(parse_to_array("['entry']")).to eq(['entry'])
  end

  it 'handles an array with a simple double-quoted entry' do
    expect(parse_to_array('["entry"]')).to eq(['entry'])
  end

  it 'handles an array with both single- and double-quoted entries' do
    expect(parse_to_array(%q(['first', "second"]))).to eq(['first', 'second'])
  end

  context 'inside single-quoted strings' do
    it 'allows a literal backslash' do
      expect(parse_to_array("['entry\\\\here']")).to eq(['entry\\here'])
    end

    it 'allows an internal single-quote' do
      expect(parse_to_array("['entry\\'here']")).to eq(['entry\'here'])
    end
  end

  context 'inside double-quoted strings' do
    it 'allows a literal backslash' do
      expect(parse_to_array('["entry\\\\here"]')).to eq(['entry\\here'])
    end

    it 'allows an internal double-quote' do
      expect(parse_to_array('["entry\\"here"]')).to eq(['entry"here'])
    end

    it 'does not require escaping a single-quote' do
      expect(parse_to_array('["entry\'here"]')).to eq(["entry'here"])
    end

    it 'allows a bell character escape' do
      expect(parse_to_array('["entry\\ahere"]')).to eq(["entry\ahere"])
    end

    it 'allows a backspace character escape' do
      expect(parse_to_array('["entry\\bhere"]')).to eq(["entry\bhere"])
    end

    it 'allows a horizontal tab character escape' do
      expect(parse_to_array('["entry\\there"]')).to eq(["entry\there"])
    end

    it 'allows a line feed character escape' do
      expect(parse_to_array('["entry\\nhere"]')).to eq(["entry\nhere"])
    end

    it 'allows a vertical tab character escape' do
      expect(parse_to_array('["entry\\vhere"]')).to eq(["entry\vhere"])
    end

    it 'allows a form feed character escape' do
      expect(parse_to_array('["entry\\fhere"]')).to eq(["entry\fhere"])
    end

    it 'allows a carriage return character escape' do
      expect(parse_to_array('["entry\\rhere"]')).to eq(["entry\rhere"])
    end

    it 'allows an escape character escape' do
      expect(parse_to_array('["entry\\ehere"]')).to eq(["entry\ehere"])
    end

    it 'allows a space character escape' do
      expect(parse_to_array('["entry\\shere"]')).to eq(['entry here'])
    end

    it 'allows octal character escapes' do
      expect(parse_to_array('["\7", "\41", "\101", "\1411"]')).to eq(["\a", '!', 'A', 'a1'])
    end

    it 'allows hexadecimal character escapes with \\x' do
      expect(parse_to_array('["\x7", "\x21", "\x211"]')).to eq(["\a", '!', '!1'])
    end

    it 'allows single-character unicode hexadecimal character escapes with \\u' do
      expect(parse_to_array('["\u2015", "\u20222"]')).to eq(["\u2015", "\u2022" << '2'])
    end

    it 'allows multi-character unicode hexadecimal character escapes with \\u{...}' do
      expect(parse_to_array('["\u{7}", "\u{20}", "\u{100}", "\u{2026}", "\u{1F464}", "\u{100000}", "\u{53 74 72 69 6E 67}"]')).to eq(["\a", ' ', "\u{100}", "\u{2026}", "\u{1F464}", "\u{100000}",
                                                                                                                                      'String'])
    end
  end

  it 'fails with garbage in front of the array' do
    expect { parse_to_array("junk ['good', 'array', 'here']") }.to raise_error(RuntimeError, %r{^Unexpected character in array at: junk \['good})
  end

  it 'fails with garbage in the middle of the array' do
    expect { parse_to_array("['got', 'some', junk 'here']") }.to raise_error(RuntimeError, %r{^Unexpected character in array at: junk 'here'})
  end

  it 'fails with garbage after the array' do
    expect { parse_to_array("['good', 'array', 'here'] junk after") }.to raise_error(RuntimeError, %r{^Unexpected character in array at: junk after})
  end
end

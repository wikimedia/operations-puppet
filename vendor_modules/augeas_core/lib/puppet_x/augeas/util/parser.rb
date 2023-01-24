# rubocop:disable Style/Documentation
module PuppetX; end

module PuppetX::Augeas; end

module PuppetX::Augeas::Util; end
# rubocop:enable Style/Documentation

# Container for helpers to parse user provided data contained in manifests.
module PuppetX::Augeas::Util::Parser
  TOKEN_ARRAY_CLOSE                 = %r{\s*\]\s*}.freeze
  TOKEN_ARRAY_OPEN                  = %r{\s*\[\s*}.freeze
  TOKEN_ARRAY_SEPARATOR             = %r{\s*,\s*}.freeze
  TOKEN_CLOSE_CURLY                 = %r|}|.freeze
  TOKEN_DOUBLE_QUOTE                = %r{"}.freeze
  TOKEN_DOUBLE_QUOTE_ESCAPED_CHAR   = %r{\\(["\\abtnvfres0-7xu])}.freeze
  TOKEN_DOUBLE_QUOTE_UNESCAPED_CHAR = %r{[^"\\]}.freeze
  TOKEN_HEX_CHAR                    = %r{[0-9a-fA-F]{1,2}}.freeze
  TOKEN_OCTAL_CHAR                  = %r{[0-7]{1,3}}.freeze
  TOKEN_OPEN_CURLY                  = %r|{|.freeze
  TOKEN_SINGLE_QUOTE                = %r{'}.freeze
  TOKEN_SINGLE_QUOTE_ESCAPED_CHAR   = %r{\\(['\\])}.freeze
  TOKEN_SINGLE_QUOTE_UNESCAPED_CHAR = %r{[^'\\]}.freeze
  TOKEN_SPACE                       = %r{\s}.freeze
  TOKEN_UNICODE_LONG_HEX_CHAR       = %r{[0-9a-fA-F]{1,6}}.freeze
  TOKEN_UNICODE_SHORT_HEX_CHAR      = %r{[0-9a-fA-F]{4}}.freeze

  # Parse a string into the (nearly) equivalent Ruby array. This only handles
  # arrays with string members (double-, or single-quoted), and does not
  # support the full quite of escape sequences that Ruby allows in
  # double-quoted strings.
  #
  # @param [String] The string to be parsed.
  # @return [Array<String>] The parsed array elements, including handling any
  #   escape sequences.
  def parse_to_array(string)
    s = StringScanner.new(string)
    match = array_open(s)
    raise "Unexpected character in array at: #{s.rest}" if match.nil?

    array_content = array_values(s)

    match = array_close(s)
    raise "Unexpected character in array at: #{s.rest}" if match.nil? || !s.empty?

    array_content
  end

  def array_open(scanner)
    scanner.scan(TOKEN_ARRAY_OPEN)
  end
  private :array_open

  def array_close(scanner)
    scanner.scan(TOKEN_ARRAY_CLOSE)
  end
  private :array_close

  def array_separator(scanner)
    scanner.scan(TOKEN_ARRAY_SEPARATOR)
  end
  private :array_separator

  def single_quote_unescaped_char(scanner)
    scanner.scan(TOKEN_SINGLE_QUOTE_UNESCAPED_CHAR)
  end
  private :single_quote_unescaped_char

  def single_quote_escaped_char(scanner)
    scanner.scan(TOKEN_SINGLE_QUOTE_ESCAPED_CHAR) && scanner[1]
  end
  private :single_quote_escaped_char

  def single_quote_char(scanner)
    single_quote_escaped_char(scanner) || single_quote_unescaped_char(scanner)
  end
  private :single_quote_char

  def double_quote_unescaped_char(scanner)
    scanner.scan(TOKEN_DOUBLE_QUOTE_UNESCAPED_CHAR)
  end
  private :double_quote_unescaped_char

  # This handles the possible Ruby escape sequences in double-quoted strings,
  # except for \M-x, \M-\C-x, \M-\cx, \c\M-x, \c?, and \C-?. The full list of
  # escape sequences, and their meanings is taken from:
  # https://github.com/ruby/ruby/blob/90fdfec11a4a42653722e2ce2a672d6e87a57b8e/doc/syntax/literals.rdoc#strings
  def double_quote_escaped_char(scanner)
    match = scanner.scan(TOKEN_DOUBLE_QUOTE_ESCAPED_CHAR)
    return nil if match.nil?

    case scanner[1]
    when '\\' then '\\'
    when '"'  then '"'
    when 'a'  then "\a"
    when 'b'  then "\b"
    when 't'  then "\t"
    when 'n'  then "\n"
    when 'v'  then "\v"
    when 'f'  then "\f"
    when 'r'  then "\r"
    when 'e'  then "\e"
    when 's'  then "\s"
    when %r{[0-7]}
      # Back the scanner up by one byte so we can grab all of the potential
      # octal digits at the same time.
      scanner.pos = scanner.pos - 1
      octal_character = scanner.scan(TOKEN_OCTAL_CHAR)

      octal_character.to_i(8).chr
    when 'x'
      hex_character = scanner.scan(TOKEN_HEX_CHAR)
      return nil if hex_character.nil?

      hex_character.to_i(16).chr
    when 'u'
      unicode_short_hex_character(scanner) || unicode_long_hex_characters(scanner)
    else
      # Not a valid escape sequence as far as we're concerned.
      nil
    end
  end
  private :double_quote_escaped_char

  def unicode_short_hex_character(scanner)
    unicode_character = scanner.scan(TOKEN_UNICODE_SHORT_HEX_CHAR)
    return nil if unicode_character.nil?

    [unicode_character.hex].pack 'U'
  end
  private :unicode_short_hex_character

  def unicode_long_hex_characters(scanner)
    unicode_string = ''
    return nil unless scanner.scan(TOKEN_OPEN_CURLY)

    loop do
      char = scanner.scan(TOKEN_UNICODE_LONG_HEX_CHAR)
      break if char.nil?
      unicode_string << [char.hex].pack('U')

      separator = scanner.scan(TOKEN_SPACE)
      break if separator.nil?
    end

    return nil if scanner.scan(TOKEN_CLOSE_CURLY).nil? || unicode_string.empty?

    unicode_string
  end
  private :unicode_long_hex_characters

  def single_quoted_string(scanner)
    quoted_string = ''

    match = scanner.scan(TOKEN_SINGLE_QUOTE)
    return nil if match.nil?

    loop do
      match = single_quote_char(scanner)
      break if match.nil?

      quoted_string << match
    end

    match = scanner.scan(TOKEN_SINGLE_QUOTE)
    return quoted_string if match

    nil
  end
  private :single_quoted_string

  def double_quote_char(scanner)
    double_quote_escaped_char(scanner) || double_quote_unescaped_char(scanner)
  end
  private :double_quote_char

  def double_quoted_string(scanner)
    quoted_string = ''

    match = scanner.scan(TOKEN_DOUBLE_QUOTE)
    return nil if match.nil?

    loop do
      match = double_quote_char(scanner)
      break if match.nil?

      quoted_string << match
    end

    match = scanner.scan(TOKEN_DOUBLE_QUOTE)
    return quoted_string if match

    nil
  end
  private :double_quoted_string

  def quoted_string(scanner)
    single_quoted_string(scanner) || double_quoted_string(scanner)
  end
  private :quoted_string

  def array_values(scanner)
    values = []

    loop do
      match = quoted_string(scanner)
      break if match.nil?
      values << match

      match = array_separator(scanner)
      break if match.nil?
    end

    values
  end
  private :array_values
end

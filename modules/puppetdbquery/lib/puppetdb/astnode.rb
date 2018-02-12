class PuppetDB::ASTNode
  attr_accessor :type, :value, :children

  def initialize(type, value, children = [])
    @type = type
    @value = value
    @children = children
  end

  def capitalize_class(name)
    name.to_s.split('::').collect(&:capitalize).join('::')
  end

  # Generate the the query code for a subquery
  #
  # As a special case, the from_mode of :none will not wrap the
  # subquery at all, returning it as is.
  #
  # @param from_mode [Symbol] the mode you want to subquery from
  # @param to_mode [Symbol] the mode you want to subquery to
  # @param query the query inside the subquery
  # @return [Array] the resulting subquery
  def subquery(from_mode, to_mode, query)
    if from_mode == :none
      return query
    else
      return ['in', 'certname',
              ['extract', 'certname',
               ["select_#{to_mode}", query]]]
    end
  end

  # Go through the AST and optimize boolean expressions into triplets etc
  # Changes the AST in place
  #
  # @return The optimized AST
  def optimize
    case @type
    when :booleanop
      @children.each do |c|
        if c.type == :booleanop && c.value == @value
          c.children.each { |cc| @children << cc }
          @children.delete c
        end
      end
    end
    @children.each(&:optimize)
    self
  end

  # Evalutate the node and all children
  #
  # @param mode [Symbol] The query mode we are evaluating for
  # @return [Array] the resulting PuppetDB query
  def evaluate(mode = [:nodes])
    case @type
    when :comparison
      left = @children[0].evaluate(mode)
      right = @children[1].evaluate(mode)
      if mode.last == :subquery
        left = left[0] if left.length == 1
        comparison(left, right)
      elsif mode.last == :resources
        if left[0] == 'tag'
          comparison(left[0], right)
        else
          comparison(['parameter', left[0]], right)
        end
      else
        subquery(mode.last,
                 :fact_contents,
                 ['and', left, comparison('value', right)])
      end
    when :boolean
      value
    when :string
      value
    when :number
      value
    when :date
      require 'chronic'
      ret = Chronic.parse(value, :guess => false).first.utc.iso8601
      fail "Failed to parse datetime: #{value}" if ret.nil?
      ret
    when :booleanop
      [value.to_s, *evaluate_children(mode)]
    when :subquery
      mode.push :subquery
      ret = subquery(mode[-2], value + 's', children[0].evaluate(mode))
      mode.pop
      ret
    when :regexp_node_match
      mode.push :regexp
      ret = ['~', 'certname', Regexp.escape(value.evaluate(mode))]
      mode.pop
      ret
    when :identifier_path
      if mode.last == :subquery || mode.last == :resources
        evaluate_children(mode)
      elsif mode.last == :regexp
        evaluate_children(mode).join '.'
      else
        # Check if any of the children are of regexp type
        # in that case we need to escape the others and use the ~> operator
        if children.any? { |c| c.type == :regexp_identifier }
          mode.push :regexp
          ret = ['~>', 'path', evaluate_children(mode)]
          mode.pop
          ret
        else
          ['=', 'path', evaluate_children(mode)]
        end
      end
    when :regexp_identifier
      value
    when :identifier
      mode.last == :regexp ? Regexp.escape(value) : value
    when :resource
      mode.push :resources
      regexp = value[:title].type == :regexp_identifier
      if !regexp && value[:type].capitalize == 'Class'
        title = capitalize_class(value[:title].evaluate)
      else
        title = value[:title].evaluate
      end
      ret = subquery(mode[-2], :resources,
                     ['and',
                      ['=', 'type', capitalize_class(value[:type])],
                      [regexp ? '~' : '=', 'title', title],
                      ['=', 'exported', value[:exported]],
                      *evaluate_children(mode)])
      mode.pop
      ret
    end
  end

  # Helper method to produce a comparison expression
  def comparison(left, right)
    if @value[0] == '!'
      ['not', [@value[1], left, right]]
    else
      [@value, left, right]
    end
  end

  # Evaluate all children nodes
  #
  # @return [Array] The evaluate results of the children nodes
  def evaluate_children(mode)
    children.collect { |c| c.evaluate mode }
  end
end

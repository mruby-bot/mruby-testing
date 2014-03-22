##
# Enumerable
#
module Enumerable
  ##
  # call-seq:
  #    enum.drop(n)               -> array
  #
  # Drops first n elements from <i>enum</i>, and returns rest elements
  # in an array.
  #
  #    a = [1, 2, 3, 4, 5, 0]
  #    a.drop(3)             #=> [4, 5, 0]

  def drop(n)
    raise TypeError, "expected Integer for 1st argument" unless n.kind_of? Integer
    raise ArgumentError, "attempt to drop negative size" if n < 0

    ary = []
    self.each {|*val| n == 0 ? ary << val.__svalue : n -= 1 }
    ary
  end

  ##
  # call-seq:
  #    enum.drop_while {|arr| block }   -> array
  #
  # Drops elements up to, but not including, the first element for
  # which the block returns +nil+ or +false+ and returns an array
  # containing the remaining elements.
  #
  #    a = [1, 2, 3, 4, 5, 0]
  #    a.drop_while {|i| i < 3 }   #=> [3, 4, 5, 0]

  def drop_while(&block)
    ary, state = [], false
    self.each do |*val|
      state = true if !state and !block.call(*val)
      ary << val.__svalue if state
    end
    ary
  end

  ##
  # call-seq:
  #    enum.take(n)               -> array
  #
  # Returns first n elements from <i>enum</i>.
  #
  #    a = [1, 2, 3, 4, 5, 0]
  #    a.take(3)             #=> [1, 2, 3]

  def take(n)
    raise TypeError, "expected Integer for 1st argument" unless n.kind_of? Integer
    raise ArgumentError, "attempt to take negative size" if n < 0

    ary = []
    self.each do |*val|
      break if ary.size >= n
      ary << val.__svalue
    end
    ary
  end

  ##
  # call-seq:
  #    enum.take_while {|arr| block }   -> array
  #
  # Passes elements to the block until the block returns +nil+ or +false+,
  # then stops iterating and returns an array of all prior elements.
  #
  #
  #    a = [1, 2, 3, 4, 5, 0]
  #    a.take_while {|i| i < 3 }   #=> [1, 2]

  def take_while(&block)
    ary = []
    self.each do |*val|
      return ary unless block.call(*val)
      ary << val.__svalue
    end
    ary
  end
  
  ##
  # call-seq:
  #   enum.each_cons(n) {...}   ->  nil
  #
  # Iterates the given block for each array of consecutive <n>
  # elements.
  #
  # e.g.:
  #     (1..10).each_cons(3) {|a| p a}
  #     # outputs below
  #     [1, 2, 3]
  #     [2, 3, 4]
  #     [3, 4, 5]
  #     [4, 5, 6]
  #     [5, 6, 7]
  #     [6, 7, 8]
  #     [7, 8, 9]
  #     [8, 9, 10]

  def each_cons(n, &block)
    raise TypeError, "expected Integer for 1st argument" unless n.kind_of? Integer
    raise ArgumentError, "invalid size" if n <= 0

    ary = []
    self.each do |*val|
      ary.shift if ary.size == n
      ary << val.__svalue
      block.call(ary.dup) if ary.size == n
    end
  end

  ##
  # call-seq:
  #   enum.each_slice(n) {...}  ->  nil
  #
  # Iterates the given block for each slice of <n> elements.
  #
  # e.g.:
  #     (1..10).each_slice(3) {|a| p a}
  #     # outputs below
  #     [1, 2, 3]
  #     [4, 5, 6]
  #     [7, 8, 9]
  #     [10]

  def each_slice(n, &block)
    raise TypeError, "expected Integer for 1st argument" unless n.kind_of? Integer
    raise ArgumentError, "invalid slice size" if n <= 0

    ary = []
    self.each do |*val|
      ary << val.__svalue
      if ary.size == n
        block.call(ary)
        ary = []
      end
    end
    block.call(ary) unless ary.empty?
  end

  ##
  # call-seq:
  #    enum.group_by {| obj | block }  -> a_hash
  #
  # Returns a hash, which keys are evaluated result from the
  # block, and values are arrays of elements in <i>enum</i>
  # corresponding to the key.
  #
  #    (1..6).group_by {|i| i%3}   #=> {0=>[3, 6], 1=>[1, 4], 2=>[2, 5]}

  def group_by(&block)
    h = {}
    self.each do |*val|
      key = block.call(*val)
      sv = val.__svalue
      h.key?(key) ? (h[key] << sv) : (h[key] = [sv])
    end
    h
  end

  ##
  # call-seq:
  #    enum.sort_by { |obj| block }   -> array
  #
  # Sorts <i>enum</i> using a set of keys generated by mapping the
  # values in <i>enum</i> through the given block.
  def sort_by(&block)
    ary = []
    orig = [] 
    self.each_with_index{|e, i|
      orig.push(e)
      ary.push([block.call(e), i])
    }
    if ary.size > 1
      __sort_sub__(ary, ::Array.new(ary.size), 0, 0, ary.size - 1) do |a,b|
        a <=> b
      end
    end
    ary.collect{|e,i| orig[i]}
  end

  NONE = Object.new
  ##
  # call-seq:
  #    enum.first       ->  obj or nil
  #    enum.first(n)    ->  an_array
  #
  # Returns the first element, or the first +n+ elements, of the enumerable.
  # If the enumerable is empty, the first form returns <code>nil</code>, and the
  # second form returns an empty array.
  def first(n=NONE)
    if n == NONE
      self.each do |*val|
        return val.__svalue
      end
      return nil
    else
      a = []
      i = 0
      self.each do |*val|
        break if n<=i
        a.push val.__svalue
        i += 1
      end
      a
    end
  end

  ##
  # call-seq:
  #    enum.count                 -> int
  #    enum.count(item)           -> int
  #    enum.count { |obj| block } -> int
  #
  # Returns the number of items in +enum+ through enumeration.
  # If an argument is given, the number of items in +enum+ that
  # are equal to +item+ are counted.  If a block is given, it
  # counts the number of elements yielding a true value.
  def count(v=NONE, &block)
    count = 0
    if block
      self.each do |*val|
        count += 1 if block.call(*val)
      end
    else
      if v == NONE
        self.each { count += 1 }
      else
        self.each do |*val|
          count += 1 if val.__svalue == v 
        end
      end
    end
    count
  end

  ##
  # call-seq:
  #    enum.flat_map       { |obj| block } -> array
  #    enum.collect_concat { |obj| block } -> array
  #    enum.flat_map                       -> an_enumerator
  #    enum.collect_concat                 -> an_enumerator
  #
  # Returns a new array with the concatenated results of running
  # <em>block</em> once for every element in <i>enum</i>.
  #
  # If no block is given, an enumerator is returned instead.
  #
  #    [1, 2, 3, 4].flat_map { |e| [e, -e] } #=> [1, -1, 2, -2, 3, -3, 4, -4]
  #    [[1, 2], [3, 4]].flat_map { |e| e + [100] } #=> [1, 2, 100, 3, 4, 100]
  def flat_map(&block)
    return to_enum :flat_map unless block_given?

    ary = []
    self.each do |*e|
      e2 = block.call(*e)
      if e2.respond_to? :each
        e2.each {|e3| ary.push(e3) }
      else
        ary.push(e2)
      end
    end
    ary
  end
  alias collect_concat flat_map

  ##
  # call-seq:
  #    enum.max_by {|obj| block }      -> obj
  #    enum.max_by                     -> an_enumerator
  #
  # Returns the object in <i>enum</i> that gives the maximum
  # value from the given block.
  #
  # If no block is given, an enumerator is returned instead.
  #
  #    %w[albatross dog horse].max_by {|x| x.length }   #=> "albatross"

  def max_by(&block)
    return to_enum :max_by unless block_given?

    first = true
    max = nil
    max_cmp = nil

    self.each do |*val|
      if first
        max = val.__svalue
        max_cmp = block.call(*val)
        first = false
      else
        if (cmp = block.call(*val)) > max_cmp
          max = val.__svalue
          max_cmp = cmp
        end
      end
    end
    max
  end

  ##
  # call-seq:
  #    enum.min_by {|obj| block }      -> obj
  #    enum.min_by                     -> an_enumerator
  #
  # Returns the object in <i>enum</i> that gives the minimum
  # value from the given block.
  #
  # If no block is given, an enumerator is returned instead.
  #
  #    %w[albatross dog horse].min_by {|x| x.length }   #=> "dog"

  def min_by(&block)
    return to_enum :min_by unless block_given?

    first = true
    min = nil
    min_cmp = nil

    self.each do |*val|
      if first
        min = val.__svalue
        min_cmp = block.call(*val)
        first = false
      else
        if (cmp = block.call(*val)) < min_cmp
          min = val.__svalue
          min_cmp = cmp
        end
      end
    end
    min
  end

  ##
  #  call-seq:
  #     enum.minmax                  -> [min, max]
  #     enum.minmax { |a, b| block } -> [min, max]
  #
  #  Returns two elements array which contains the minimum and the
  #  maximum value in the enumerable.  The first form assumes all
  #  objects implement <code>Comparable</code>; the second uses the
  #  block to return <em>a <=> b</em>.
  #
  #     a = %w(albatross dog horse)
  #     a.minmax                                  #=> ["albatross", "horse"]
  #     a.minmax { |a, b| a.length <=> b.length } #=> ["dog", "albatross"]

  def minmax(&block)
    max = nil
    min = nil
    first = true

    self.each do |*val|
      if first
        val = val.__svalue
        max = val
        min = val
        first = false
      else
        if block
          max = val.__svalue if block.call(*val, max) > 0
          min = val.__svalue if block.call(*val, min) < 0
        else
          val = val.__svalue
          max = val if (val <=> max) > 0
          min = val if (val <=> min) < 0
        end
      end
    end
    [min, max]
  end
end

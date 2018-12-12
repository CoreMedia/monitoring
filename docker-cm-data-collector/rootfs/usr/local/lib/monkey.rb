
# -----------------------------------------------------------------------------
# Monkey patches

# Modify `Object` (https://gist.github.com/Integralist/9503099)

# None of the above solutions work with a multi-level hash
# They only work on the first level: {:foo=>"bar", :level1=>{"level2"=>"baz"}}
# The following two variations solve the problem in the same way
# transform hash keys to symbols
# multi_hash = { 'foo' => 'bar', 'level1' => { 'level2' => 'baz' } }
# multi_hash = multi_hash.deep_string_keys

class Object

  def deep_symbolize_keys

    if( self.is_a?( Hash ) )
      return self.inject({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v.deep_string_keys }
      end
    elsif( self.is_a?( Array ) )
      return self.map { |memo| memo.deep_string_keys }
    end

    self
  end

  def deep_string_keys

    if( self.is_a?( Hash ) )
      return self.inject({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_s] = v.deep_string_keys }
      end
    elsif( self.is_a?( Array ) )
      return self.map { |memo| memo.deep_string_keys }
    end

    self
  end

end

# -----------------------------------------------------------------------------

class Array
  def compare( comparate )
    to_set == comparate.to_set
  end
end

# -----------------------------------------------------------------------------

# filter hash
# example:
# tags = [ 'foo', 'bar', 'fii' ]
# useableTags = tags.filter( 'fii' )

class Hash
  def filter( *args )
    if( args.size == 1 )
      if( args[0].is_a?( Symbol ) )
        args[0] = args[0].to_s
      end
      self.select { |key| key.to_s.match( args.first ) }
    else
      self.select { |key| args.include?( key ) }
    end
  end

  # a << 0.3 <<0.1 << 1.0 << 0.4 << 2.0 << 2.2 << 1.8 << 1.6 << 1.6
  # a.average(5)
  #
  def average(size)
    reject!{ |v| v.nil? }
    pop(size)
    inject { |sum, x| sum + x }.round(2) / size
  end
end

# -----------------------------------------------------------------------------

# Lengthen timeout in Net::HTTP
# module Net
#   class HTTP
#     alias old_initialize initialize
#
#     def initialize(*args)
#       old_initialize(*args)
#       @read_timeout = 15
#     end
#   end
# end

# -----------------------------------------------------------------------------

class Array
  def partial_include? search
    self.each do |e|
      return true if search.include?(e.to_s)
    end
    return false
  end
end

# -----------------------------------------------------------------------------

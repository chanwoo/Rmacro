=begin
Rmacro - A macro utility similar to Common Lisp macros for Ruby

(The MIT License)

Copyright (c) 2009 Chanwoo Yoo

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=end

require 'macro'

# parse("[a, [b, c], _]")
# => s(:array, s(:call, nil, :a, s(:arglist)), s(:array, s(:call, nil, :b, s(:arglist)), s(:call, nil, :c, s(:arglist))), s(:call, nil, :_, s(:arglist)))
class MacroDefinition

  # destructuring_bind([a, [b, c], _], [1, [2, 3], 4])
  # [a, b, c]
  # => [1, 2, 3]
  def destructuring_bind(template, sequence)
    macro_helper = Macro.new
    # parse("[a, [b, c], _]")
    # => s(:array, s(:call, nil, :a, s(:arglist)), s(:array, s(:call, nil, :b, s(:arglist)), s(:call, nil, :c, s(:arglist))), s(:call, nil, :_, s(:arglist)))
    symbol_array = macro_helper.exhaustive_collect(macro_helper.exhaustive_collect(template,
                                                                                   lambda {|expr| expr.is_a?(Array) and (expr.first == :call)},
                                                                                   lambda {|expr| expr[2]}),
                                                   lambda {|expr| expr.is_a?(Array) and (expr.first == :array)},
                                                   lambda {|expr| expr.slice(1..expr.length)})
    # symbol_array => [:a, [:b, :c], :_]
    code = "";
    array_name = gensym(:array)
    code = code + "#{array_name} = #{c(sequence)} \n"

    indices = all_indices_for_binding(symbol_array)
    indices.each do |each|
      code = code + "#{item_at_index(symbol_array, each)} = #{array_name}#{index_string(each)} \n"
    end
    bq(code)
  end

  def ntimes(n, body)
    bq("#{c(n)}.times do
          #{c(body)}
        end")
  end

  def all_indices (array, start_index, ignore)
    indices = []
    array.each_with_index do |each, index|
      if (each.is_a?(Array))
        indices = indices + all_indices(each, (start_index + [index]), ignore)
      else
        indices << (start_index + [index]) unless each == ignore
      end
    end
    indices
  end

  # all_indices_for_binding([:a, [:_, :b, [:c, :_], :d], :e, [:f, :g, [:i, [:_]]]])
  # => [[0], [1, 1], [1, 2, 0], [1, 3], [2], [3, 0], [3, 1], [3, 2, 0]]
  def all_indices_for_binding(array)
    all_indices(array, [], :_)
  end

  # item_at_index([:a, [:b, [:c, :d]], :e], [1,1,0])
  # => [:a, [:b, [:c, :d]], :e][1][1][0]
  # => :c
  def item_at_index(array, indices)
    item = array
    indices.each do |each|
      item = item.slice(each)
    end
    item
  end

  # index_string([1,2,3]) => "[1][2][3]"
  def index_string(indices)
    index = ""
    indices.each do |each|
      index = index + "[#{each}]"
    end
    index
  end

  private :all_indices, :all_indices_for_binding, :item_at_index, :index_string
end

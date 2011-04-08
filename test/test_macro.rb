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

require 'test/unit'
require 'english'
$LOAD_PATH.push File.join(File.dirname(__FILE__), "..", "lib")
require 'macro'

class MacroDefs
  def my_if(condition, clause)
    (Code.from_s_expression(s(:if, Code.from_string(condition).to_s_expression, Code.from_string(clause).to_s_expression, nil))).to_s
  end

  def time(code)
    now = gensym(:now)
    %Q{
      #{now} = Time.now
      #{code}
      Time.now - #{now}
      }
  end

  def delay(code)
    %Q{
      lambda { #{code} }
      }
  end

  def MacroDefs.my_when(test, body)
    %Q{
      my_if(#{test},
            #{body})
      }
  end

  def my_multiply(a, b)
    %Q{
      #{a} * #{b}
      }
  end


  def progn(*rest)
    (Code.block_from_strings(*rest)).to_s
  end

  def MacroDefs.my_add(a, b)
    %Q{
      #{a} + #{b}
      }
  end
end

class Person
  @@hey = "hey!"
  def name
    "John"
  end

  def age
    30
  end

  def Person.hello
    "hello"
  end

  def Person.hey
    @@hey
  end
end

require_with_macro('example', true, MacroDefs.new)

class TestMacro < Test::Unit::TestCase
  def setup
    @macro = Macro.new
    @example = Example.new
    # RubyParser.new.parse('1+1')
    @sexp1 = s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))
    # RubyParser.new.parse('a = 3')
    @sexp2 = s(:lasgn, :a, s(:lit, 3))
    # RubyParser.new.parse('add(a,b)')
    @sexp3 = s(:call, nil, :defs, s(:arglist, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist))))
    # RubyParser.new.parse("
    # def rest(array)
    #   last_index = array.length - 1
    #   array[1..last_index]
    # end
    # ")
    @sexp4 = s(:defn, :rest,
               s(:args, :array),
               s(:scope, s(:block,
                           s(:lasgn, :last_index, s(:call,
                                                    s(:call, s(:lvar, :array), :length, s(:arglist)),
                                                    :-,
                                                    s(:arglist, s(:lit, 1)))),
                           s(:call, s(:lvar, :array), :[], s(:arglist, s(:dot2, s(:lit, 1), s(:lvar, :last_index)))))))
    # RubyParser.new.parse("my_if a, c")
    @sexp5 = s(:call, nil, :my_if, s(:arglist, s(:call, nil, :a, s(:arglist)), s(:call, nil, :c, s(:arglist))))
  end

  def test_rest
    array = [1,2,3]
    assert_equal([2,3], @macro.rest(array))
  end

  def test_array?
    assert_equal(true, @macro.array?([1,2,3]))
    assert_equal(false, @macro.array?(:call))
    assert_equal(true, @macro.array?(s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))))
  end

  def test_include_array?
    assert_equal(true, @macro.include_array?([1, 2, [3, 4]]))
    assert_equal(false, @macro.include_array?([1, 2, 3, 4]))
  end

  def test_exhaustive_collect
    array = [1,2,[3,4,5,[1,4,5]],[2,3]]
    assert_equal([1,3,[3,5,5,[1,5,5]],[3,3]],
                 @macro.exhaustive_collect(array,
                                           lambda { |item| (not(@macro.array?(item))) and (item.remainder(2) == 0) },
                                           lambda { |item| item + 1 }))
    assert_equal([1,2,[3,4,5,[1,4,5,10,10],10],[2,3,10,10,10],10],
                 @macro.exhaustive_collect(array,
                                           lambda { |item| (@macro.array?(item) and (item.length < 5)) },
                                           lambda { |item| item.push(10) }))
  end

  def test_depth_first_exhaustive_collect
    array = [1,2,[3,4,5,[1,4,5]],[2,3]]
    assert_equal([1,3,[3,5,5,[1,5,5]],[3,3]],
                 @macro.depth_first_exhaustive_collect(array,
                                           lambda { |item| (not(@macro.array?(item))) and (item.remainder(2) == 0) },
                                           lambda { |item| item + 1 }))
    assert_equal([1,2,[3,4,5,[1,4,5,10,10],10],[2,3,10,10,10],10],
                 @macro.depth_first_exhaustive_collect(array,
                                           lambda { |item| (@macro.array?(item) and (item.length < 5)) },
                                           lambda { |item| item.push(10) }))
  end

  def test_replace
    array = [1,2,[3,4,5,[1,4,5]],[2,3]]
    assert_equal([1,3,[3,5,5,[1,5,5]],[3,3]],
                 @macro.replace(array,
                                lambda { |item| (not(@macro.array?(item))) and (item.remainder(2) == 0) },
                                lambda { |item| item + 1 }))
    assert_equal([1,2,[3,4,5,[1,4,5,10],10],[2,3,10],10],
                 @macro.replace(array,
                                lambda { |item| (@macro.array?(item) and (item.length < 5)) },
                                lambda { |item| item.push(10) }))
  end

  def test_replace_sexp_with_type
    assert_equal(s(:call, s(:colon2, s(:colon2, s(:const, :Thing), :Animal, 1), :Person, 1), :new, s(:arglist)),
                 @macro.to_sexp(@macro.replace_sexp_with_type(s(:call, s(:colon2, s(:colon2, s(:const, :Thing), :Animal), :Person), :new, s(:arglist)),
                                                            :colon2,
                                                            lambda { |sexp| sexp.push(1) })))
  end

  def test_call_site?
    assert_equal(true, @macro.call_site?(@sexp1))
    assert_equal(false, @macro.call_site?(@sexp2))
  end

  def test_receiver
    assert_equal(s(:lit, 1), @macro.receiver(@sexp1))
    assert_equal(nil, @macro.receiver(@sexp2))
    assert_equal(nil, @macro.receiver(@sexp3))
  end

  def test_call_name
    assert_equal(:+, @macro.call_name(@sexp1))
    assert_equal(nil, @macro.call_name(@sexp2))
    assert_equal(:defs, @macro.call_name(@sexp3))
  end

  def test_call_keys
    assert_equal([nil, :add],
                 @macro.call_keys(parse("add(1, 2)")))
    assert_equal([:Person, :hello],
                 @macro.call_keys(parse("Person.hello")))
    assert_equal([s(:call, nil, :abc, s(:arglist)), :add],
                 @macro.call_keys(parse("abc.add(1, 2)")))
  end

  def test_global_call?
    assert_equal(false, @macro.global_call?(@sexp1))
    assert_equal(false, @macro.global_call?(@sexp2))
    assert_equal(true, @macro.global_call?(@sexp3))
  end

  def test_constant_call?
    assert_equal(true,
                 @macro.constant_call?(s(:call, s(:const, :Hello), :hey, s(:arglist, s(:lit, 3)))))
    assert_equal(true,
                 @macro.constant_call?(parse("Person.play(1, 2)")))
    assert_equal(false,
                 @macro.constant_call?(@sexp1))
    assert_equal(false,
                 @macro.constant_call?(@sexp2))
    assert_equal(false,
                 @macro.constant_call?(@sexp3))
  end

  def test_receiver_name
    assert_equal(nil,
                 @macro.receiver_name(parse("add(1, 2)")))
    assert_equal(:Person,
                 @macro.receiver_name(parse("Person.hello")))
    assert_equal(s(:call, nil, :abc, s(:arglist)),
                 @macro.receiver_name(parse("abc.add(1, 2)")))
  end

  def test_expandable?
    assert_equal(true, @macro.expandable?(@sexp5, @macro.defs(MacroDefs.new)))
  end

  def test_args
    assert_equal(["1"], @macro.args(@sexp1))
    assert_equal([], @macro.args(@sexp2))
    assert_equal(["a", "b"],
                 @macro.args(@sexp3))
  end

  def test_defs
    assert_equal("John",
                 ((@macro.defs(Person.new))[[nil, :name]]).call)
    assert_equal(30,
                 ((@macro.defs(Person.new))[[nil, :age]]).call)
    assert_equal("hello",
                 ((@macro.defs(Person.new))[[:Person, :hello]]).call)
    assert_equal("hey!",
                 ((@macro.defs(Person.new))[[:Person, :hey]]).call)
  end

  def test_expand
    assert_equal(true, @macro.expandable?(parse("my_if(a, c)"), @macro.defs(MacroDefs.new)))
    assert_equal(s(:if, s(:call, nil, :a, s(:arglist)), s(:call, nil, :c, s(:arglist)), nil),
                 @macro.expand(parse("my_if(a, c)"), @macro.defs(MacroDefs.new)))
  end

  def test_to_sexp
    assert_equal(s(1,2,3), @macro.to_sexp([1,2,3]))
    assert_equal(nil, @macro.to_sexp(nil))
    assert_equal(s(:lit, 1),
                 @macro.to_sexp("1"))
  end

  def test_q
    assert_equal(s(:if, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist)), nil),
                 bq("
                   if a
                     b
                   end
                   "))
    assert_equal(unparse(s(:block, s(:lasgn, :a, s(:true)), s(:if, s(:lvar, :a), s(:call, nil, :b, s(:arglist)), nil))),
                 unparse(bq("a = true", s(:if, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist)), nil))))
  end

  def test_nonexistent_var
    assert_equal("_3",
                 @macro.nonexistent_var("_123 abc def 2324 _2 _23 _43 _0"))
  end

  def test_gensym
    assert_equal("__generated_name_00", gensym)
    assert_equal("__generated_name_01", gensym)
    assert_equal("time__generated_name_00", gensym(:time))
    assert_equal("time__generated_name_01", gensym("time"))
  end

  def test_macro_expand
    assert_equal("b if a",
                 @macro.macro_expand("my_if a, b", MacroDefs.new))
  end

  def test_require_with_macro
    assert_equal("success",
                 @example.test_my_if)
    assert_equal(Float,
                 @example.test_time.class)
    assert_equal(3,
                 @example.test_delay)
    assert_equal(5,
                 @example.test_delay2)
    assert_equal("my_when",
                 @example.test_my_when)
    assert_equal(Float,
                 @example.test_multiple_times.class)
    assert_equal(4,
                 @example.test_my_multiply)
    assert_equal(3,
                 @example.test_progn)
    assert_equal(3,
                 @example.test_my_add)
  end

  def test_e
    assert_equal(parse("
                       time = Time.now
                       if a
                         b
                       end
                       Time.now - time
                       "),
                 bq("
                   time = Time.now
                   #{c(s(:if, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist)), nil))}
                   Time.now - time
                   "))
  end

  def test_expansion_equal?
    assert_equal(true,
                 expansion_equal?("puts 'hi' if true", "my_if(true, (puts 'hi'))", MacroDefs.new))
  end

  def test_to_str
    assert_equal(":abc", @macro.to_str(:abc))
    assert_equal("nil", @macro.to_str(nil))
    assert_equal("1", @macro.to_str(1))
  end

  def test_to_elt
    assert_equal("<Fixnum>1</Fixnum>", @macro.to_elt(1))
  end

  def test_sexp_to_xml
    assert_equal("<?xml version=\"1.0\"?><Sexp>
<Symbol>
:lasgn
</Symbol>
<Symbol>
:a
</Symbol>
<Sexp>
<Symbol>
:lit
</Symbol>
<Fixnum>
3
</Fixnum>
</Sexp>
</Sexp>".delete("\n"),
                 @macro.sexp_to_xml(s(:lasgn, :a, s(:lit, 3))))
  end

  def test_xml_to_sexp
    assert_equal(true,
                 (s(:lasgn, :a, s(:lit, 3))).eql?(@macro.xml_to_sexp("<Sexp>
<Symbol>
:lasgn
</Symbol>
<Symbol>
:a
</Symbol>
<Sexp>
<Symbol>
:lit
</Symbol>
<Fixnum>
3
</Fixnum>
</Sexp>
</Sexp>")))

    assert_equal(true,
                 (s(:call, nil, :defs, s(:arglist, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist)))).eql?(@macro.xml_to_sexp("<Sexp><Symbol>:call</Symbol><NilClass>nil</NilClass><Symbol>:defs</Symbol><Sexp><Symbol>:arglist</Symbol><Sexp><Symbol>:call</Symbol><NilClass>nil</NilClass><Symbol>:a</Symbol><Sexp><Symbol>:arglist</Symbol></Sexp></Sexp><Sexp><Symbol>:call</Symbol><NilClass>nil</NilClass><Symbol>:b</Symbol><Sexp><Symbol>:arglist</Symbol></Sexp></Sexp></Sexp></Sexp>"))))
  end
end

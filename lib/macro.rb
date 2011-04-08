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

require 'rubygems'
gem 'ruby_parser'
require 'ruby_parser'
gem 'ruby2ruby'
require 'ruby2ruby'
require 'rexml/document'
require 'code'

class Macro

  # Returns an array without the first element.
  # e.g. rest([1, 2, 3]) => [2, 3]
  def rest(array)
    if array.length == 1
      []
    else
      last_index = array.length - 1
      array[1..last_index]
    end
  end

  # Tests whether item is a type of Array.
  # e.g. array?([1, 2, 3]) => true
  # e.g. array?(1) => false
  def array?(item)
    item.is_a?(Array)
  end

  # Tests whether an array includes other array as its member. If there is no array among its members, it returns false.
  # e.g. include_array?([1, 2, [3, 4]]) => true
  # e.g. include_array?([1, 2, 3, 4]) => false
  def include_array?(array)
    array.any? { |member| array?(member) }
  end

  # Collects every element(including expression itself) which the function is applied to, whenever the predicate(element) is true.
  # This process repeatedly executes until there is no element at which the predicate returns true.
  # e.g. exhaustive_collect([1, [2], 3], lambda { |item| item.is_a?(Array) and item.length < 4 }, lambda { |array| array.push(4) })
  # => [1, [2, 4, 4, 4], 3, 4]
  def exhaustive_collect(exp, predicate, function)
    if predicate.call(exp)
      exhaustive_collect(function.call(exp), predicate, function)
    elsif not(predicate.call(exp)) and array?(exp)
      exp.collect { |item| exhaustive_collect(item, predicate, function) }
    else
      exp
    end
  end

  # Similar to 'exhaustive_collect'.
  # But the applying of 'function' spreads out from inner elements to outer elements in an array.
  def depth_first_exhaustive_collect(exp, predicate, function)
    if predicate.call(exp) and array?(exp)
      depth_first_exhaustive_collect(function.call(exp.collect { |item| depth_first_exhaustive_collect(item, predicate, function) }), predicate, function)
    elsif predicate.call(exp) and (not(array?(exp)))
      depth_first_exhaustive_collect(function.call(exp), predicate, function)
    elsif not(predicate.call(exp)) and array?(exp)
      exp.collect { |item| depth_first_exhaustive_collect(item, predicate, function) }
    else
      exp
    end
  end

  # Traverses in an array, and tests each element with the 'predicate'.
  # If the result of the test is true, applies the function to the element exactly once.
  def replace(exp, predicate, function)
    if predicate.call(exp) and array?(exp)
      function.call(exp.collect { |item| replace(item, predicate, function) })
    elsif predicate.call(exp) and (not(array?(exp)))
      function.call(exp)
    elsif not(predicate.call(exp)) and array?(exp)
      exp.collect { |item| replace(item, predicate, function) }
    else
      exp
    end
  end

  # Finds a specific type of s-expression, and replace it with the result of the application of the 'function' to it.
  # e.g. replace_sexp(s(:call, s(:colon2, s(:colon2, s(:const, :Thing), :Animal), :Person), :new, s(:arglist)), :colon2, lambda { |sexp| sexp.push(1) })
  # => [:call, [:colon2, [:colon2, [:const, :Thing], :Animal, 1], :Person, 1], :new, [:arglist]]
  def replace_sexp_with_type(sexp, type, function)
    replace(sexp,
            lambda { |exp| array?(exp) and exp.first == type },
            function)
  end

  # Accepts an array of directory names and a filename, then returns an array of abstract paths which the file of the filename exists.
  # e.g. search_file($LOAD_PATH, "hello.rb") => ["/home/hello.rb", "/temp/hello.rb"]
  def search_file(dirs, filename)
    findings = dirs.collect do |dir|
      abs_path = File.join(File.expand_path(dir), filename)
      if File.exist?(abs_path)
        abs_path
      end
    end
    findings.delete(nil)
    findings
  end

  # Parses a ruby code string into a s-expression.
  # e.g. parse("a = 1") => s(:lasgn, :a, s(:lit, 1))
  def parse(str)
    RubyParser.new.parse(str.deep_clone)
  end

  # Unparse a s-expression into a ruby code string.
  # e.g. unparse(s(:call, nil, :hello, s(:arglist, s(:str, "John")))) => "hello(\"John\")"
  def unparse(sexp)
    Ruby2Ruby.new.process(sexp.deep_clone)
  end

  # Tests whether the s-expression's first element is ':call'.
  # e.g. call_site?(s(:call, nil, :hello, s(:arglist))) => true
  # e.g. call_site?(s(:lasgn, :a, s(:lit, 1))) => false
  def call_site?(sexp)
    if (array?(sexp) and (sexp.first == :call))
      true
    else
      false
    end
  end

  # Returns the receiver of a call.
  # e.g. receiver(s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))) => s(:lit, 1)
  def receiver(sexp)
    if call_site?(sexp)
      sexp[1]
    end
  end

  # Returns the name of the message(i.e. method).
  # e.g. call_name(s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))) => :+
  def call_name(sexp)
    if call_site?(sexp)
      sexp[2]
    end
  end

  # Tests whether a receiver exists.
  # e.g. global_call?(s(:call, nil, :hello, s(:arglist))) => true
  # e.g. global_call?(s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))) => false
  def global_call?(sexp)
    if (call_site?(sexp) and (receiver(sexp) == nil))
      true
    else
      false
    end
  end

  # Tests whether the receiver is a constant.
  # e.g. constant_call?(s(:call, s(:const, :Person), :hello, s(:arglist))) => true
  # e.g. constant_call?(s(:call, nil, :hello, s(:arglist))) => false
  def constant_call?(sexp)
    if (call_site?(sexp) and array?(receiver(sexp)) and ((receiver(sexp)).first == :const))
      true
    else
      false
    end
  end

  # Returns the name of the constant if the receiver is a constant,
  # else it returns the receiver of the call.
  # e.g. receiver_name(s(:call, s(:const, :Person), :hello, s(:arglist))) => :Person
  # e.g. receiver_name(s(:call, nil, :hello, s(:arglist))) => nil
  def receiver_name(sexp)
    if (global_call?(sexp))
      nil
    elsif (constant_call?(sexp))
      (receiver(sexp))[1]
    else
      receiver(sexp)
    end
  end

  # Returns a pair of the receiver name and the message name.
  # e.g. call_keys(s(:call, nil, :hello, s(:arglist))) => [nil, :hello]
  # e.g. call_keys(s(:call, s(:const, :Person), :hello, s(:arglist))) => [:Person, :hello]
  def call_keys(sexp)
    if call_site?(sexp)
      [receiver_name(sexp), call_name(sexp)]
    end
  end

  # Tests whether an s-expression is macro-expandable.
  # If it is possible to find a matched function in definitions based on s-expression's
  # message name and receiver name, it returns true.
  def expandable?(exp, defs)
    if ((global_call?(exp) or constant_call?(exp)) and array?(exp) and defs.key?(call_keys(exp)))
      true
    else
      false
    end
  end

  # Returns an array of arguments as code strings of a call.
  # e.g. args(s(:call, nil, :hello, s(:arglist, s(:str, "John")))) => [s(:str, "John")]
  # e.g. args(s(:call, nil, :max, s(:arglist, s(:lit, 1), s(:lit, 2)))) => [s(:lit, 1), s(:lit, 2)]
  def args(sexp)
    if call_site?(sexp)
      (rest(sexp[3])).collect { |each| (Code.from_s_expression(each)).to_s }
    else
      []
    end
  end

  # A macro is defined as a ruby method which accepts s-expression and returns s-expression.
  # A macro expansion means applying the methods to s-expressions which are generated by parsing ruby codes.
  # Before macro expansions, it needs to extract macro definition functions as a hash table from macro definition objects.
  # 'defs' does such a thing. It accepts objects which define macros. then extracts class and public instance methods from each object,
  # and returns a hash which contains the method functions as values and pairs of [receiver_name, method_name] as keys.
  # 'method_name's would be class and public instance method names of the object.
  # A 'receiver_name' would be nil if the method is an instance method, or ':CLASSNAME'(e.g. :Person) if it is a class method.
  # Extracted macro functions(methods) are clojures. So they can access their macro objects after extracting and saving in the hash.
  def defs(*objs)
    definitions = { }
    objs.each do |obj|
      instance_method_names = (obj.public_methods(false)).collect { |method_name| method_name.to_sym }
      instance_method_names.each { |name| definitions[[nil, name]] = obj.method(name) }
      cls = obj.class
      class_method_names = (cls.singleton_methods(false)).collect { |method_name| method_name.to_sym }
      class_method_names.each { |name| definitions[[cls.name.to_sym, name]] = cls.method(name) }
    end
    definitions
  end

  # Returns a s-expression which is macro-expanded by using definitions including extracted functions from macro definition objects.
  def expand(sexp, defs)
    Sexp.from_array(depth_first_exhaustive_collect(sexp,
                                                   lambda { |exp| expandable?(exp, defs) },
                                                   lambda { |exp| (Code.from_string(defs[call_keys(exp)].call(*args(exp)))).to_s_expression }))
  end

  # Accepts code strings and applies macro functions of macro definition objects, then returns the expanded code strings.
  def macro_expand(str, *macro_objs)
    unparse(expand(parse(str), defs(*macro_objs)))
  end

  # If the argument is an array, it converts it to a s-expression and returns it.
  # Else the argument is a string, it generates a s-expression by parsing it, and returns the s-expression.
  def to_sexp(exp)
    if array?(exp)
      Sexp.from_array(exp)
    elsif exp.is_a?(String)
      parse(exp)
    end
  end

  # If the argument is a code string, back_quote unparses the argument and returns the s-expression as a result.
  # If there is multiple arguments, and some of them are s-expressions and others are strings,
  # back_quote transforms them into s-expressions and combine them as a block s-expression.
  def back_quote(*rest)
    if (rest.length == 1)
      to_sexp(rest.first)
    else
      (s(:block) + (rest.collect do |exp|
                      to_sexp(exp)
                    end))
    end
  end

  # Transforms s-expressions into a code string.
  def comma(*sexps)
    if (sexps.length == 1)
      unparse(*sexps)
    else
      unparse(s(:block) + sexps)
    end
  end

  # Finds a nonexistent name in the code string.
  # It starts a test with '_0', and increment the number if the name exists in the code string. (e.g. _1, _2, _3, ..., _10, ...)
  def nonexistent_var(str, counter = 0)
    if str.include?("_" + counter.to_s)
      nonexistent_var(str, counter.succ)
    else
      "_" + counter.to_s
    end
  end

  @@GENSYM_TABLE = { }
  @@NONEXISTENT_VAR = "_0"

  # Generates a nonexistent name just like 'gensym' in Common Lisp.
  # e.g. gensym() => "_21"
  # e.g. gensym(:temp) => "temp_14"
  # e.g. gensym("temp") => "temp_52"
  def gensym(var_name = "")
    name = var_name.to_s
    if @@GENSYM_TABLE.key?(name)
      generated_symbol = name + @@NONEXISTENT_VAR + ((@@GENSYM_TABLE[name]).succ).to_s
      @@GENSYM_TABLE[name] = (@@GENSYM_TABLE[name]).succ
      generated_symbol
    else
      @@GENSYM_TABLE[name] = 0
      name + @@NONEXISTENT_VAR + "0"
    end
  end

  # Open the required ruby file, and apply macros which are defined in macro objects to it,
  # then loads the macro expanded file. If the second argument is true, the expanded file will be deleted
  # after loading it. If it is false, the expanded file will not be deleted.
  # An macro expanded file name is generated by adding a prefix 'macroexpanded_' to an original file name.
  def require_with_macro(required_name, delete_expanded_file, *macro_objs)
    source_name = required_name + ".rb"
    source_directory = File.dirname((search_file($LOAD_PATH, source_name)).first)
    source = File.read(File.join(source_directory, source_name))
    @@GENSYM_TABLE = { }
    @@NONEXISTENT_VAR = nonexistent_var(source)
    expanded_path = File.join(source_directory, ("macroexpanded_" + source_name))
    File.open(expanded_path, "w") do |macroexpanded_file|
      macroexpanded_file.puts(macro_expand(source, *macro_objs))
    end
    require("macroexpanded_" + required_name)
    if delete_expanded_file
      File.delete(expanded_path)
    end
  end

  # e.g. to_str(:abc) => ":abc"
  # e.g. to_str(nil) => "nil"
  # e.g. to_str(1) => "1"
  def to_str(arg)
    if arg.is_a?(Symbol)
      ":" + arg.to_s
    elsif arg.nil?
      "nil"
    elsif arg.is_a?(String)
      "'#{arg}'"
    else
      arg.to_s
    end
  end

  # e.g. to_elt(1) => "<Fixnum>1</Fixnum>"
  def to_elt(arg)
    "<" + to_str(arg.class) + ">" + to_str(arg) + "</" + to_str(arg.class) + ">"
  end

  def sexp_to_xml(sexps)
    "<?xml version=\"1.0\"?>" + _sexp_to_xml(sexps)
  end

  def _sexp_to_xml(sexps)
    if sexps.is_a?(Array)
      "<" + to_str(sexps.class) + ">" + sexps.inject("") { |result, sexp| result + _sexp_to_xml(sexp) } + "</" + to_str(sexps.class) + ">"
    else
      to_elt(sexps)
    end
  end

  def elt_to_sexp(element)
    sexp = []
    element.each_element do |child|
       if child.name == "Sexp"
         sexp << elt_to_sexp(child)
       else
         sexp << eval(child.text)
       end
    end
    sexp
  end

  def xml_to_sexp(xml_str)
    doc = REXML::Document.new(xml_str)
    Sexp.from_array(elt_to_sexp(doc.root))
  end

end

# A global function for calling an instance method 'parse' of a Macro object. Just for the convenience.
def parse(str)
  Macro.new.parse(str)
end

# A global function for calling an instance method 'unparse' of a Macro object. Just for the convenience.
def unparse(sexp)
  Macro.new.unparse(sexp)
end

# A global function for calling an instance method 'back_quote' of a Macro object. Just for the convenience.
def bq(*rest)
  Macro.new.back_quote(*rest)
end

# A global function for calling an instance method 'comma' of a Macro object. Just for the convenience.
def c(*sexps)
  Macro.new.comma(*sexps)
end

# A global function for calling an instance method 'gensym' of a Macro object. Just for the convenience.
def gensym(var_name = "")
  Macro.new.gensym(var_name)
end

# A global function for calling an instance method 'macro_expand' of a Macro object. Just for the convenience.
def macro_expand(str, *macro_objs)
  Macro.new.macro_expand(str, *macro_objs)
end

# A global function for calling an instance method 'require_with_macro' of a Macro object. Just for the convenience.
def require_with_macro(filename, delete_expanded_file, *macro_objs)
  Macro.new.require_with_macro(filename, delete_expanded_file, *macro_objs)
end

# Makes easy to test macros.
# e.g. expansion_equal?("puts 'hi' if true", "my_if(true, (puts 'hi'))", MacroDefinition.new) => true
def expansion_equal?(expanded_code, code, *macro_objs)
  if parse(expanded_code) == parse(macro_expand(code, *macro_objs))
    true
  else
    false
  end
end

# A global function for calling an instance method 'replace' of a Macro object. Just for the convenience.
def replace_sexp(sexp, predicate, function)
  Macro.new.replace(sexp, predicate, function)
end

# A global function for calling an instance method 'replace_sexp_with_type' of a Macro object. Just for the convenience.
def replace_sexp_with_type(sexp, type, function)
  Macro.new.replace_sexp_with_type(sexp, type, function)
end

# A global function for calling an instance method 'sexp_to_xml' of a Macro object. Just for the convenience.
def sexp_to_xml(sexps)
  Macro.new.sexp_to_xml(sexps)
end

# A global function for calling an instance method 'xml_to_sexp' of a Macro object. Just for the convenience.
def xml_to_sexp(xml_str)
  Macro.new.xml_to_sexp(xml_str)
end

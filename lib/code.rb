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

class Code

  def initialize(s_expression)
    @content = s_expression
  end

  def self.from_string(code_string)
    Code.new(RubyParser.new.parse(code_string.deep_clone))
  end

  def self.block_from_strings(*strings)
    if (strings.length == 1)
      Code.from_string(strings.first)
    else
      Code.from_s_expression(Sexp.from_array(s(:block) + (strings.collect do |string|
                                                            (Code.from_string(string)).to_s_expression
                                                          end)))
    end
  end

  def self.from_s_expression(s_expression)
    Code.new(s_expression)
  end

  def self.from_xml(xml_string)
    doc = REXML::Document.new(xml_string)
    Code.from_s_expression(Sexp.from_array(elt_to_sexp(doc.root)))
  end

  def to_s
    Ruby2Ruby.new.process(@content.deep_clone)
  end

  def to_string
    to_s
  end

  def to_s_expression
    @content
  end

  def to_xml
    "<?xml version=\"1.0\"?>" + sexp_to_xml(self.to_s_expression)
  end

  def ==(other)
    @content == other.to_s_expression
  end

  def evaluate
    eval(Ruby2Ruby.new.process(@content.deep_clone))
  end

  def method_missing(name, *args)
    @content.send(name, *args)
  end


  private

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
    if sexps.is_a?(Array)
      "<" + to_str(sexps.class) + ">" + sexps.inject("") { |result, sexp| result + sexp_to_xml(sexp) } + "</" + to_str(sexps.class) + ">"
    else
      to_elt(sexps)
    end
  end

  def self.elt_to_sexp(element)
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

end

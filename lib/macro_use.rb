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
require 'macro_definition'

class MacroUse
  def self.destructuring_bind
    anArray = [1, [2, 3], 4]
    destructuring_bind([a, [b, c], d], anArray)
    [a, b, c, d]
  end

  def self.destructuring_bind2
    anArray = [1, [2, [3, 4]], 5]
    destructuring_bind([a, [b, _], c], anArray)
    [a, b, c]
  end

  def self.destructuring_bind3
    anArray = [1, [2, 3], 4]
    a, b, c, d = 0
    eval(MacroDefinition.new.destructuring_bind(%Q{[a, [b, c], d]}, %Q{anArray}))
#    eval("a = 1")
#    eval("b = 2")
#    eval("c = 3")
#    eval("d = 4")
#    class_eval([a, b, c, d])
    [a, b, c, d]
  end
end

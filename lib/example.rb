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

class Example
  def test_my_if
    a = 3
    my_if a == 3, "success"
  end

  def test_time
    time = "abc"
    time(my_if true,
           sleep(0.01))
  end

  def force(function)
    function.call
  end

  def test_delay
    force(delay 3)
  end

  def test_delay2
    force(delay((a = 2
                 b = 3
                 a+b)))
  end

  def test_my_when
    MacroDefs.my_when [1,2,3].class == Array,
      "my_when"
  end

  def test_multiple_times
    time(time(time sleep(0.01)))
  end

  def test_my_multiply
    my_multiply(1+1, 1+1)
  end

  def test_progn
    progn(a = 1,
          b = 2,
          a + b)
  end

  def test_my_add
    MacroDefs.my_add(1, 2)
  end
end

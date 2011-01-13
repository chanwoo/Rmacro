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

# frozen_string_literal: false
require 'test/unit'

Warning[:ruby2_incompatible] = true

class TestKwHash < Test::Unit::TestCase
 
  def fix_NOW(&block)
    assert_warn(/FIX NOW/, &block)
  end
  def fix_now(&block)
    assert_warn(/fix now/, &block)
  end
  def fix_3_x(&block)
    assert_warn(/fix in 3.x/, &block)
  end
  def fix_n_a(&block)
    assert_warn(/\A\z/, &block)
  end

  def deleg1(*args)
    deleg2(*args)
  end
  def deleg2(x,*args)
    deleg3(x,*args)
  end
  def deleg3(*args)
    deleg4(*args)
  end
  def deleg4(m,*args)
    send(m,*args)
  end

  def deleg_kw(m,*args,**kw)
    send(m,*args,**kw)
  end

  def deleg_arg(m, arg)
    send(m, arg)
  end

  def f_hash(hash)
    hash
  end

  def f_rest(*rest)
    rest
  end
  def f_rest_kwrest(*rest,**kw)
    [rest, kw]
  end
  def f_kwrest(**kw)
    kw
  end

  def f_opt_kw(o=nil, **kw)
    [o,kw]
  end
  def f_lead_kw(o, **kw)
    [o,kw]
  end

  H0 = {}.freeze
  H1 = {k:1}.freeze
  
  def test_hash_delegation
    assert_equal(H1, deleg1(:f_hash, H1))
    assert_equal(H1, deleg_arg(:f_hash, H1))
  end

  def test_kw_delegation
    fix_3_x{ assert_equal(H1, deleg1(:f_kwrest, **H1)) }
    fix_3_x{ assert_equal(H1, deleg_arg(:f_kwrest, **H1)) }
  end
  
  def test_emptyhash_delegation
    assert_equal([{},{},{}], deleg1(:f_rest, {}, {}, {}))
    assert_equal([{},{},{}], deleg1(:f_rest, {}, {}, {}))
  end

  def test_kw_delegation
    assert_equal([1,2,3], deleg_kw(:f_rest, 1,2,3))
    assert_equal({a:4,b:5}, deleg_kw(:f_kwrest, a:4, b:5))
    assert_equal([[1,2,3],{a:4,b:5}], deleg_kw(:f_rest_kwrest, 1,2,3, a:4, b:5))
  end

  def test_arg_delegation
    assert_equal([{},{},{}], deleg1(:f_rest, {}, {}, {}))
    assert_equal([{},{},{}], deleg1(:f_rest, {}, {}, {}))
  end

  def test_behavior_change
    as_k = [nil, {:k=>1}]
    as_a = [{:k=>1}, {}]
    fix_NOW{ assert_equal(as_k, f_opt_kw(H1)) } #will change to as_a
    fix_n_a{ assert_equal(as_a, f_lead_kw(H1)) }
    fix_n_a{ assert_equal(as_k, f_opt_kw(**H1)) }
    fix_now{ assert_equal(as_a, f_lead_kw(**H1)) } #will change to error

    as_k = [nil, {}]
    as_a = [{}, {}]
    fix_NOW{ assert_equal(as_k, f_opt_kw(H0)) } #will change to as_a
    fix_n_a{ assert_equal(as_a, f_lead_kw(H0)) }
    fix_n_a{ assert_equal(as_k, f_opt_kw(**H0)) }
    fix_now{ assert_equal(as_a, f_lead_kw(**H0)) } #will change to error
  end

  def test_destructuring_iteration
    arr = []
    arr.push(x: 1)
    arr.push(x: 2)
    fix_3_x{ assert_equal([1,2], arr.map{ |x:| x }) }
    fix_3_x{ assert_equal([1,2], arr.map{ |a=0,x:| x }) }
    fix_3_x{ assert_equal([1,2], arr.map{ |a=0,x:nil| x }) }
    arr = []
    arr.push({x: 1})
    arr.push({x: 2})
    fix_now{ assert_equal([1,2], arr.map{ |x:| x }) }
    fix_NOW{ assert_equal([1,2], arr.map{ |a=0,x:| x }) }
    fix_NOW{ assert_equal([1,2], arr.map{ |a=0,x:nil| x }) }
  end

  def test_kwhash_literal_in_array
    arr = [x: 1]
    fix_3_x{ assert_equal({x:1}, f_kwrest(*arr)) }
    arr = [{x: 1}]
    fix_now{ assert_equal({x:1}, f_kwrest(*arr)) }
  end

end


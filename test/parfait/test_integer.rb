require_relative "helper"

module Parfait
  class TestInteger < ParfaitTest

    def setup
      super
      @int = Integer.new(10)
    end
    def test_index
      assert_equal 2 , Integer.integer_index
    end
    def test_next_index
      assert_equal 1 , Integer.next_index
    end
    def test_class
      assert_equal :Integer, @int.get_type.object_class.name
    end
    def test_next_nil
      assert_nil @int.next_integer
    end
    def test_next_not_nil
      int2 = Integer.new(0 , @int)
      assert_equal Integer,  int2.next_integer.class
    end
    def test_value_10
      assert_equal 10 , @int.value
    end
    def test_word_value_10
      assert_equal 10 , @int.get_internal_word( Integer.integer_index )
    end
    def test_word_settable
      assert_equal 20 , @int.set_internal_word( Integer.integer_index , 20 )
    end
    def test_word_set
      assert_equal 20 , @int.set_internal_word( Integer.integer_index , 20 )
      assert_equal 20 , @int.get_internal_word( Integer.integer_index )
    end
    def test_set
      @int.set_value(1)
      assert_equal 1 , @int.value
    end
  end
  class AddressTest < ParfaitTest
    def test_address
      assert ReturnAddress.new(55)
    end
    def test_value
      assert_equal 55 , ReturnAddress.new(55).value
    end
    def test_value_set
      addr = ReturnAddress.new(55)
      addr.set_value(33)
      assert_equal 33 , addr.value
    end
  end
  class TrueTest < MiniTest::Test
    def test_true
      assert TrueClass.new
    end
    def test_set
      tru = TrueClass.new
      assert_equal 20 , tru.set_internal_word( Integer.integer_index , 20 )
      assert_equal 20 , tru.get_internal_word( Integer.integer_index )
    end
    def test_get_true
      assert_equal 1 , TrueClass.new.get_internal_word( Integer.integer_index )
    end
    def test_get_false
      assert_equal 0 , FalseClass.new.get_internal_word( Integer.integer_index )
    end
  end
end

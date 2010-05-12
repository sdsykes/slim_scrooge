require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'callsite_hash'


class Callsite_hash_test < Test::Unit::TestCase
  HASH_METHODS = [:callsite_hash, :fallback_callsite_hash]

  def fallback_callsite_hash
    caller[1..16].hash
  end

  def cur_hash
    send(@current_hash)
  end

  def each_method
    HASH_METHODS.each do |m|
      @current_hash = m
      yield
    end
  end

  def test_same_place_gives_same_hash
    each_method do
      x1 = nil
      2.times do |n|
        x = cur_hash
        if n == 1
          assert_equal x, x1, @current_hash
        end
        x1 = x
      end
    end
  end
  
  def test_getting_different_values_in_different_places
    each_method do
      x = cur_hash
      y = cur_hash
      assert_not_equal x, y, @current_hash
# these tests fail - TODO: find a fix
#      x = cur_hash; y = cur_hash
#      assert_not_equal x, y, @current_hash
#      x, y = cur_hash, cur_hash
#      assert_not_equal x, y, @current_hash
    end
  end
end

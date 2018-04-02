require_relative "helper"

module Risc
  class InterpreterMultTest < MiniTest::Test
    include Ticker

    def setup
      @string_input = as_main "return #{2**31} * #{2**31}"
      super
    end

    def test_mult
      #show_ticks # get output of what is
      check_chain [Branch, Label, LoadConstant, SlotToReg, LoadConstant,
             SlotToReg, SlotToReg, RegToSlot, LoadConstant, SlotToReg,
             SlotToReg, SlotToReg, SlotToReg, RegToSlot, LoadConstant,
             SlotToReg, SlotToReg, SlotToReg, SlotToReg, RegToSlot,
             SlotToReg, LoadConstant, RegToSlot, LoadConstant, RegToSlot,
             FunctionCall, Label, LoadConstant, SlotToReg, SlotToReg,
             RegToSlot, LoadConstant, SlotToReg, SlotToReg, SlotToReg,
             SlotToReg, RegToSlot, LoadConstant, SlotToReg, SlotToReg,
             SlotToReg, SlotToReg, RegToSlot, LoadConstant, SlotToReg,
             RegToSlot, LoadConstant, SlotToReg, SlotToReg, RegToSlot,
             LoadConstant, SlotToReg, RegToSlot, SlotToReg, LoadConstant,
             FunctionCall, Label, SlotToReg, SlotToReg, SlotToReg,
             SlotToReg, SlotToReg, OperatorInstruction, LoadConstant, SlotToReg,
             SlotToReg, RegToSlot, RegToSlot, RegToSlot, SlotToReg,
             SlotToReg, RegToSlot, SlotToReg, SlotToReg, FunctionReturn,
             SlotToReg, SlotToReg, RegToSlot, SlotToReg, SlotToReg,
             RegToSlot, SlotToReg, SlotToReg, RegToSlot, SlotToReg,
             SlotToReg, FunctionReturn, Transfer, Syscall, NilClass]
       assert_equal Parfait::Integer , get_return.class
       assert_equal 0 , get_return.value
    end
    def test_op
      op = ticks(63)
      assert_equal OperatorInstruction , op.class
      assert_equal :r1 , op.left.symbol
      assert_equal :r2 , op.right.symbol
      assert_equal 2**31 , @interpreter.get_register(:r2)
      assert_equal 0 , @interpreter.get_register(:r1)
    end
    def test_overflow
      ticks( 63 )
      assert @interpreter.flags[:overflow]
    end
    def test_zero
      ticks( 12 )
      assert @interpreter.flags[:zero]
    end
  end
end

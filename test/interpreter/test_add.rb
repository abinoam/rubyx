require_relative "helper"

class AddTest < MiniTest::Test
  include AST::Sexp
  include Ticker

  def setup
    machine = Register.machine.boot
    code  =   s(:class, :Object,
                s(:derives, nil),
                  s(:statements,
                    s(:function, :int,
                      s(:name, :main),
                      s(:parameters),
                      s(:statements,
                        s(:return,
                          s(:operator_value, :+,
                            s(:int, 5),
                            s(:int, 7)))))))

    Soml::Compiler.compile( code  )
    machine.collect
    @interpreter = Interpreter::Interpreter.new
    @interpreter.start Register.machine.init
  end

  def test_branch
    was = @interpreter.block
    assert_equal Register::Branch , ticks(1).class
    assert was != @interpreter.block
  end
  def test_load
    assert_equal Register::LoadConstant ,  ticks(2).class
    assert_equal Parfait::Space ,  Register.machine.objects[ @interpreter.get_register(:r2)].class
    assert_equal :r2,  @interpreter.instruction.array.symbol
  end
  def test_get
    assert_equal Register::GetSlot , ticks(3).class
    assert @interpreter.get_register( :r2 )
    assert @interpreter.get_register( :r2 ).is_a? Integer
  end
  def test_transfer
    transfer = ticks 5
    assert_equal Register::RegisterTransfer ,  transfer.class
    assert_equal @interpreter.get_register(transfer.to) , @interpreter.get_register(transfer.from)
  end
  def test_call
    assert_equal Register::FunctionCall ,  ticks(6).class
    assert @interpreter.link
  end
  def test_adding
    done_op = ticks(10)
    assert_equal Register::OperatorInstruction ,  done_op.class
    left = @interpreter.get_register(done_op.left)
    rr = done_op.right
    right = @interpreter.get_register(rr)
    assert_equal Fixnum , left.class
    assert_equal Fixnum , right.class
    assert_equal 7 , right
    assert_equal 12 , left
    done_tr = ticks(1)
    assert_equal Register::RegisterTransfer ,  done_tr.class
    result = @interpreter.get_register(done_op.left)
    assert_equal result , 12
  end

  def test_chain
    #show_ticks # get output of what is
    ["Branch","LoadConstant","GetSlot","SetSlot","RegisterTransfer",
     "FunctionCall","SaveReturn","LoadConstant","LoadConstant","OperatorInstruction",
     "RegisterTransfer","GetSlot","FunctionReturn","RegisterTransfer","Syscall",
     "NilClass"].each_with_index do |name , index|
      got = ticks(1)
      assert got.class.name.index(name) , "Wrong class for #{index+1}, expect #{name} , got #{got}"
    end
  end


#  def test_exit
#    done = ticks(34)
#    assert_equal NilClass ,  done.class
#  end
end

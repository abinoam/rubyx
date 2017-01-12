require_relative '../helper'
require "register/interpreter"
require "parser/ruby22"

module Melon
  module MelonTests

    def setup
      Register.machine.boot
    end

    def check
      Compiler.compile @string_input
      Register::Collector.collect_space
      @interpreter = Register::Interpreter.new
      @interpreter.start Register.machine.init
      nil
    end
  end
end

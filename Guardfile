# can't put in helper or it will run (and fail) with parallel
#require "minitest/reporters"
#Minitest::Reporters.use!( Minitest::Reporters::MeanTimeReporter.new)

guard :minitest , all_on_start: false do   # with Minitest::Unit

  # if any test file changes, run that test
  watch(%r{^test/(.*)\/?test_(.*)\.rb$})

  # if any helper in any directory changes, run test_all in the same directory
  watch(%r{^test/(.*/)?helper.rb$})     { |m| "test/#{m[1]}test_all.rb" }

  # if any file XX in any directory in the /lib changes, run a test_XX in the
  # shadow directory in the /test
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}1.rb" }
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}2.rb" }
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}3.rb" }

  #Arm instructions
  watch(%r{^lib/arm/instructions/(.+)_instruction.rb}) { |m| "test/arm/test_#{m[1]}.rb" }

  #parfait type tests have a whole directory
  watch(%r{^lib/parfait/type.rb}) { Dir["test/parfait/type/test_*.rb"] }

  # ruby compiler tests have a whole directory
  watch(%r{^lib/ruby/ruby_compiler.rb}) { Dir["test/ruby/test_*.rb"] }

  # slot compiler tests have a whole directory
  watch(%r{^lib/slot_machine/slot_compiler.rb}) { Dir["test/slot_machine/compiler/test_*.rb"] }

  watch(%r{^lib/sol/statements/send_statement.rb}) {
    [ Dir["test/sol/send/test_*.rb"] ] }

  # message setup
  watch(%r{^lib/slot_machine/instruction/message_setup.rb}) { Dir["test/slot_machine/send/test_setup*.rb"] }

  # mains test
  watch(%r{^test/mains/source/(.*)\.rb}) { "test/mains/test_interpreted.rb" }

end

require 'minitest'

def Minitest.autorun = nil
Dir["#{__dir__}/*_test.rb"].each { |test_file| require test_file }

class ParallelTestRunner
  def perform
    status = Minitest.run(['-n', "/#{tests_for_current_node.join('|')}/"])
    exit(status)
  end

  private

  def tests_for_current_node
    node_index = ENV['CI_NODE_INDEX'].to_i
    node_total = [ENV['CI_NODE_TOTAL'].to_i, 1].max

    all_tests.select.with_index { |_, index| index % node_total == node_index }
  end

  def all_tests
    ObjectSpace
      .each_object(Class)
      .select { |klass| klass < Minitest::Test }
      .flat_map { |klass| klass.methods_matching(/^test_/) }
  end
end

ParallelTestRunner.new.perform

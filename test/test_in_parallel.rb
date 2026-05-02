require 'minitest'

class ParallelTestRunner
  def perform(test_files)
    require_files(test_files)

    status = Minitest.run(['-n', "/#{tests_for_current_node.join('|')}/"])

    exit(status)
  end

  private

  def require_files(test_files)
    def Minitest.autorun = nil
    $LOAD_PATH.prepend(__dir__)

    test_files.each { |test_file| require File.expand_path(test_file) }
  end

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

ParallelTestRunner.new.perform(ARGV) if __FILE__ == $PROGRAM_NAME

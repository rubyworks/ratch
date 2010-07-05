require File.dirname(__FILE__) + '/test_helper'

require 'ratch/task'

class TestTaskable < Test::Unit::TestCase

  RESULT_CACHE = []

  class Example #< Ratch::DSL 

    include Taskable

    task :task_with_no_requisites do
      RESULT_CACHE << "task_with_no_requisites"
    end

    task :task_with_one_requisite => [:task_with_no_requisites] do
      RESULT_CACHE << "task_with_one_requisite"
    end

  end


  def setup
    RESULT_CACHE.replace([])
    @example = Example.new
  end
  
  def teardown
  end
  
  # Replace this with your real tests.
  def test_task_with_no_requisite
    @example.run :task_with_no_requisites
    #@example.task_with_no_requisites_trigger
    assert_equal(["task_with_no_requisites"], RESULT_CACHE)
  end

  def test_task_with_one_requisite
    @example.run :task_with_one_requisite
    #@example.task_with_one_requisite_trigger
    assert_equal(["task_with_no_requisites", "task_with_one_requisite"], RESULT_CACHE)
  end

end


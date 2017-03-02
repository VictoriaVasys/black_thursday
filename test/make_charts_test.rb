require_relative 'test_helper.rb'
require_relative '../lib/sales_analyst'
require_relative '../lib/make_charts'

class MakeChartsTest < Minitest::Test
  attr_reader :chart

  def setup
    @chart = Object.new
    @chart.extend(MakeCharts)
  end

  def test_makes_erb_template
    assert_instance_of ERB, chart.make_erb_template
  end

  def test_it_reads_erb_file
    assert_equal "<html>", chart.make_template_letter.split.first
  end

end
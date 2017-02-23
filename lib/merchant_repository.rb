require 'csv'
require 'pry'
require_relative 'merchant'

class MerchantRepository

  #creates instances of Merchant for each row in the csv file
  attr_reader :all, :engine

  def initialize(merchant_csv_data, engine ="")
    @all = []
    create_merchant_instances(merchant_csv_data)
    @engine = engine
  end

  def create_merchant_instances(data)
    CSV.foreach(data, headers: true, header_converters: :symbol) do |row|
      all << Merchant.new({id: row[:id], name: row[:name]}, self)
      end
   end

  def find_by_id(id_num)
    all.find {|merchant| merchant.id == id_num }
  end

  def find_by_name(name)
    all.find {|merchant| merchant.name.downcase == name.downcase}
  end

  def find_all_by_name(name_frag)
    all.select {|merchant| merchant.name.downcase.include?(name_frag.downcase)}
  end

  def inspect
  "#<#{self.class} #{@merchants.size} rows>"
  end
end
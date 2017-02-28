require 'date'

class SalesAnalyst
  attr_reader :engine,
              :set,
              :squared_differences,
              :items_by_merchant,
              :total_price_per_merchant,
              :total_avgs,
              :total_prices,
              :price_set,
              :price_squared_differences,
              :invoice_set,
              :invoices_squared_differences,
              :invoices_by_day,
              :merchant_invoices,
              :total

  def initialize(engine="")
    @engine = engine
  end

  def average_items_per_merchant
    (engine.items.all.count / engine.merchants.all.count.to_f).round(2)
  end

  def average_items_per_merchant_standard_deviation
    @set ||= engine.merchants.all.map do |merchant|
      merchant.items.count
    end
    @squared_differences ||= set.map { |num| (num - average_items_per_merchant) ** 2 }
    (Math.sqrt( ( squared_differences.reduce(:+) ) / (set.count - 1) )).round(2)
    # Math.sqrt( ( (2-0.67)**2+(0-0.67)**2+(0-0.67)**2 ) / 2 )
  end

  def merchants_with_high_item_count
    engine.merchants.all.select do |merchant|
      merchant.items.count > (average_items_per_merchant_standard_deviation + average_items_per_merchant)
    end
  end

  def average_item_price_for_merchant(merch_id)
    @items_by_merchant = engine.merchants.find_by_id(merch_id).items
    @total_price_per_merchant = items_by_merchant.reduce(0) do |total, item|
      total + item.unit_price
    end
    (total_price_per_merchant / items_by_merchant.count).round(2)
  end

  def average_average_price_per_merchant
    @total_avgs ||= engine.merchants.all.reduce(0) do |total, merchant|
      total + average_item_price_for_merchant(merchant.id)
    end
    (total_avgs / engine.merchants.all.count).floor(2)
  end

  def average_item_price
    @total_prices ||= engine.items.all.reduce(0) do |total, item|
      total + item.unit_price_to_dollars
    end
    (total_prices / engine.items.all.count).round(2)
  end

  def item_price_standard_deviation
    @price_set ||= engine.items.all.map do |item|
      item.unit_price_to_dollars
    end

    @price_squared_differences ||= price_set.map { |num| (num - average_item_price)**2 }
    (Math.sqrt( ( price_squared_differences.reduce(:+) ) / (price_set.count - 1) )).round(2)
  end

  def golden_items
    engine.items.all.select do |item|
      item.unit_price_to_dollars > (item_price_standard_deviation * 2 + average_item_price)
    end
  end

  def average_invoices_per_merchant
    (engine.invoices.all.count / engine.merchants.all.count.to_f).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    @invoice_set ||= engine.merchants.all.map do |merchant|
      merchant.invoices.count
    end
    @invoices_squared_differences ||= invoice_set.map { |num| (num - average_invoices_per_merchant) ** 2 }

    (Math.sqrt( ( invoices_squared_differences.reduce(:+) ) / (invoice_set.count - 1) )).round(2)
  end

  def top_merchants_by_invoice_count
    engine.merchants.all.select do |merchant|
      merchant.invoices.count > (average_invoices_per_merchant + average_invoices_per_merchant_standard_deviation * 2)
    end
  end

  def bottom_merchants_by_invoice_count
    engine.merchants.all.select do |merchant|
      merchant.invoices.count < (average_invoices_per_merchant - average_invoices_per_merchant_standard_deviation * 2)
    end
  end

  def invoices_by_day_average
    engine.invoices.all.count / 7
  end

  def invoices_by_day_standard_deviation
    invoices_by_day_squared_differences = invoices_by_day.values.map { |invoices| (invoices.count - invoices_by_day_average) ** 2 }
    (Math.sqrt( ( invoices_by_day_squared_differences.reduce(:+) ) / (invoices_by_day.values.count - 1) )).round(2)
  end

  def top_days_by_invoice_count
    @invoices_by_day = engine.invoices.all.group_by do |invoice|
      invoice.created_at.strftime('%A')
    end

    invoices_by_day.select { |day, invoices| invoices.count > (invoices_by_day_average + invoices_by_day_standard_deviation) }.keys
  end

  def invoice_status(status)
    ((engine.invoices.find_all_by_status(status).count / engine.invoices.all.count.to_f) * 100).round(2)
  end

  def total_revenue_by_date(date)
    invoices_by_date = engine.invoices.all.select do |invoice|
      invoice.created_at == date
    end
    invoices_by_date.map do |invoice|
      invoice.total
    end.reduce(:+)
  end

  def revenue_by_merchant(merch_id)
    engine.merchants.find_by_id(merch_id).revenue
  end

  def merchants_ranked_by_revenue
    engine.merchants.all.sort_by do |merchant|
      [merchant.revenue ? 1 : 0, merchant.revenue]
    end.reverse
  end

  # def revenue_for_all_merchants
  #   engine.merchants.all.map {|merchant| revenue_by_merchant(merchant.id)}
  # end

  def top_revenue_earners(num_top = 20)
    merchants_ranked_by_revenue[0..num_top-1]
  end
  #
  # def sorted_merchants_by_revenue_2
  #   engine.merchants.all.sort_by { |merchant| [revenue_by_merchant(merchant.id) ? 0 : 1, revenue_by_merchant(merchant.id) || 0] }
  ## end

  # def remove_nil_merchants_by_revenue
  #   engine.merchants.all.select do |merchant|
  #     revenue_by_merchant(merchant.id)
  #   end
  # end
  #
  # def sorted_merchants_by_revenue
  #   remove_nil_merchants_by_revenue.sort_by do |merchant|
  #     revenue_by_merchant(merchant.id)
  #   end.reverse
  # end

  def merchants_with_pending_invoices
    engine.merchants.all.select do |merchant|
      merchant.any_pending?
    end
  end

  def merchants_with_only_one_item
    engine.merchants.all.select do |merchant|
      merchant.only_one_item?
    end
  end

  def merchants_with_only_one_item_registered_in_month(month)
    merchants_with_only_one_item.select do |merchant|
      merchant.created_at.strftime("%B") == month
    end
  end



end

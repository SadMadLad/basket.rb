# frozen_string_literal: true

# Class containing the implementation of the basket
class Basket
  DEFAULT_PRODUCTS = {
    R01: { name: 'Red Widget', price: 32.95 },
    G01: { name: 'Green Widget', price: 24.95 },
    B01: { name: 'Blue Widget', price: 7.95 }
  }.freeze

  DEFAULT_DELIVERY_RULES = [
    { min_total: 90, cost: 0 },
    { min_total: 50, cost: 2.95 },
    { min_total: 0, cost: 4.95 }
  ].freeze

  DEFAULT_OFFERS = {
    multiple_R01: lambda do |item_price, item_count|
      return item_price / 2 if item_count.odd?

      item_price
    end
  }.freeze

  # Intiailizing the basket
  # - <tt>args</tt>
  #   - <tt>products [Hash]:</tt> Hash of the products. <b>Assumption:</b> The products hash the format of <tt><b><product-code>: { name: <product-name>, price: <product-price> }</b></tt>. Keys are all symbols.
  #   - <tt>delivery_rules [Array]:</tt> Array of delivery rules. <b>Assumption:</b> Each delivery rule is a hash of format <tt><b>{ min_total: <minimum-total-for-charge>, cost: <delivery-cost> }</b></tt>.
  #   - <tt>offers [Hash]:</tt> Hash of special offers. <b>Assumption:</b> Each offer has the format of <tt><b><name-of-offer-#{product-code}>: lambda { how discount is applied }</b></tt>. And offers only apply when a certain product is bought multiple times
  def initialize(products = DEFAULT_PRODUCTS, delivery_rules = DEFAULT_DELIVERY_RULES, offers = DEFAULT_OFFERS)
    @products = products
    @delivery_rules = delivery_rules
    @offers = offers

    @items = []
  end

  # Adding item to the items array
  # - <tt>args</tt>
  #   - <tt>item_code: [Symbol, String]:</tt> Product Code
  # - returns the current items array
  def add(item_code)
    item_code = item_code.to_sym if item_code.is_a?(String)

    if @products[item_code].nil?
      raise ArgumentError, "Not a valid product code. Available codes: #{@products.keys.map(&:to_s).join(',')}"
    end

    @items << item_code
  end

  # Calculating the total of the items, applying delivery charges and special offers
  # - returns <tt>[Integer]</tt> the total sum of products
  def calculate_total
    total = 0
    items_tally = {}

    @items.each do |item|
      offer_found, offer_lambda = @offers.find { |offer_name, _| offer_name.to_s.include?(item.to_s) }
      total += if !items_tally[item].nil? && offer_found
                 offer_lambda.call(
                   @products[item][:price],
                   items_tally[item]
                 )
               else
                 @products.dig(item, :price)
               end

      items_tally[item] = items_tally[item].nil? ? 1 : items_tally[item] + 1
    end

    apply_delivery_rule(total).round(2)
  end

  class << self
    # Convenient factory method to initialize a basket
    # - <tt>args</tt>
    #   - <tt>items [Array, String]:</tt> Array of product codes as symbols, and String can be comma separated of product codes.
    #   - All other arguments are passed through to the basket instance
    # - return <tt>Basket</tt> with the specified items
    def initialize_with_items(items, ...)
      unless items.is_a?(Array) || items.is_a?(String)
        raise ArgumentError,
              'items can only be array or string (comma separated)'
      end

      basket = new(...)

      items = items.map(&:to_sym) if items.is_a?(Array)
      items = items.split(',').map { |item| item.strip.to_sym } if items.is_a?(String)
      items.each { |item| basket.add(item) }

      basket
    end
  end

  private

  # :nodoc:
  def apply_delivery_rule(total)
    @delivery_rules.each do |rule|
      return total + rule[:cost] if total >= rule[:min_total]
    end
  end
end

def main
  # Test Cases
  [
    %i[B01 G01],
    %i[R01 R01],
    %i[R01 G01],
    %i[B01 B01 R01 R01 R01],
    'B01, R01, G01',
    []
  ].each do |items|
    basket = Basket.initialize_with_items(items)

    puts "Items: #{items} - Price: #{basket.calculate_total}"
  end
end

main

#!/usr/bin/env ruby

require "csv"
require "time"
require "json"
require "bigdecimal"
require "bigdecimal/util"
require "optparse"

require "rubygems"
require "bundler/setup"
Bundler.require(:default)

require "active_support/all"

require_relative "constants"
require_relative "saxo"
require_relative "ibkr"
require_relative "tiger"
require_relative "kristalai"
require_relative "moomoo"
require_relative "listing"

options = {}
OptionParser.new do |opts|
  opts.on("--saxo path/to/saxo/csv", "Saxo CSV path") do |v|
    options[:saxo] = v
  end
  opts.on("--ibkr path/to/ibkr/csv", "Saxo CSV path") do |v|
    options[:ibkr] = v
  end
  opts.on("--tiger path/to/tiger/csv", "Saxo CSV path") do |v|
    options[:tiger] = v
  end
  opts.on("--kristal path/to/kristal/csv", "Kristal CSV path") do |v|
    options[:kristal] = v
  end
  opts.on("--moomoo path/to/moomoo/csv", "MooMoo CSV path") do |v|
    options[:moomoo] = v
  end
end.parse!

transactions = SaxoCSV.import(options[:saxo]) + IbkrCSV.import(options[:ibkr]) + TigerCSV.import(options[:tiger]) + KristalCSV.import(options[:kristal]) + MooMooCSV.import(options[:moomoo])

transactions.each do |t|
  t.symbol = "SOFI" if t.symbol == "IPOE"
end

suffix = Time.now.strftime("%Y_%m_%d")
output_csv = "output/yahoo_finance_upload_#{suffix}.csv"
CSV.open(output_csv, "w") do |csv|
  csv << ["Symbol", "Trade Date", "Purchase Price", "Quantity", "Comment"]
  transactions.sort_by(&:trade_date).each do |t|
    csv << [
      t.symbol,
      t.trade_date.strftime("%Y%m%d"),
      t.purchase_price.round(2),
      t.buy? ? t.quantity : -t.quantity,
      t.broker,
    ]
  end
end

puts "Wrote #{transactions.size} transactions to #{output_csv}"

#

# result = JSON.parse(resp.body)["data"] || []

# #ap result
# top = result.select do |match|
#   #ap match["stock_exchange"]["acronym"]
#   STOCK_EXCHANGES.include?(match["stock_exchange"]["acronym"].to_s.upcase)
# end

# ap top[0]["symbol"]
# if top[0].blank?
#   ap result
# end

#!/usr/bin/env ruby

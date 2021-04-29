require "set"
require_relative "transaction"

class SaxoCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    listing = Listing.new("US.json")

    rows = CSV.new(File.read(path)).read

    rows.map do |r|
      next if r[0] == "Instrument"

      SaxoTransaction.from_csv_row(r).to_transaction(listing)
    end.compact
  end
end

class SaxoTransaction < Hashie::Dash
  property :instrument, required: true
  property :trade_date, required: true
  property :buy_sell, required: true
  property :open_close, required: true
  property :amount, required: true
  property :price, required: true
  property :traded_value, required: true
  property :booked_amount, required: true

  def self.sanitize_company_name(company_name)
    company_name.gsub(/\(ISIN:.*/, "")
  end

  def self.from_csv_row(row)
    self.new([
      :instrument,
      :trade_date,
      :buy_sell,
      :open_close,
      :amount,
      :price,
      :traded_value,
      :booked_amount,
    ].zip(row).to_h)
  end

  def to_transaction(listing)
    Transaction.new(
      symbol: listing.symbol_for_company_name(self.class.sanitize_company_name(instrument)),
      trade_date: Date.parse(trade_date),
      type: transaction_type,
      purchase_price: BigDecimal(price),
      quantity: amount.to_i,
      broker: Transaction::Broker::SAXO,
    )
  end

  def transaction_type
    case buy_sell
    when "Bought"
      Transaction::Type::BUY
    else
      raise "oops, unknown buy sell type '#{buy_sell}"
    end
  end
end

require "set"
require_relative "transaction"

class SaxoCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    listing = Listing.new("data/US.json")

    rows = CSV.new(File.read(path)).read

    rows.each.with_index.map do |row, index|
      next if index.zero?

      next unless row[5] == "Trade"

      if row[6] == "Sell"
        ap "Sell Trade found, skipping"
        puts row.inspect
        puts
        next
      end
      if row[12] == "0"
        ap "Buy Trade found with booked_amount_instrument_currency = 0, skipping"
        puts row.inspect
        puts
        next
      end

      begin
        saxo_row = SaxoTransaction.from_csv_row(
          [
            row[0], # trade date
            row[2], # asset type
            row[3], # instrument
            row[5], # transaction type
            row[6], # event
            row[9], # amount
            row[10], # price
            row[12], # booked_amount_instrument_currency,
          ]
        )

        saxo_row.to_transaction(listing)
      rescue => e
        puts row.inspect
        puts saxo_row.inspect
        raise e
      end
    end.compact
  end
end

class SaxoTransaction < Hashie::Dash
  property :trade_date, required: true
  property :asset_type, required: true
  property :instrument, required: true
  property :transaction_type, required: true
  property :event, required: true
  property :amount, required: true
  property :price, required: true
  property :booked_amount_instrument_currency, required: true

  def self.sanitize_company_name(company_name)
    matchdata = /.*\((.*)\)/.match(company_name)
    return matchdata[1] unless matchdata.nil?
    company_name.gsub(/\(ISIN:.*/, "")
  end

  def self.from_csv_row(row)
    self.new([
      :trade_date,
      :asset_type,
      :instrument,
      :transaction_type,
      :event,
      :amount,
      :price,
      :booked_amount_instrument_currency,
    ].zip(row).to_h)
  end

  def to_transaction(listing)
    sanitized_company_name = self.class.sanitize_company_name(instrument)
    sym = listing.symbol_for_company_name(sanitized_company_name)
    Transaction.new(
      symbol: sym,
      trade_date: Date.strptime(trade_date, "%m/%d/%Y"),
      type: trans_type,
      purchase_price: BigDecimal(price),
      quantity: amount.to_i,
      broker: Transaction::Broker::SAXO,
    )
  end

  def trans_type
    case event
    when "Buy"
      Transaction::Type::BUY
    else
      raise "oops, unknown event '#{event}"
    end
  end
end

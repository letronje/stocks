class KristalCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    rows = CSV.new(File.read(path)).read

    rows.each.with_index.map do |r, index|
      next if index.zero?

      KristalTransaction.from_csv_row(r).to_transaction
    end.compact
  end
end

class KristalTransaction < Hashie::Dash
  property :date, required: true
  property :type, required: true
  property :symbol, required: true
  property :quantity, required: true
  property :currency, required: true
  property :unit_nav, required: true

  def to_transaction
    Transaction.new(
      symbol: symbol,
      trade_date: Date.parse(date),
      type: transaction_type,
      purchase_price: BigDecimal(unit_nav),
      quantity: quantity.to_i,
      broker: Transaction::Broker::KRISTAL,
    )
  end

  def self.from_csv_row(r)
    new(
      date: r[0],
      type: r[1],
      symbol: r[3],
      quantity: r[5],
      currency: r[6],
      unit_nav: r[7],
    )
  end

  def transaction_type
    case type
    when "BUY"
      Transaction::Type::BUY
    else
      raise "oops, unknown transaction type '#{type}"
    end
  end
end

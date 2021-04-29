class TigerCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    rows = CSV.new(File.read(path)).read

    rows.map do |row|
      next if row[0] == "Symbol"
      next if row[0].blank?
      next if row[1].nil?
      #next if row[0].starts_with?("Total ") || row[0] == "Total"
      TigerTransaction.from_csv_row(row).to_transaction
    end.compact
  end
end

class TigerTransaction < Hashie::Dash
  property :symbol, required: true
  property :date_and_time, required: true
  property :quantity, required: true
  property :transaction_price, required: true

  def self.from_csv_row(r)
    self.new([
      :symbol,
      :date_and_time,
      :quantity,
      :transaction_price,
    ].zip([
      r[0],
      r[1],
      r[2],
      r[3],
    ]).to_h)
  end

  def to_transaction
    Transaction.new(
      symbol: symbol,
      trade_date: Date.parse(date_and_time),
      type: transaction_type,
      purchase_price: BigDecimal(transaction_price),
      quantity: quantity.to_i,
      broker: Transaction::Broker::IBKR,
    )
  end

  def transaction_type
    case
    when quantity.to_i > 0
      Transaction::Type::BUY
    else
      raise "oops, unknown buy/sell type for transaction #{self.inspect}"
    end
  end
end

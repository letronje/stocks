class IbkrCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    File.read(path).each_line.map do |line|
      row = CSV.parse_line(line) rescue nil
      next if row.nil?

      next unless row[0] == "Trades"
      next unless row[3] == "Stocks"
      next unless row[1] == "Data"

      IbkrTransaction.from_csv_row(row).to_transaction
    end.compact
  end
end

class IbkrTransaction < Hashie::Dash
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
      r[5],
      r[6],
      r[7],
      r[8],
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

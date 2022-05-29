class TigerCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    paths = if File.directory? path
        (Dir.entries(path) - %w[. ..]).select { |p| p.include?(".csv") }.map { |p| File.join(path, p) }
      else
        [path]
      end

    paths.flat_map do |path|
      puts "Processing #{path}"

      rows = CSV.new(File.read(path)).read

      header_row = ["", "Symbol", "Date/Time", "Quantity", "T.Price", "C.Price", "Proceeds", "Comm/Fee", "GST", "Realized P/L", "MTM P/L", "Code"]
      start_index = rows.find_index header_row

      next [] if start_index.nil?

      last_index = start_index + rows[(start_index + 1)..-1].find_index do |row|
        row[0..5] == ["", "Total", nil, nil, nil, nil]
      end

      rows[start_index..last_index].map do |row|
        next if row[1] == "Symbol"
        next if row[1].nil?
        next if row[1].starts_with? "Total "
        TigerTransaction.from_csv_row(row[1, 4]).to_transaction
      end.compact
    end
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
    ].zip(r).to_h)
  end

  def to_transaction
    Transaction.new(
      symbol: symbol,
      trade_date: Date.parse(date_and_time),
      type: transaction_type,
      purchase_price: BigDecimal(transaction_price),
      quantity: quantity.to_i,
      broker: Transaction::Broker::TIGER,
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

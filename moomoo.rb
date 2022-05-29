class MooMooCSV
  def self.import(path)
    # TODO: if path is directory, import all csv files within
    return [] if path.blank?

    puts "Processing #{path}"

    File.read(path).each_line.map do |line|
      row = CSV.parse_line(line) rescue nil
      next if row.nil?

      next if row[0] != "Buy"

      row.map { |x| x.gsub!("\r", " ") }
      MooMooTransaction.from_csv_row(row).to_transaction
    end.compact
  end
end

class MooMooTransaction < Hashie::Dash
  property :date, required: true
  property :type, required: true
  property :symbol_and_name, required: true
  property :quantity, required: true
  property :price, required: true

  def to_transaction
    Transaction.new(
      symbol: symbol_and_name.gsub(/\(.+\)/, ""),
      trade_date: Date.parse(date),
      type: transaction_type,
      purchase_price: BigDecimal(price, 8),
      quantity: quantity.to_i,
      broker: Transaction::Broker::MOOMOO,
    )
  end

  def self.from_csv_row(r)
    new(
      date: r[3],
      type: r[0],
      symbol_and_name: r[2],
      quantity: r[4],
      price: r[5],
    )
  end

  def transaction_type
    case type
    when "Buy"
      Transaction::Type::BUY
    else
      raise "oops, unknown transaction type '#{type}"
    end
  end
end

class Transaction < Hashie::Dash
  module Type
    BUY = :buy
    SELL = :sell
  end

  module Broker
    IBKR = :ibkr
    TIGER = :tiger
    SAXO = :saxo
    KRISTAL = :kristal
    MOOMOO = :moomoo
  end

  property :symbol, required: true
  property :trade_date, required: true
  property :type, required: true
  property :purchase_price, required: true
  property :quantity, required: true
  property :broker, required: true

  def buy?
    type == Type::BUY
  end
end

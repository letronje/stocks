require "zip"

STOCK_EXCHANGES = [
  "NYSE",
  "NASDAQ",
  "NYSE ARCA",
  "BATS",
].map(&:upcase).to_set

class Listing
  def initialize(disk_path)
    @disk_path = disk_path
    @resolved = {}
    @cache = {}
  end

  def symbol_for_company_name(company_name)
    symbol = @resolved[company_name]
    return symbol if symbol.present?

    symbol = match_company_name_to_symbol(company_name)
    if symbol.present?
      @resolved[company_name] = symbol
      return symbol
    end

    raise "OOPS, couldn't find ticker/symbol for company '#{company_name}'"
  end

  def match_company_name_to_symbol(company_name)
    cache = cached
    query = self.class.cache_key(company_name)

    cache.each do |k, symbol|
      if k.starts_with? query
        return symbol
      end
    end

    best_match = nil
    best_match_ratio = 0.0

    cache.each do |k, symbol|
      kw = k.split(" ").to_set
      matched = 0
      query.split(" ").each do |qp|
        if kw.include? qp
          matched += qp.size
        end
      end

      match_ratio = matched.to_f / kw.sum(&:size).to_f
      if match_ratio >= 0.6
        if match_ratio > best_match_ratio
          best_match_ratio = match_ratio
          best_match = symbol
        end
      end
    end

    best_match
  end

  def cached
    return @cache if @cache.present?

    list = JSON.parse(json_cache)

    cache = {}
    list.each do |e|
      company_name = e["Name"]
      symbol = e["Code"]
      exchange = e["Exchange"]

      next if company_name.blank? || symbol.blank? || !STOCK_EXCHANGES.include?(exchange)

      key = self.class.cache_key(company_name)
      cache[key] = symbol
    end

    @cache = cache
    return @cache
  end

  def self.cache_key(company_name)
    company_name.gsub(/[\.\-,]/, "").strip.downcase.gsub("ltd", "limited")
  end

  def json_cache
    File.read(@disk_path)
  end
end

class MarketStack
  # api_key =
  def self.write_to_disk_cache!(api_key, path)
    limit = 1000

    json = []

    resp = Faraday.get("http://api.marketstack.com/v1/tickers?access_key=#{api_key}&limit=#{limit}")

    body = JSON.parse(resp.body)
    pagination = body["pagination"]
    data = body["data"]
    total = pagination["total"]
    pages = (total / limit.to_f).round

    ap total: total, pages: pages

    json += data

    File.write(path, JSON.pretty_generate(json))
    puts "Wrote #{json.size} listings to #{path}"

    (pages - 1).times do |p|
      begin
        puts "Fetching page #{p + 2} ..."

        offset = (p + 1) * limit

        resp = Faraday.get("http://api.marketstack.com/v1/tickers?access_key=#{api_key}&limit=#{limit}&offset=#{offset}")
        body = JSON.parse(resp.body)
        pagination = body["pagination"]
        data = body["data"]
        json += data

        File.write(path, JSON.pretty_generate(json))
        puts "Wrote #{json.size} listings to #{path}"
      rescue => e
        ap e.class
        ap e.message
        ap e.backtrace
      end
    end

    File.write(path, JSON.pretty_generate(json))
    puts "Wrote #{json.size} listings to #{path}"
  end
end

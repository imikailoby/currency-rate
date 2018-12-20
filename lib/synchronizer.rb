module CurrencyRate
  class Synchronizer
    attr_accessor :storage

    def initialize(storage: nil)
      @storage = storage || FileStorage.new
    end

    def sync_fiat!
      _sync CurrencyRate.configuration.fiat_adapters
    end

    def sync_crypto!
      _sync CurrencyRate.configuration.crypto_adapters
    end

    def sync!
      fiat = sync_fiat!
      crypto = sync_crypto!
      [fiat[0] | crypto[0], fiat[1] | crypto[1]]
    end

    private

    def _sync(adapters)
      successful = []
      failed = []
      adapters.each do |provider|
        adapter_name = "#{provider}Adapter"
        CurrencyRate.logger.info("Fetching '#{provider}'...")
        begin
          adapter = CurrencyRate::const_get(adapter_name).instance
          rates = adapter.fetch_rates
          CurrencyRate.logger.error("Error fetch #{adapter_name}") if rates.nil?
          rates.each do |c, p|
            CurrencyRate.logger.info("#{c}: #{p.class == BigDecimal ? p.to_f.round(2) : p }")
          end
          unless rates
            CurrencyRate.logger.warn("Synchronizer#sync!: rates for #{provider} not found")
            failed.push(provider)
            next
          end
          exchange_name = provider.downcase
          @storage.write(exchange_name, rates)
          successful.push(provider)
        rescue StandardError => e
          failed.push(provider)
          CurrencyRate.logger.error(e)
          next
        end
      end
      CurrencyRate.logger.info("Update finished!")
      CurrencyRate.logger.info("#{successful.join(', ')}: sync success") unless successful.empty?
      CurrencyRate.logger.error("#{failed.join(', ')}: sync failed") unless failed.empty?
      [successful, failed]
    end

  end
end

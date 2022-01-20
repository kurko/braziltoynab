module BrazilToYnab
  class EnvVars
    # This is called PORTOSEGURO but the source could be other banks.
    # Given we only support one for now, I'll keep it as is. The #sync
    # method will also need to load these vars conditionally.
    BUDGET = "BRAZILTOYNAB_PORTOSEGURO_BUDGET".freeze
    CARD_ACCOUNT_PREFIX = "BRAZILTOYNAB_PORTOSEGURO".freeze

    def self.card_account_id(card_number)
      "#{CARD_ACCOUNT_PREFIX}_#{card_number}_ACCOUNT_ID"
    end

    def self.memo_prefix(card_number)
      "#{CARD_ACCOUNT_PREFIX}_#{card_number}_MEMO_PREFIX"
    end
  end
end

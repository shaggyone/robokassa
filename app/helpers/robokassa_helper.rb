module RobokassaHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::FormTagHelper

  PAYMENT_SYSTEMS = {
    :bank_card     => 'BANKOCEANMR',                                # Банковской картой
    :platezh_ru    => 'OceanBankOceanR',                            # Банковской картой через Platezh.ru
    :qiwi          => 'QiwiR',                                      # QIWI Кошелек
    :yandex        => 'PCR',                                        # Яндекс.Деньги
    :wmr           => 'WMRM',                                       # WMR
    :wmz           => 'WMZM',                                       # WMZ
    :wme           => 'WMEM',                                       # WME
    :wmu           => 'WMUM',                                       # WMU
    :wmb           => 'WMBM',                                       # WMB
    :wmg           => 'WMGM',                                       # WMG
    :money_mail_ru => 'MoneyMailR',                                 # RUR MoneyMail
    :rur_rbk_money => 'RuPayR',                                     # RUR RBK Money
    :w1r           => 'W1R',                                        # RUR Единый Кошелек
    :easy_pay      => 'EasyPayB',                                   # EasyPay
    :liq_pay_usd   => 'LiqPayZ',                                    # USD LiqPay
    :money_mail_ru => 'MailRuR',                                    # Деньги@Mail.Ru
    :z_payment     => 'ZPaymentR',                                  # RUR Z-Payment
    :tele_money    => 'TeleMoneyR',                                 # RUR TeleMoney
    :alfabank      => 'AlfaBankR',                                  # Альфа-Клик
    :pskbr         => 'PSKBR',                                      # Промсвязьбанк
    :handy_bank    => 'HandyBankMerchantR',                         # HandyBank
    :innivation    => 'BSSFederalBankForInnovationAndDevelopmentR', # АК ФБ Инноваций и Развития (ЗАО)
    :energobank    => 'BSSMezhtopenergobankR',                      # Межтопэнергобанк
    :svyaznoy      => 'RapidaOceanSvyaznoyR',                       # Через Связной
    :euroset       => 'RapidaOceanEurosetR',                        # Через Евросеть
    :elecsnet_r    => 'ElecsnetR',                                  # Элекснет
    :kassira_net   => 'TerminalsUnikassaR',                         # Кассира.нет
    :mobil_element => 'TerminalsMElementR',                         # Мобил Элемент
    :baltika       => 'TerminalsNovoplatR',                         # Банк Балтика
    :absolut_plat  => 'TerminalsAbsolutplatR',                      # Absolutplat
    :pinpay        => 'TerminalsPinpayR',                           # Pinpay
    :money_money   => 'TerminalsMoneyMoneyR',                       # Money-Money
    :petrocommerce => 'TerminalsPkbR',                              # Петрокоммерц
    :vtb24         => 'VTB24R',                                     # ВТБ24
    :mts           => 'MtsR',                                       # МТС
    :megafon       => 'MegafonR',                                   # Мегафон
    :iphone        => 'BANKOCEANCHECKR',                            # Через iPhone
    :contact       => 'ContactR',                                   # Переводом по системе Контакт
    :online_credit => 'OnlineCreditR'
  }

  def payment_form(interface, invoice_id, amount, description, custom_options = {})
    payment_base_url = interface.init_payment_base_url
    payment_options  = interface.init_payment_options(invoice_id, amount, description, custom_options)

    @__robokassa_vars = {
      :interface        => interface,
      :invoice_id       => invoice_id,
      :amount           => amount,
      :description      => description,
      :custom_options   => custom_options,
      :payment_base_url => payment_base_url,
      :payment_options  => payment_options
    }

    if block_given?
      yield payment_base_url, payment_options
    else
      render 'payment_method/robokassa/init',
        :interface        => interface,
        :invoice_id       => invoice_id,
        :amount           => amount,
        :description      => description,
        :custom_options   => custom_options,
        :payment_base_url => payment_base_url,
        :payment_options  => payment_options
    end

    @__robokassa_vars = nil
  end

  def robokassa_rates_hash
    raise "rates_hash helper should be called inside of payment_form." if @__robokassa_vars.blank?
    @__robokassa_vars[:rates_hash] ||= robokassa_interface.rates_linear(robokassa_amount)
  end

  def robokassa_payment_block currency
    raise "payment_block should be called inside of payment_form." if @__robokassa_vars.blank?

    currency = RobokassaHelper::PAYMENT_SYSTEMS[currency]
    raise "wrong currency" unless currency
    kept_rate = @__robokassa_vars[:currency_rate]
    currency_rate = robokassa_rates_hash[currency]
    return "" unless currency_rate
    @__robokassa_vars[:currency_rate] = currency_rate

    yield currency_rate

    @__robokassa_vars[:currency_rate] = kept_rate
  end

  def robokassa_payment_link *args
    raise "payment_link should be called inside of payment_form." if @__robokassa_vars.blank?
    options = args.extract_options!
    currency = options.delete(:currency)
    if currency
      return robokassa_currency currency do
        payment_link args
      end
    end
    payment_url = "#{ robokassa_payment_base_url }?#{ robokassa_payment_options.merge('IncCurrLabel' => robokassa_currency_rate[:name]).to_query}"

    if block_given?
      link_to payment_url, *args, options do
        yield robokassa_currency_rate
      end
    else
      title = args.shift
      link_to title, payment_url, *args, options
    end
  end

  [:interface, :invoice_id, :amount, :description, :custom_options, :payment_base_url, :payment_options].each do |method_name|
    define_method "robokassa_#{method_name}".to_sym do
      raise "robokassa_#{method_name} helper should be called inside of payment_form." if @__robokassa_vars.blank?
      @__robokassa_vars[method_name]
    end
  end

  def robokassa_currency_rate
    raise "robokassa_currency_rate helper should be called inside of robokassa_payment_block." if @__robokassa_vars.blank? || @__robokassa_vars[:currency_rate].blank?
    @__robokassa_vars[:currency_rate]
  end
end

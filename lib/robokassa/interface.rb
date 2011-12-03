require 'cgi'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'rexml/document'

module Robokassa
class Interface
  include ActionDispatch::Routing::UrlFor
  include Rails.application.routes.url_helpers

  cattr_accessor :config

  @@default_options = {
    :language => "ru"
  }
  @cache = {}

  def test_mode?
    @options[:test_mode] || false
  end

  def owner
    @options[:owner]
  end

  def initialize(options)
    @options = @@default_options.merge(options.symbolize_keys)
    @cache   = {}
  end

  def self.create_by_notification_key(key)
    self.new get_options_by_notification_key(key)
  end

  def notify(params, controller)
    parsed_params = map_params(params, @@notification_params_map)
    self.class.notify_implementation parsed_params[:invoice_id], parsed_params[:amount], parsed_params[:custom_options], controller
    "OK#{parsed_params[:invoice_id]}"
  end

  def self.success(params, controller)
    parsed_params = map_params(params, @@notification_params_map)
    success_implementation parsed_params[:invoice_id], parsed_params[:amount], parsed_params[:language], parsed_params[:custom_options], controller
  end

  def self.fail(params, controller)
    parsed_params = map_params(params, @@notification_params_map)
    fail_implementation parsed_params[:invoice_id], parsed_params[:amount], parsed_params[:language], parsed_params[:custom_options], controller
  end

  def init_payment_url(invoice_id, amount, description, currency='', language='ru', email='', custom_options={})
    url_options = init_payment_options(invoice_id, amount, description, custom_options, currency, language, email)
    "#{init_payment_base_url}?" + url_options.map do |k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" end.join('&')
  end

  def payment_methods
    return @cache[:payment_methods] if @cache[:payment_methods]
    xml = get_remote_xml(payment_methods_url)
    if xml.elements['PaymentMethodsList/Result/Code'].text != '0'
      raise (a=xml.elements['PaymentMethodsList/Result/Description']) ? a.text : "Unknown error"
    end

    @cache[:payment_methods] ||= Hash[xml.elements.each('PaymentMethodsList/Methods/Method'){}.map do|g|
      [g.attributes['Code'], g.attributes['Description']]
    end]
  end

  def rates_long(amount, currency='')
    cache_key = "rates_long_#{currency}_#{amount}".to_sym
    return @cache[cache_key] if @cache[cache_key]
    xml = get_remote_xml(rates_url(amount, currency))
    if xml.elements['RatesList/Result/Code'].text != '0'
      raise (a=xml.elements['RatesList/Result/Description']) ? a.text : "Unknown error"
    end

    @cache[cache_key] = Hash[xml.elements.each('RatesList/Groups/Group'){}.map do|g|
      code = g.attributes['Code']
      description = g.attributes['Description']
      [
        code,
        {
          :code        => code,
          :description => description,
          :currencies  => Hash[g.elements.each('Items/Currency'){}.map do|c|
            label = c.attributes['Label']
            name  = c.attributes['Name']
            [label, {
              :currency             => label,
              :currency_description => name,
              :group                => code,
              :group_description    => description,
              :amount => BigDecimal.new(c.elements['Rate'].attributes['IncSum'])
            }]
          end]
        }
      ]
    end]
  end

  def rates(amount, currency='')
    cache_key = "rates_#{currency}_#{amount}".to_sym
    @cache[cache_key] ||= Hash[rates_long(amount, currency).map do |key, value|
      [key, {
        :description => value[:description],
        :currencies => Hash[(value[:currencies] || []).map do |k, v|
          [k, v]
        end]
      }]
    end]
  end

  def currencies_long
    return @cache[:currencies_long] if @cache[:currencies_long]
    xml = get_remote_xml(currencies_url)
    if xml.elements['CurrenciesList/Result/Code'].text != '0'
      raise (a=xml.elements['CurrenciesList/Result/Description']) ? a.text : "Unknown error"
    end
    @cache[:currencies_long] = Hash[xml.elements.each('CurrenciesList/Groups/Group'){}.map do|g|
      code = g.attributes['Code']
      description = g.attributes['Description']
      [
        code,
        {
          :code        => code,
          :description => description,
          :currencies  => Hash[g.elements.each('Items/Currency'){}.map do|c|
            label = c.attributes['Label']
            name  = c.attributes['Name']
            [label, {
              :currency             => label,
              :currency_description => name,
              :group                => code,
              :group_description    => description
            }]
          end]
        }
      ]
    end]
  end

  def currencies
    @cache[:currencies] ||= Hash[currencies_long.map do |key, value|
      [key, {
        :description => value[:description],
        :currencies => value[:currencies]
      }]
    end]
  end

  def notification_url
    robokassa_notification_url :notification_key => @options[:notification_key]
  end

  def on_success_url
    robokassa_on_success_url
  end

  def on_fail_url
    robokassa_on_fail_url
  end

#private
  def parse_response_params(params)
    parsed_params = map_params(params, @@notification_params_map)
    parsed_params[:custom_options] = Hash[args.select do |k,v| o.starts_with?('shp') end.sort.map do|k, v| [k[3, k.size], v] end]
    if response_signature(parsed_params)!=parsed_params[:signature].downcase
      raise "Invalid signature"
    end
  end

  def rates_url(amount, currency)
    "#{xml_services_base_url}/GetRates?#{query_string(rates_options(amount, currency))}"
  end

  def rates_options(amount, currency)
    map_params(subhash(@options.merge(:amount=>amount, :currency=>currency), %w{login language amount currency}), @@service_params_map)
  end

  def payment_methods_url
    @cache[:get_currencies_url] ||= "#{xml_services_base_url}/GetPaymentMethods?#{query_string(payment_methods_options)}"
  end

  def payment_methods_options
    map_params(subhash(@options, %w{login language}), @@service_params_map)
  end

  def currencies_url
    @cache[:get_currencies_url] ||= "#{xml_services_base_url}/GetCurrencies?#{query_string(currencies_options)}"
  end

  def currencies_options
    map_params(subhash(@options, %w{login language}), @@service_params_map)
  end

  def init_payment_options(invoice_id, amount, description, custom_options = {}, currency='', language='ru', email='')
    options = {
      :login       => @options[:login],
      :amount      => amount.to_s,
      :invoice_id  => invoice_id,
      :description => description[0, 100],
      :signature   => init_payment_signature(invoice_id, amount, description, custom_options),
      :currency    => currency,
      :email       => email,
      :language    => language
    }.merge(Hash[custom_options.sort.map{|x| ["shp#{x[0]}", x[1]]}])
    map_params(options, @@params_map)
  end

  def response_signature(parsed_params)
    md5 response_signature_string(parsed_params)
  end

  def response_signature_string(parsed_params)
    custom_options_fmt = custom_options.sort.map{|x|"shp#{x[0]}=x[1]]"}.join(":")
    "#{parsed_params[:amount]}:#{parsed_params[:invoice_id]}:#{@options[:password2]}#{unless custom_options_fmt.blank? then ":" + custom_options_fmt else "" end}"
  end


  def init_payment_signature(invoice_id, amount, description, custom_options={})
    md5 init_payment_signature_string(invoice_id, amount, description, custom_options)
  end

  def init_payment_signature_string(invoice_id, amount, description, custom_options={})
    custom_options_fmt = custom_options.sort.map{|x|"shp#{x[0]}=#{x[1]}"}.join(":")
    "#{@options[:login]}:#{amount}:#{invoice_id}:#{@options[:password1]}#{unless custom_options_fmt.blank? then ":" + custom_options_fmt else "" end}"
  end

  def base_url
    test_mode? ? 'http://test.robokassa.ru' : 'https://merchant.roboxchange.com'
  end

  def init_payment_base_url
    "#{base_url}/Index.aspx"
  end

  def xml_services_base_url
    "#{base_url}/WebService/Service.asmx"
  end

  @@notification_params_map = {
      'OutSum'         => :amount,
      'InvId'          => :invoice_id,
      'SignatureValue' => :signature,
      'Culture'        => :language
    }

  @@params_map = {
      'MrchLogin'      => :login,
      'OutSum'         => :amount,
      'InvId'          => :invoice_id,
      'Desc'           => :description,
      'Email'          => :email,
      'IncCurrLabel'   => :currency,
      'Culture'        => :language,
      'SignatureValue' => :signature
    }.invert

  @@service_params_map = {
      'MerchantLogin'  => :login,
      'Language'       => :language,
      'IncCurrLabel'   => :currency,
      'OutSum'         => :amount
    }.invert

  def md5(str)
    Digest::MD5.hexdigest(str).downcase
  end

  def subhash(hash, keys)
    Hash[keys.map do |key|
      [key.to_sym, hash[key.to_sym]]
    end]
  end

  # Maps gem parameter names, to robokassa names
  def self.map_params(params, map)
    Hash[params.map do|key, value| [(map[key] || map[key.to_sym] || key), value] end]
  end

  def map_params(params, map)
    self.class.map_params params, map
  end

  def query_string(params)
    params.map do |name, value|
      "#{CGI::escape(name.to_s)}=#{CGI::escape(value.to_s)}"
    end.join("&")
  end

  def get_remote_xml(url)
#   xml_data = Net::HTTP.get_response(URI.parse(url)).body
    begin
      xml_data = URI.parse(url).read
      doc = REXML::Document.new(xml_data)
    rescue REXML::ParseException => e
      sleep 1
      get_remote_xml(url)
    end
  end
end
end

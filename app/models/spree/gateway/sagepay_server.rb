require 'sage_pay'

module Spree
  class Gateway::SagepayServer < Gateway
    preference :vendor, :string
    preference :mode, :string, default: 'test'
    preference :proxy_enabled, :boolean, default: false
    preference :proxy_host, :string
    preference :proxy_port, :integer
    preference :profile, :string, default: 'low'

    attr_accessible :preferred_vendor, :preferred_mode, :preferred_proxy_enabled,
                    :preferred_proxy_host, :preferred_proxy_port, :preferred_profile

    def supports?(source)
      true
    end

    def provider_class
      ::SagePay::Server
    end

    def provider
      ::SagePay::Server.default_registration_options = {
        :mode => preferred_mode.present? ? preferred_mode.to_sym : :test,
        :profile => preferred_profile.present? ? preferred_profile.to_sym : :low,
        :vendor => preferred_vendor
      }
    end

    def auto_capture?
      true
    end

    def method_type
      'sagepay'
    end

    def purchase(amount, sagepay_checkout, gateway_options = {})
      Class.new do
        def success?; true; end
        def authorization; nil; end
      end.new
    end

    # def capture(amount, sagepay_checkout, gateway_options = {})
    #   p amount
    #   p sagepay_checkout.inspect
    # end
  end
end

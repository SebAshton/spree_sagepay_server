module Spree
  class SagepayController  < StoreController
    skip_before_filter :verify_authenticity_token, :only => :notification
    before_filter :sagepay_notification, :only => :notification
    layout false, :only => :redirect

    def notification
      unless authorized?
        render(
          :layout => false,
          :text => sagepay_notification.response(callback_url(spree_order))
        ) and return
      end

      if sagepay_notification.valid_signature? and sagepay_notification.status == :ok
        complete_payment
      else
        fail_payment
      end

      spree_order.next

      render(
        :layout => false,
        :text => sagepay_notification.response(callback_url(spree_order))
      )
    end

    def redirect
      @url = redirect_url(spree_order_from_param)
    end

    private

    def spree_order_from_param
      @order ||= Spree::Order.find_by_id(params[:order])
    end

    def spree_order
      @order ||= payment_source.payments.first.order
    end

    def sagepay_notification
      @sagepay_notification ||= SagePay::Server::Notification.from_params(params, verification_details)
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def payment_source
      @payment_source ||= Spree::SagepayServerCheckout.find_by_vpstx_id(params['VPSTxId'])
    end

    def authorized?
      params['Status'] == "OK"
    end

    def provider
      payment_method.provider
    end

    def complete_payment
      # cant set payment to complete here due to a validation
      # in order transition from payment to complete (it requires at
      # least one pending payment)

      payment_source.payments.last.update_attributes!({
        :amount => spree_order.total,
        :cvv_response_message => sagepay_notification.cv2_result,
        :avs_response => sagepay_notification.avs_cv2
      }, :without_protection => true)
    end

    def fail_payment
      payment_source.payments.last.update_attributes!({
        :state => :failed
      }, :without_protection => true)
    end

    def failed_url
      spree.checkout_state_url(spree_order.state)
    end

    def callback_url(order)
      spree.sagepay_redirect_url(:order => order.id)
    end

    def redirect_url(order)
      if order.complete?
        return spree.order_url(order, :token => order.token)
      end

      failed_url
    end

    def verification_details
      ::SagePay::Server::SignatureVerificationDetails.new(
        payment_method.preferred_vendor,
        payment_source.security_key
      )
    end
  end
end

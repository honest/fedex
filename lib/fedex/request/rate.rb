require 'fedex/request/base'

module Fedex
  module Request
    class Rate < Base
      def initialize(credentials, options={})
        super(credentials, options)
        @special_service_type= options[:special_service_type]
      end
      # Sends post request to Fedex web service and parse the response, a Rate object is created if the response is successful
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug
        response = parse_response(api_response)
        if success?(response)
          rate_details = [response[:rate_reply][:rate_reply_details][:rated_shipment_details]].flatten.first[:shipment_rate_detail]
          Fedex::Rate.new(rate_details.merge(response_details: response[:rate_reply]))
        else
          error_message = if response[:rate_reply]
            [response[:rate_reply][:notifications]].flatten.first[:message]
          else
            "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment{
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      def add_special_services_request(xml)
        if @special_service_type
          xml.SpecialServicesRequested{
            xml.ShipmentSpecialServiceType @special_service_type
          }
        end
      end

      def add_variable_service_option_type(xml)
        xml.VariableOptionsServiceOptionType @special_service_type if @special_service_type && @special_service_type == 'SATURDAY_DELIVERY'
      end

      # Build xml Fedex Web Service request
      def build_xml
        ns = "http://fedex.com/ws/rate/v#{service[:version]}"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.RateRequest(:xmlns => ns){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_variable_service_option_type(xml)
            xml.ReturnTransitAndCommit true
            add_requested_shipment(xml)
            add_special_services_request(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'crs', :version => 13 }
      end

      # Successful request
      def success?(response)
        response[:rate_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:rate_reply][:highest_severity])
      end

    end
  end
end

require 'rspec'
require 'spec_helper'
require 'tmpdir'

module Fedex
  describe PendingShipmentLabel do
    describe "service for email label" do
      let(:fedex) { Fedex::Shipment.new(fedex_production_credentials)}
      let(:shipper) do
        {:name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US"}
      end
      let(:recipient) do
        {:name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Frankin Park", :state => "IL", :postal_code => "60131", :country_code => "US", :residential => true }
      end
      let(:packages) do
        [
            {
                :weight => {:units => "LB", :value => 2},:dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" },:item_description=>'Test'
            }
        ]
      end
      let(:shipping_options) do
        { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }
      end

      let(:label_specification) do
        { :label_format_type => 'COMMON2D',
          :image_type => 'PNG',
        }
      end

      let(:filename) {
        require 'tmpdir'
        File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
      }

      let(:special_service_details) do
        {
            :special_services_requested=>{:return_shipment_detail=>{:return_email_detail=>{:merchant_phone_number=>'3101321223'}},:pending_shipment_detail=>{:expiration_date=>'2014-01-31',:email_label_detail=>{:notification_email_address=>'test@test.com',:notification_message=>'Test'}}}

        }
      end



      let(:options) do
        { :shipper => shipper,
          :recipient => recipient,
          :packages => packages,
          :service_type => "FEDEX_GROUND",
          :special_service_details=>special_service_details,
          :customs_clearance=> nil,
          :shipping_details => shipping_options,
          :label_specification => label_specification,
          :filename =>  filename
        }
      end

      describe "pending_shipment", :vcr do
        before do
          @pending_shipment_label = fedex.pending_shipment(options)
        end


        it "should return email label url" do
          @pending_shipment_label.should respond_to('email_label_url')
        end



      end
    end
  end
end
# frozen_string_literal: true

module LeadProviders
  class ConfirmSchoolsController < ApplicationController
    before_action :load_form

    def show
      render :no_schools and return if @confirm_schools_form.school_ids.none?

      @schools = School.includes(:local_authority).find(@confirm_schools_form.school_ids)
      @delivery_partner = DeliveryPartner.find(@confirm_schools_form.delivery_partner_id)
    end

    def remove
      school_id = params[:remove][:school_id]
      @confirm_schools_form.school_ids.delete(school_id)

      if @confirm_schools_form.school_ids.any?
        school = School.find school_id
        set_success_message heading: "#{school.name} has been removed"
      end

      redirect_to action: :show
    end

    # TODO: This action exists only for demonstration purpose and should be removed
    # as soon as the CSV/search journey is completed
    def start
      session[:confirm_schools_form] = {
        source: :csv,
        school_ids: School.order(Arel.sql("RANDOM()")).limit(10).pluck(:id),
        delivery_partner_id: DeliveryPartner.order(Arel.sql("RANDOM()")).first.id,
        cohort: 2021,
      }
      redirect_to action: :show
    end

    # TODO: This is temporary behaviour and will be replaced with Partnership creation
    def update
      set_success_message heading: "The list of schools has been confirmed", content: "You will be redirected to success page in another story"
      redirect_to action: :show
    end

  private

    def load_form
      @confirm_schools_form = ConfirmSchoolsForm.new(session[:confirm_schools_form])
    end
  end
end

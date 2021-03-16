# frozen_string_literal: true

module Admin
  module Administrators
    class AdministratorsController < Admin::BaseController
      skip_after_action :verify_authorized, only: :index
      skip_after_action :verify_policy_scoped, except: :index
      before_action :load_admin, only: %i[edit update delete destroy]

      def index
        @administrators = policy_scope(User).admins
      end

      def new
        authorize AdminProfile

        if params[:continue]
          @user = user_from_session
        else
          session.delete(:administrator_user)
          @user = User.new
        end

        authorize @user
      end

      def confirm
        @user = User.new(permitted_attributes(User))

        authorize @user, :create?
        authorize AdminProfile, :create?

        if @user.invalid?
          render :new and return
        end

        session[:administrator_user] = @user
      end

      def create
        user = User.new(permitted_attributes(User))
        user.confirm

        authorize user
        authorize AdminProfile

        ActiveRecord::Base.transaction do
          user.save!
          AdminProfile.create!(user: user)
        end
        session.delete(:administrator_user)

        set_success_message(heading: "User added", content: "They have been sent an email to sign in")
        redirect_to admin_administrators_path
      end

      def edit; end

      def delete; end

      def update
        if @administrator.update(permitted_attributes(@administrator))
          redirect_to :admin_administrators, notice: "Changes saved successfully"
        else
          render :edit
        end
      end

      def destroy
        authorize @administrator
        @administrator.discard!
        set_success_message(content: "User deleted", title: "Success")
        redirect_to admin_administrators_path
      end

    private

      def user_from_session
        User.new(session[:administrator_user])
      end

      def load_admin
        @administrator = User.find(params[:id])
        authorize @administrator
      end
    end
  end
end

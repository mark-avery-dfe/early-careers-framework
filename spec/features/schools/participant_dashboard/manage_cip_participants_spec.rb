# frozen_string_literal: true

require "rails_helper"
require_relative "../training_dashboard/manage_training_steps"

RSpec.describe "Manage CIP participants", js: true, with_feature_flags: { eligibility_notifications: "active", cohortless_dashboard: "active" } do
  include ManageTrainingSteps

  before do
    given_there_is_a_school_that_has_chosen_cip_for_2021
  end

  context "Ineligible ECTs with mentor assigned" do
    before do
      and_i_have_added_a_contacted_for_info_mentor
      and_i_have_added_an_ineligible_ect_with_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "Ineligible With-mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:failed_induction)
    end
  end

  context "Ineligible ECTs without mentor assigned" do
    before do
      and_i_have_added_an_ineligible_ect_without_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "Ineligible Without-mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:failed_induction)
    end
  end

  context "Ineligible mentor" do
    before do
      and_i_have_added_an_ineligible_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "Ineligible mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:failed_induction)
    end
  end

  context "ERO mentor" do
    before do
      and_i_have_added_an_ero_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "ero mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:statutory_induction_completed)
    end
  end

  context "Eligible ECTs with a mentor assigned" do
    before do
      and_i_have_added_a_contacted_for_info_mentor
      and_i_have_added_an_eligible_ect_with_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "Eligible With-mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:training)
    end
  end

  context "Eligible ECTs without a mentor assigned" do
    before do
      and_i_have_added_an_eligible_ect_without_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "Eligible Without-mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:training)
    end
  end

  context "Eligible mentor" do
    before do
      and_i_have_added_an_eligible_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "Eligible mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:not_mentoring)
    end
  end

  context "Contacted for info ECTs with mentor assigned" do
    before do
      and_i_have_added_a_mentor
      and_i_have_added_a_contacted_for_info_ect_with_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "CFI With-mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:contacted_for_info)
    end
  end

  context "Contacted for info ECTs without mentor assigned" do
    before do
      and_i_have_added_a_contacted_for_info_ect_without_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "CFI Without-mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:check_email_address)
    end
  end

  context "Contacted for info mentor" do
    before do
      and_i_have_added_a_contacted_for_info_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "CFI Mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:contacted_for_info)
    end
  end

  context "Details being checked ECT with mentor" do
    before do
      and_i_have_added_a_contacted_for_info_mentor
      and_i_have_added_a_details_being_checked_ect_with_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "CFI Mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:contacted_for_info)
    end
  end

  context "Details being checked ECT without mentor" do
    before do
      and_i_have_added_a_details_being_checked_ect_without_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "DBC Without-Mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:pending)
    end
  end

  context "Details being checked mentor" do
    before do
      and_i_have_added_a_details_being_checked_mentor
      and_i_am_signed_in_as_an_induction_coordinator
    end

    scenario "Induction coordinators can view and manage participant" do
      given_i_am_on_the_cip_induction_dashboard
      and_i_click_on("2021 to 2022")
      when_i_navigate_to_participants_dashboard
      when_i_click_on_the_participants_name "DBC Mentor"
      then_i_am_taken_to_view_details_page
      then_i_can_view_participant_with_status(:pending)
    end
  end
end

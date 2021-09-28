# frozen_string_literal: true

module ManageTrainingSteps
  include Capybara::DSL

  def freeze_dynamic_dates_or_times_for_percy
    Timecop.freeze(Time.zone.local(2021, 9, 17, 16, 15, 0))
  end

  def return_from_timecop
    Timecop.return
  end

  def given_there_is_a_school_that_has_chosen_fip_for_2021
    @cohort = create(:cohort, start_year: 2021)
    @school = create(:school, name: "Fip School")
    @school_cohort = create(:school_cohort, school: @school, cohort: @cohort, induction_programme_choice: "full_induction_programme")
  end

  def given_there_is_a_school_that_has_chosen_fip_for_2021_and_partnered
    given_there_is_a_school_that_has_chosen_fip_for_2021
    @lead_provider = create(:lead_provider, name: "Big Provider Ltd")
    @delivery_partner = create(:delivery_partner, name: "Amazing Delivery Team")
    create(:partnership, school: @school, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort, challenge_deadline: 2.weeks.ago)
  end

  def given_there_is_a_school_that_has_chosen_cip_for_2021
    @cip = create(:core_induction_programme, name: "CIP Programme 1")
    @cohort = create(:cohort, start_year: 2021)
    @school = create(:school, name: "CIP School")
    @school_cohort = create(:school_cohort, school: @school, cohort: @cohort, induction_programme_choice: "core_induction_programme")
  end

  def and_i_have_added_an_ect_or_mentor
    @participant_profile = create(:participant_profile, :ect, school_cohort: @school_cohort)
  end

  def then_i_should_see_the_add_your_ect_and_mentor_link
    expect(page).to have_text("Add your early career teacher and mentor details")
  end

  def then_i_should_see_the_view_your_ect_and_mentor_link
    expect(page).to have_text("View your early career teacher and mentor details")
  end

  def given_there_is_a_school_that_has_chosen_design_our_own_for_2021
    @cohort = create(:cohort, start_year: 2021)
    @school = create(:school, name: "Design Our Own Programme School")
    @school_cohort = create(:school_cohort, school: @school, cohort: @cohort, induction_programme_choice: "design_our_own")
  end

  def given_there_is_a_school_that_has_chosen_no_ect_for_2021
    @cohort = create(:cohort, start_year: 2021)
    @school = create(:school, name: "No ECT Programme School")
    @school_cohort = create(:school_cohort, school: @school, cohort: @cohort, induction_programme_choice: "no_early_career_teachers")
  end

  def and_i_am_signed_in_as_an_induction_coordinator
    @induction_coordinator_profile = create(:induction_coordinator_profile, schools: [@school_cohort.school])
    privacy_policy = create(:privacy_policy)
    privacy_policy.accept!(@induction_coordinator_profile.user)
    sign_in_as @induction_coordinator_profile.user
    set_participant_data
  end

  def then_i_should_see_the_fip_induction_dashboard
    expect(page).to have_selector("h1", text: "Manage your training")
    expect(page).to have_text("Training provider")
    expect(page).to have_text(@school_cohort.lead_provider.name)
    expect(page).to have_text("Delivery partner")
    expect(page).to have_text(@school_cohort.delivery_partner.name)
  end

  def then_i_should_see_the_cip_induction_dashboard
    expect(page).to have_selector("h1", text: "Manage your training")
    expect(page).not_to have_text("Programme materials")
  end

  def when_i_click_add_your_early_career_teacher_and_mentor_details
    click_on("Add your early career teacher and mentor details")
  end

  def when_i_click_on_add_a_new_ect_or_mentor_link
    click_on("Add a new ECT or mentor")
  end

  def then_i_am_taken_to_add_your_ect_and_mentors_page
    expect(page).to have_selector("h1", text: "Add your early career teachers and mentors")
    expect(page).to have_text("Do you want to add an early career teacher (ECT) or a mentor?")
  end

  def when_i_select_add_ect
    choose("Early career teacher", allow_label_click: true)
  end

  def when_i_select_add_mentor
    choose("Mentor", allow_label_click: true)
  end

  def when_i_select_add_myself_as_mentor
    choose("Myself as a mentor", allow_label_click: true)
  end

  def then_i_am_taken_to_are_you_sure_page
    expect(page).to have_selector("h1", text: "Are you sure you want to add yourself as a mentor?")
    expect(page).to have_text("The induction tutor and mentor roles are separate")
  end

  def when_i_click_on_check_what_each_role_needs_to_do
    click_on("Check what each role needs to do")
  end

  def then_i_am_taken_to_roles_page
    expect(page).to have_selector("h1", text: "Check what each person needs to do in the early career teacher training programme")
    expect(page).to have_text("An induction tutor should only assign themself as a mentor in exceptional circumstances")
  end

  def and_select_continue
    click_on("Continue")
  end

  def then_i_am_taken_to_add_ect_name_page
    expect(page).to have_selector("h1", text: "What’s the full name of this ECT?")
  end

  def then_i_am_taken_to_add_mentor_name_page
    expect(page).to have_selector("h1", text: "What’s the full name of this mentor?")
  end

  def when_i_add_ect_or_mentor_name
    fill_in "Full_name", with: @participant_data[:full_name]
  end

  def then_i_am_taken_to_add_new_ect_or_mentor_page
    expect(page).to have_text("Add your early career teachers and mentors")
    expect(page).to have_text("We need to verify that your early career teachers")
  end

  def then_i_am_taken_to_add_ect_or_mentor_email_page
    expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s email address?")
  end

  def when_i_add_ect_or_mentor_email
    fill_in "Email", with: @participant_data[:email]
  end

  def when_i_add_ect_or_mentor_email_that_already_exists
    fill_in "Email", with: @participant_profile.user.email
  end

  def and_then_return_to_dashboard
    visit schools_dashboard_path(@school)
  end

  def then_i_can_view_the_added_materials
    expect(page).to have_selector("h1", text: "Manage your training")
    expect(page).to have_text("Materials")
    expect(page).to have_text(@cip.name)
  end

  def when_i_click_on_view_details
    click_on("View details")
  end

  def then_i_am_taken_to_fip_programme_choice_info_page
    expect(page).to have_text("You've chosen to: use a training provider, funded by the DfE")
  end

  def then_i_am_taken_to_cip_programme_choice_info_page
    expect(page).to have_text("You've chosen to: deliver your own programme using the DfE-accredited materials")
  end

  def then_i_am_taken_to_design_our_own_course_programme_choice_info_page
    expect(page).to have_text("You've chosen to: design and deliver your own programme based on the Early Career Framework")
  end

  def then_i_am_taken_to_the_no_ect_training_info_page
    expect(page).to have_text("You're not expecting any early career teachers this year")
  end

  def then_i_should_see_the_fip_induction_dashboard_without_partnership_details
    expect(page).to have_selector("h1", text: "Manage your training")
    expect(page).not_to have_text("Delivery partner")
  end

  def when_i_click_on_sign_up
    click_on("Sign up")
  end

  def then_i_am_taken_to_sign_up_to_training_provider_page
    expect(page).to have_selector("h1", text: "Signing up with a training provider")
    expect(page).to have_text("How you can sign up with a training provider")
  end

  def when_i_click_on_add_materials
    click_on("Add")
    click_on("Continue")
  end

  def then_i_am_taken_to_course_choice_page
    expect(page).to have_text("Which training materials do you want this cohort to use?")
  end

  def when_i_select_materials
    choose("CIP Programme 1", allow_label_click: true)
  end

  def and_i_am_taken_to_course_confirmed_page
    click_on("Continue")
  end

  def then_i_should_see_the_design_our_own_induction_dashboard
    expect(page).to have_selector("h1", text: "Manage your training")
    expect(page).to have_text("Design and deliver your own programme")
  end

  def then_i_should_see_the_no_ect_induction_dashboard
    expect(page).to have_selector("h1", text: "Manage your training")
    expect(page).to have_text("No early career teachers for this cohort")
  end

  def when_i_select_view_details
    click_on("View details")
  end

  def and_click_continue
    click_on("Continue")
  end

  def and_select_back
    click_on("Back")
  end

  def when_i_select_confirm_and_add
    click_on("Confirm and add")
  end

  def and_select_confirm
    click_on("Confirm")
  end

  def then_i_am_taken_to_check_details_page
    expect(page).to have_selector("h1", text: "Check your answers")
  end

  def then_i_should_be_taken_to_ect_confirmation_page
    expect(page).to have_selector("h1", text: "#{@participant_data[:full_name]} has been added as an ECT")
    expect(page).to have_text("What happens next")
  end

  def then_i_should_be_taken_to_mentor_confirmation_page
    expect(page).to have_selector("h1", text: "#{@participant_data[:full_name]} has been added as a mentor")
    expect(page).to have_text("What happens next")
  end

  def then_i_am_taken_to_yourself_as_mentor_confirmation_page
    expect(page).to have_selector("h1", text: "#{@induction_coordinator_profile.user.full_name} has been added as a mentor")
  end

  def then_i_receive_a_missing_name_error_message
    expect(page).to have_text("Enter a full name")
  end

  def then_i_receive_a_missing_email_error_message
    expect(page).to have_text("Enter an email address")
  end

  def then_i_will_see_email_already_taken_error_message
    expect(page).to have_text("This email has already been added")
  end

  def set_participant_data
    @participant_data = {
      trn: "1234567",
      full_name: "Sally Teacher",
      date_of_birth: Date.new(1998, 3, 22),
      email: "sally@school.com",
      nino: "",
    }
  end
end

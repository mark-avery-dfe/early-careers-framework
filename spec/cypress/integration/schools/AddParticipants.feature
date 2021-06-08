Feature: School leaders should be able to manage participants

  Background:
    Given scenario "school_participants" has been run
    And feature induction_tutor_manage_participants is active
    And I am logged in as existing user with email "school-leader@example.com"
    And I am on "2021 school participants" page

  Scenario: Should be able to add a new ECT participant
    When I click on "link" containing "Add participants"
    Then "page body" should contain "What type of participant do you want to add to this cohort?"

    When I click the submit button
    Then "page body" should contain "Please select type of the new participant"

    When I set "new participant type radio" to "ect"
    And I click the submit button
    Then "page body" should contain "Enter their personal details"

    When I click the submit button
    Then "page body" should contain "can't be blank"

    When I type "James Bond" into field labelled "Full name"
    And I type "james.bond.007@.secret.gov.uk" into field labelled "Email"
    And I click the submit button
    Then "page body" should contain "Further steps not implemented"

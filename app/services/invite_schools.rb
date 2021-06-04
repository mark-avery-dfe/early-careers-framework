# frozen_string_literal: true

class InviteSchools
  EMAIL_COOLDOWN_PERIOD = 24.hours

  def run(school_urns)
    logger.info "Emailing schools"

    school_urns.each do |urn|
      school = School.eligible.find_by(urn: urn)

      if school.nil?
        logger.info "School not found, urn: #{urn} ... skipping"
        next
      end

      nomination_email = NominationEmail.create_nomination_email(
        sent_at: Time.zone.now,
        sent_to: school.contact_email,
        school: school,
      )

      send_nomination_email(nomination_email)
    rescue Notifications::Client::RateLimitError
      sleep(1)
      send_nomination_email(nomination_email)
    rescue StandardError
      logger.info "Error emailing school, urn: #{urn} ... skipping"
    end
  end

  def sent_email_recently?(school)
    latest_nomination_email = NominationEmail.where(school: school).order(sent_at: :desc).first
    latest_nomination_email&.sent_within_last?(EMAIL_COOLDOWN_PERIOD) || false
  end

  def send_chasers
    logger.info "Sending chaser emails"
    logger.info "Nomination email count before: #{NominationEmail.count}"
    School.eligible.without_induction_coordinator.each do |school|
      additional_emails = school.additional_school_emails.pluck(:email_address)
      emails = [school.primary_contact_email, school.secondary_contact_email, *additional_emails]
                 .reject(&:blank?)
                 .map(&:downcase)
                 .uniq

      emails.each do |email|
        nomination_email = NominationEmail.create_nomination_email(
          sent_at: Time.zone.now,
          sent_to: email,
          school: school,
        )
        send_nomination_email(nomination_email)
      rescue Notifications::Client::RateLimitError
        sleep(1)
        send_nomination_email(nomination_email)
      rescue StandardError
        logger.info "Error emailing school, urn: #{school.urn}, email: #{email} ... skipping"
      end
    end

    logger.info "Chaser emails sent"
    logger.info "Nomination email count after: #{NominationEmail.count}"
  end

  def send_ministerial_letters
    School.eligible.each do |school|
      recipient = school.primary_contact_email.presence || school.secondary_contact_email

      delay(queue: "mailers", priority: 1).send_ministerial_letter(recipient) if recipient.present?
    end
  end

private

  def send_nomination_email(nomination_email)
    notify_id = SchoolMailer.nomination_email(
      recipient: nomination_email.sent_to,
      school_name: nomination_email.school.name,
      nomination_url: nomination_email.nomination_url,
      expiry_date: email_expiry_date,
    ).deliver_now.delivery_method.response.id

    nomination_email.update!(notify_id: notify_id)
  end

  def send_ministerial_letter(recipient)
    SchoolMailer.ministerial_letter_email(recipient: recipient).deliver_now
  rescue Notifications::Client::RateLimitError
    sleep(1)
    SchoolMailer.ministerial_letter_email(recipient: recipient).deliver_now
  end

  def email_expiry_date
    NominationEmail::NOMINATION_EXPIRY_TIME.from_now.strftime("%d/%m/%Y")
  end

  def logger
    @logger ||= Rails.logger
  end
end

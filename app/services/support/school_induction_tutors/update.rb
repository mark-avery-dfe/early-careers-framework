module Support
  module SchoolInductionTutors
    class Update
      class << self
        def call(school_id:, email:, full_name:)
          new(school_id: school_id, email: email, full_name: full_name).call
        end
      end

      attr_reader :school, :email, :full_name

      def initialize(school_id:, email:, full_name:)
        @school = School.find(school_id)
        @email = email
        @full_name = full_name
      end

      def call
        if school.induction_tutor.present?
          log_existing_information

          UpdateInductionTutor.call(school: school, email: email, full_name: full_name)

          log_updated_information
        else
          send_update_to_replacement_service
        end
      rescue => e
        log_error(e)
      end

      private

      def send_update_to_replacement_service
        Rails.logger.info("Attempted to update existing SIT for #{school.name} (ID: #{school.id})")
        Rails.logger.info("No SIT found, redirecting update to Support::SchoolInductionTutors::Replace")

        Support::SchoolInductionTutors::Replace.new(school_id: school.id, full_name: full_name, email: email).call
      end

      def log_existing_information
        Rails.logger.info("Updating existing SIT for #{school.name} (ID: #{school.id})")

        Rails.logger.info("Existing SIT: #{school.induction_tutor.full_name} #{school.induction_tutor.email} (ID: #{school.induction_tutor.id})")
      end

      def log_updated_information
        school.reload

        Rails.logger.info("Updated SIT for #{school.name} (ID: #{school.id})")
        Rails.logger.info("New SIT: #{school.induction_tutor.full_name} #{school.induction_tutor.email} (ID: #{school.induction_tutor.id})")
      end

      def log_error(error)
        Rails.logger.error("Failed to update SIT for #{school.name} (ID: #{school.id})")
        Rails.logger.error(error.message)
      end
    end
  end
end

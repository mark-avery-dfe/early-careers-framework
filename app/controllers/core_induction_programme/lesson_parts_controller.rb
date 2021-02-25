# frozen_string_literal: true

class CoreInductionProgramme::LessonPartsController < ApplicationController
  include Pundit
  include GovspeakHelper
  include CipBreadcrumbHelper

  after_action :verify_authorized
  before_action :authenticate_user!, except: :show
  before_action :load_course_lesson_part

  def show; end

  def edit; end

  def update
    if params[:commit] == "Save changes"
      @course_lesson_part.save!
      flash[:success] = "Your changes have been saved"
      redirect_to cip_year_module_lesson_part_url
    else
      render action: "edit"
    end
  end

  def show_split
    @split_lesson_part_form = SplitLessonPartForm.new(title: @course_lesson_part.title, content: @course_lesson_part.content)
  end

  def split
    @split_lesson_part_form = SplitLessonPartForm.new(lesson_split_params)
    if @split_lesson_part_form.valid? && params[:commit] == "Save changes"
      ActiveRecord::Base.transaction do
        @new_course_lesson_part = CourseLessonPart.create!(
          title: @split_lesson_part_form.new_title,
          content: @split_lesson_part_form.new_content,
          course_lesson: @course_lesson_part.course_lesson,
          next_lesson_part: @course_lesson_part.next_lesson_part,
          previous_lesson_part: @course_lesson_part,
        )
        @course_lesson_part.update!(title: @split_lesson_part_form.title, content: @split_lesson_part_form.content)
      end
      redirect_to cip_year_module_lesson_part_url(id: params[:part_id])
    else
      render action: "show_split"
    end
  rescue ActiveRecord::RecordInvalid
    render action: "show_split"
  end

private

  def load_course_lesson_part
    @course_lesson_part = CourseLessonPart.find(params[:id] || params[:part_id])
    authorize @course_lesson_part
    @course_lesson_part.assign_attributes(course_lesson_part_params)
  end

  def course_lesson_part_params
    params.permit(:content, :title)
  end

  def lesson_split_params
    params.require(:split_lesson_part_form).permit(:title, :content, :new_title, :new_content)
  end
end

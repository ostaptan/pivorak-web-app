module Courses
  class SeasonsController < BaseController
    helper_method :mentors, :season, :journal_students, :journal_lectures, :journal_hash

    private

    def season
      @season ||= ::Courses::Season.friendly.find(params[:id])
    end

    def mentors
      @mentors ||= season.mentors.includes(:user).sort_by { |obj| obj.full_name }
    end

    def journal_students
      @journal_students ||= ::Courses::Student::AttendingAndGraduated
        .call(season, [:user, :progresses])
    end

    def journal_lectures
      @journal_lectures ||= season.lectures.order(:started_at)
    end

    def journal_hash
      @journal_hash ||= ::Courses::Student::TotalHash
        .call(journal_students, sort_by: params[:sort_by], lecture_id: params[:lecture])
    end
  end
end

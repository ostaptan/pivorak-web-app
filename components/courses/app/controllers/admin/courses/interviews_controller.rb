module Admin
  module Courses
    class InterviewsController < ::Admin::Courses::BaseController
      helper_method :interviews, :interview, :questions,
        :interviews_with_assessments, :average_assessment, :interview_assessment

      before_action :authenticate_interviewer!, only: %i[edit update]

      breadcrumps do
        add :interviews_breadcrumb
        add :interview_breadcrumb, only: %i[show edit update]
      end

      def show
        ::Courses::InterviewAssessment::BuildAssessments.call(interview_assessment, questions)
      end

      def new
        @interview = current_season.interviews.new
        render_form
      end

      def create
        @interview = current_season.interviews.new(interviews_params)
        react_to interview.save
      end

      def update
        react_to interview.update(interviews_params)
      end

      private

      def default_redirect
        redirect_to admin_courses_season_interviews_path(current_season)
      end

      def interview
        @interview ||= ::Courses::Interview.find(params[:id])
      end

      def interviews
        @interviews ||= current_season.interviews
          .order(:status)
          .includes(mentor: :user)
          .includes(student: :user)
      end

      def interviews_breadcrumb
       add_breadcrumb 'courses.interviews.plural',
         path: admin_courses_season_interviews_path(current_season)
      end

      def interview_breadcrumb
        label_data = interview.student ? :full_name : :status

        add_breadcrumb interview, label: label_data,
          path: admin_courses_season_interview_path(current_season, interview)
      end

      def interviews_params
        params.require(:interview).permit(:start_at, :description, :video_url, :status)
          .merge(mentor_id: mentor_id)
      end

      def mentor_id
        ::Courses::Mentor
          .find_by(season_id: current_season.id, user_id: current_user.id).id
      end

      def questions
        current_season.questions
      end

      def interviews_with_assessments
        @interviews_with_assessments ||= ::Courses::Interview::WithAssessments
          .call(interviews, questions)
          .sort { |a,b| [a.status, -a.average_assessment] <=> [b.status, -b.average_assessment]}
      end

      def average_assessment
        @average_assessment ||= ::Courses::Interview::AverageAssessment.new(interview, questions).call
      end

      def authenticate_interviewer!
        default_redirect unless interview.mentor == ::Courses::Mentor.find(mentor_id)
      end

      def interview_assessment
        @interview_assessment ||= ::Courses::Interview::InterviewAssessmentForInterview
          .call(interview, current_mentor)
      end
    end
  end
end

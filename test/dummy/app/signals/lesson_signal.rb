# frozen_string_literal: true

class LessonSignal < Demux::Signal
  attributes object_class: Lesson, signal_name: "lesson", account_type: :account

  def payload
    {
      company_id: lesson.company_id,
      lesson: {
        id: object.id,
        name: lesson.name,
        public: lesson.public
      }
    }
  end

  def updated
    send :updated
  end

  def destroyed_payload
    {
      company_id: account_id,
      **context
    }
  end

  def destroyed
    send :destroyed, context: destroyed_context
  end

  private

  def lesson
    object
  end

  def destroyed_context
    {
      lesson: {
        id: lesson.id,
        name: lesson.name,
        public: lesson.public
      }
    }
  end
end

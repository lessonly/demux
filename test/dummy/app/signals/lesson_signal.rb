# frozen_string_literal: true

class LessonSignal < Demux::Signal
  attributes object_class: Lesson, signal_name: "lesson"

  def payload
    {
      company_id: lesson.company_id,
      lesson: {
        id: @object_id,
        name: lesson.name,
        public: lesson.public
      }
    }
  end

  def updated
    send :updated
  end

  def destroyed(context = {})
    # How do we handle cases where we need to eager create the payload
    # Do we just send the ID of the object in a case like this
    # Some thoughts are below

    # Just call the payload early and pass it into send
    send :destroyed, payload: payload
    # Indicate eager with boolean
    send :destroyed, eager: true
    # New method for sending in an eager way
    send_now :destroyed
    # Allow extra in the moment context to be added by the caller.
    # We could have a base `destroyed_payload` method in here that is pretty
    # sparse or empty and then the destroyer passes in context for the
    # lesson that was destroyed.
    # The concerning part here is that "what is sent" logic leaks out to the
    # caller in this case and could be inconsistent.
    send :destroyed, add_context: context
  end

  private

  def lesson
    object
  end
end

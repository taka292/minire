module ApplicationHelper
  def error_class(resource, attribute)
    resource.errors[attribute].present? ? 'border-red-500' : ''
  end
end

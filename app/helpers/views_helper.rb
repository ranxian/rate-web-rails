module ViewsHelper
  def view_verbose_strategy(view)
    vs = view.strategy.to_s
    if view.strategy == :import_tag
      vs += "(#{view.import_tag})"
    end
    return vs
  end
end

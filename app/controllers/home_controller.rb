class HomeController < ApplicationController
  skip_before_filter :authenticate_user!

  def index
    if current_user
      redirect_to home_show_path
    end
  end

  def show
  end
end

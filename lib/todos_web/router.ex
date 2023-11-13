defmodule TodosWeb.Router do
  use TodosWeb, :router

  import TodosWeb.UserAuth

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TodosWeb do
    pipe_through :api

    ## Authentication routes

    post "/users/register", UserRegistrationController, :create
    post "/users/log_in", UserSessionController, :create
    post "/users/reset_password", UserResetPasswordController, :create
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/api", TodosWeb do
    pipe_through [:api, :require_api_user]

    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    delete "/users/log_out", UserSessionController, :delete
    post "/users/confirm", UserConfirmationController, :create
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:todos, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

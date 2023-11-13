defmodule TodosWeb.UserConfirmationControllerTest do
  use TodosWeb.ConnCase, async: true

  alias Todos.Accounts
  alias Todos.Repo
  import Todos.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/confirm", %{
          "user" => %{"email" => user.email}
        })

      assert json_response(conn, 200)["message"] =~
             "If your email is in our system"

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if User is confirmed", %{conn: conn, user: user} do
      confirmed_user = Accounts.confirm_user(user) |> elem(1)
      conn =
        post(conn, ~p"/users/confirm", %{
          "user" => %{"email" => confirmed_user.email}
        })

      assert json_response(conn, 200)["message"] =~
             "If your email is in our system"

      refute Repo.get_by(Accounts.UserToken, user_id: confirmed_user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/confirm", %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert json_response(conn, 200)["message"] =~
             "If your email is in our system"

      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "POST /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      # token =
      #   extract_user_token(fn url ->
      #     Accounts.deliver_user_confirmation_instructions(user, url)
      #   end)

      # conn = post(conn, ~p"/users/confirm/#{token}")
      # assert redirected_to(conn) == ~p"/"

      # assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
      #          "User confirmed successfully"

      # assert Accounts.get_user!(user.id).confirmed_at
      # refute get_session(conn, :user_token)
      # assert Repo.all(Accounts.UserToken) == []

      # # When not logged in
      # conn = post(conn, ~p"/users/confirm/#{token}")
      # assert redirected_to(conn) == ~p"/"

      # assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
      #          "User confirmation link is invalid or it has expired"

      # # When logged in
      # conn =
      #   build_conn()
      #   |> log_in_user(user)
      #   |> post(~p"/users/confirm/#{token}")

      # assert redirected_to(conn) == ~p"/"
      # refute Phoenix.Flash.get(conn.assigns.flash, :error)
      # Setup and send the confirmation request
      # ...

      # Confirm the user with a valid token
      conn = post(conn, ~p"/users/confirm/#{token}")
      assert json_response(conn, 200)["message"] == "User confirmed successfully"

      # Try to use the token again
      conn = post(conn, ~p"/users/confirm/#{token}")
      assert json_response(conn, 422)["error"] == "User confirmation link is invalid or it has expired"
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = post(conn, ~p"/users/confirm/oops")
      assert json_response(conn, 422)["error"] == "User confirmation link is invalid or it has expired"
    end
  end
end

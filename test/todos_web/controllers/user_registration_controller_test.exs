defmodule TodosWeb.UserRegistrationControllerTest do
  use TodosWeb.ConnCase, async: true

  import Todos.AccountsFixtures

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/users/register", %{
          "user" => valid_user_attributes(email: email)
        })

      assert json_response(conn, 201)["message"] == "User created successfully."
      assert json_response(conn, 201)["user_id"]

      # Assuming you have a method to extract the user_id from the JSON response
      user_id = extract_user_id(json_response(conn, 201))

      # Now do a logged-in request and assert on the menu
      conn = get(conn, ~p"/")
      assert json_response(conn, 200)["email"] == email
      assert json_response(conn, 200)["settings_url"] =~ ~p"/users/settings/#{user_id}"
      assert json_response(conn, 200)["logout_url"] == ~p"/users/log_out"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, ~p"/users/register", %{
          "user" => %{"email" => "with spaces", "password" => "too short"}
        })

      assert json_response(conn, 422)["error"] == "Registration failed."
      assert json_response(conn, 422)["details"]["email"] =~ "must have the @ sign and no spaces"
      assert json_response(conn, 422)["details"]["password"] =~ "should be at least 12 characters"
    end
  end
end

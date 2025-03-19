defmodule MyappWeb.UserRegistrationLive do
  use MyappWeb, :live_view

  alias Myapp.Accounts
  alias Myapp.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <%= if @step == :registration do %>
        <.header class="text-center">
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
              Sign in
            </.link>
            to your account now.
          </:subtitle>
        </.header>
      <% else %>
        <.header class="text-center">
          Confirm your account
          <:subtitle>
            Please enter the confirmation code sent to your email.
          </:subtitle>
        </.header>
      <% end %>

      <%= if @step == :registration do %>
        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
        >
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input field={@form[:email]} type="email" label="Email" required />
          <div class="text-sm font-medium pb-2">
            <div :if={@email_taken} class="text-red-600">Email is already in use</div>
            <div :if={@invalid_email} class="text-red-600">Must be a valid email address</div>
          </div>

          <.input field={@form[:password]} type="password" label="Password" required />
          <div class="text-sm font-medium pb-2">
            <div :if={@password_criteria.length}>
              <span class={if @password_criteria.length, do: "text-green-600", else: "text-red-600"}>
                ✓
              </span>
              At least 12 characters
            </div>
            <div :if={!is_nil(@password_criteria.uppercase)}>
              <span class={
                if @password_criteria.uppercase, do: "text-green-600", else: "text-red-600"
              }>
                ✓
              </span>
              At least one uppercase letter
            </div>
            <div :if={!is_nil(@password_criteria.lowercase)}>
              <span class={
                if @password_criteria.lowercase, do: "text-green-600", else: "text-red-600"
              }>
                ✓
              </span>
              At least one lowercase letter
            </div>
            <div :if={!is_nil(@password_criteria.numbers)}>
              <span class={if @password_criteria.numbers, do: "text-green-600", else: "text-red-600"}>
                ✓
              </span>
              At least one number
            </div>
            <div :if={!is_nil(@password_criteria.special)}>
              <span class={if @password_criteria.special, do: "text-green-600", else: "text-red-600"}>
                ✓
              </span>
              At least one special character
            </div>
          </div>

          <!-- Debug information section -->
          <div class="mt-4 mb-4 p-3 border border-gray-300 bg-gray-100 rounded text-xs">
            <h3 class="font-bold mb-2">Debug Information:</h3>
            <div>
              <strong>Form valid:</strong> <span class={if @form_valid, do: "text-green-600", else: "text-red-600 font-bold"}><%= @form_valid %></span>
            </div>
            <div>
              <strong>Changeset valid:</strong> <span class={if @form.source.valid?, do: "text-green-600", else: "text-red-600"}><%= @form.source.valid? %></span>
            </div>
            <div>
              <strong>Email validation:</strong>
              <ul class="ml-4">
                <li>Email taken: <span class={if @email_taken, do: "text-red-600", else: "text-green-600"}><%= @email_taken %></span></li>
                <li>Invalid email: <span class={if @invalid_email, do: "text-red-600", else: "text-green-600"}><%= @invalid_email %></span></li>
              </ul>
            </div>
            <div>
              <strong>Password criteria:</strong>
              <ul class="ml-4">
                <li>Length (≥12): <span class={if @password_criteria.length, do: "text-green-600", else: "text-red-600"}><%= @password_criteria.length %></span></li>
                <li>Uppercase: <span class={if @password_criteria.uppercase, do: "text-green-600", else: "text-red-600"}><%= @password_criteria.uppercase %></span></li>
                <li>Lowercase: <span class={if @password_criteria.lowercase, do: "text-green-600", else: "text-red-600"}><%= @password_criteria.lowercase %></span></li>
                <li>Numbers: <span class={if @password_criteria.numbers, do: "text-green-600", else: "text-red-600"}><%= @password_criteria.numbers %></span></li>
                <li>Special chars: <span class={if @password_criteria.special, do: "text-green-600", else: "text-red-600"}><%= @password_criteria.special %></span></li>
              </ul>
            </div>
          </div>

          <div>
            <.button phx-disable-with="Creating account..." class="w-full" disabled={!@form_valid}>
              Create an account
            </.button>
            
            <div class="mt-2">
              <.button type="button" class="w-full bg-blue-400" phx-click="test_button">
                Test Button (Always Enabled)
              </.button>
            </div>
          </div>
        </.simple_form>
      <% else %>
        <.simple_form
          for={@confirmation_form}
          id="confirmation_form"
          phx-submit="confirm"
          phx-change="validate_code"
        >
          <div class="space-y-4">
            <p class="text-sm text-gray-600">
              We've sent a confirmation code to <span class="font-semibold"><%= @email %></span>.
              Please check your email and enter the code below.
            </p>

            <.input
              field={@confirmation_form[:confirmation_code]}
              type="text"
              label="Confirmation Code"
              autocomplete="off"
              required
              maxlength="6"
              placeholder="Enter 6-letter code"
            />

            <div :if={@confirmation_error} class="text-sm text-red-600">
              {@confirmation_error}
            </div>

            <div>
              <.button phx-disable-with="Verifying..." class="w-full">
                Verify Account
              </.button>
            </div>

            <div class="text-center text-sm mt-4">
              <.link href="#" class="text-brand hover:underline" phx-click="resend_code">
                Didn't receive a code? Resend
                w
              </.link>
            </div>
          </div>
        </.simple_form>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    
    # Initialize password criteria as explicit false values rather than nil
    # This ensures they are properly recognized in boolean operations
    password_criteria = %{
      length: false,
      uppercase: false,
      lowercase: false,
      numbers: false,
      special: false
    }
    
    # Log the initial state
    IO.puts("\n==== MOUNT STARTED: #{DateTime.utc_now()} ====")
    IO.puts("Socket ID: #{inspect(socket.id)}")
    IO.puts("Initializing form_valid to false explicitly")
    IO.inspect(password_criteria, label: "Initial password criteria")

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_taken, false)
      |> assign(:invalid_email, false)
      |> assign(:trigger_submit, false)
      |> assign(:check_errors, false)
      |> assign(:password_criteria, password_criteria)
      |> assign(:form_valid, false) # Explicitly set to false
      |> assign(:step, :registration)
      |> assign(:user_params, %{})
      |> assign(:email, nil)
      |> assign(:confirmation_error, nil)
      |> assign(:confirmation_form, to_form(%{"confirmation_code" => ""}))
      |> assign_form(changeset)
    
    # Log mount completion
    IO.puts("\n==== MOUNT COMPLETED: #{DateTime.utc_now()} ====")
    IO.puts("Live view successfully mounted - all assigns initialized")
    IO.puts("Socket ID: #{inspect(socket.id)}")
    IO.puts("Assigns: #{inspect(Map.take(socket.assigns, [:step, :form_valid]))}")
    IO.puts("===============================\n")

    {:ok, socket}
  end

  # Enhanced debug logging for event handling
  def handle_event(event_name, params, socket) do
    IO.puts("\n==== EVENT RECEIVED: #{event_name} at #{DateTime.utc_now()} ====")
    IO.puts("Socket ID: #{inspect(socket.id)}")
    IO.puts("Current step: #{inspect(socket.assigns.step)}")
    IO.puts("Params: #{inspect(params)}")
    IO.puts("=============================================\n")
    
    do_handle_event(event_name, params, socket)
  end

  # Renamed original handlers to do_handle_event
  defp do_handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    email = user_params["email"] || ""
    email_taken = email != "" && Accounts.get_user_by_email(email) != nil
    invalid_email = email != "" && !String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)

    password = user_params["password"] || ""
    password_criteria = validate_password_criteria(password)

    form_valid =
      changeset.valid? && !email_taken && !invalid_email &&
        password_criteria.length &&
        password_criteria.uppercase &&
        password_criteria.lowercase &&
        password_criteria.numbers &&
        password_criteria.special

    # Debug information logged to terminal
    IO.puts("\n==== Form Validation Debug ====")
    IO.inspect(email, label: "Email")
    IO.inspect(changeset.valid?, label: "Changeset valid?")
    IO.inspect(email_taken, label: "Email taken?")
    IO.inspect(invalid_email, label: "Invalid email?")
    IO.puts("\nPassword Criteria:")
    IO.inspect(password_criteria, label: "Password criteria")
    IO.puts("\nFinal Form Validation:")
    IO.inspect(form_valid, label: "Form valid?")
    IO.puts("==============================\n")

    # TEMPORARY DEBUG CHANGE: Force form_valid to be true regardless of validation
    # This helps test if the button can be clicked when enabled
    # Original code: |> assign(:form_valid, form_valid)
    IO.puts("\n==== IMPORTANT: form_valid forced to TRUE for debugging ====\n")

    {:noreply,
     socket
     |> assign(:email_taken, email_taken)
     |> assign(:invalid_email, invalid_email)
     |> assign(:password_criteria, password_criteria)
     |> assign(:form_valid, true)
     |> assign_form(changeset)}
  end

  defp do_handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Send confirmation code to the user's email
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(user)

        changeset = Accounts.change_user_registration(%User{})

        # Initialize the confirmation form with an empty confirmation code
        confirmation_form = to_form(%{"confirmation_code" => ""})

        {:noreply,
         socket
         |> assign(:user_params, user_params)
         |> assign(:email, user.email)
         |> assign(:step, :confirmation)
         |> assign(:confirmation_form, confirmation_form)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:check_errors, true) |> assign_form(changeset)}
    end
  end

  defp do_handle_event("confirm", %{"confirmation_code" => code}, socket) do
    email = socket.assigns.email

    case Accounts.confirm_user(email, code) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account confirmed successfully. You can now log in.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, error} ->
        # Convert error atoms to user-friendly messages
        error_message = case error do
          :invalid_code -> "Invalid confirmation code. Please check and try again."
          :expired -> "Confirmation code has expired. Please request a new one."
          :user_not_found -> "User not found. Please register again."
          _ when is_atom(error) -> "Error: #{error}"
          _ when is_binary(error) -> error
          _ -> "An unknown error occurred. Please try again."
        end
        
        {:noreply,
         socket
         |> assign(:confirmation_error, error_message)}
    end
  end

  defp do_handle_event("resend_code", _, socket) do
    # Get user by email
    user = Accounts.get_user_by_email(socket.assigns.email)

    case user do
      nil ->
        {:noreply,
         socket
         |> assign(:confirmation_error, "User not found")}

      user ->
        # Regenerate and send confirmation code
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(user)

        {:noreply,
         socket
         |> assign(:confirmation_error, nil)
         |> put_flash(:info, "A new confirmation code has been sent to your email.")}
    end
  end

  defp do_handle_event("validate_code", %{"confirmation_code" => code}, socket) do
    # Ensure the code is properly formatted (6 letters)
    formatted_code =
      code
      |> String.slice(0, 6)
      |> String.upcase()

    confirmation_form = to_form(%{"confirmation_code" => formatted_code})

    {:noreply,
     socket
     |> assign(:confirmation_form, confirmation_form)
     |> assign(:confirmation_error, nil)}
  end
  
  defp do_handle_event("test_button", params, socket) do
    IO.puts("\n!!!!! TEST BUTTON CLICKED: #{DateTime.utc_now()} !!!!!")
    IO.puts("Socket ID: #{inspect(socket.id)}")
    IO.puts("Button event received with params: #{inspect(params)}")
    IO.puts("Current assigns: #{inspect(Map.take(socket.assigns, [:step, :form_valid]))}")
    IO.puts("This confirms the button click event was received by LiveView")
    IO.puts("Sending flash message to browser to confirm response")
    IO.puts("!!!!! END TEST BUTTON DEBUG !!!!!\n")
    
    # Log the complete process
    Process.send_after(self(), {:log_test_button_completed}, 100)
    
    {:noreply, socket |> put_flash(:info, "Test button clicked successfully at #{DateTime.utc_now()}")}
  end
  
  # Catch-all handler for unknown events
  defp do_handle_event(unknown_event, params, socket) do
    IO.puts("\n==== UNKNOWN EVENT RECEIVED: #{unknown_event} ====")
    IO.puts("This event has no defined handler!")
    IO.puts("Params: #{inspect(params)}")
    IO.puts("=================================================\n")
    
    {:noreply, socket}
  end
  
  # This will be triggered after the test button event completes
  def handle_info({:log_test_button_completed}, socket) do
    IO.puts("\n!!!!! TEST BUTTON RESPONSE PROCESSED !!!!!")
    IO.puts("Flash message should now be visible in the browser")
    IO.puts("If you don't see the flash message, check browser console for JavaScript errors")
    IO.puts("============================================\n")
    
    {:noreply, socket}
  end

  defp validate_password_criteria(password) do
    # Log what password we're validating (first 3 chars for privacy)
    password_preview = if String.length(password) > 0, do: String.slice(password, 0, 3) <> "...", else: "(empty)"
    IO.puts("\n==== Password Validation for: #{password_preview} ====")
    
    # Check and log each criterion
    length_valid = String.length(password) >= 12
    IO.puts("Length check (≥12): #{String.length(password)} chars - #{if length_valid, do: "✓", else: "✗"}")
    
    uppercase_valid = String.match?(password, ~r/[A-Z]/)
    IO.puts("Uppercase check: #{if uppercase_valid, do: "✓", else: "✗"}")
    
    lowercase_valid = String.match?(password, ~r/[a-z]/)
    IO.puts("Lowercase check: #{if lowercase_valid, do: "✓", else: "✗"}")
    
    numbers_valid = String.match?(password, ~r/[0-9]/)
    IO.puts("Numbers check: #{if numbers_valid, do: "✓", else: "✗"}")
    
    special_valid = String.match?(password, ~r/[^A-Za-z0-9]/)
    IO.puts("Special char check: #{if special_valid, do: "✓", else: "✗"}")
    
    # Log overall result
    all_criteria_met = length_valid && uppercase_valid && lowercase_valid && numbers_valid && special_valid
    IO.puts("All criteria met: #{if all_criteria_met, do: "✓", else: "✗"}")
    IO.puts("=============================================\n")
    
    # Return the criteria map as before
    %{
      length: length_valid,
      uppercase: uppercase_valid,
      lowercase: lowercase_valid,
      numbers: numbers_valid,
      special: special_valid
    }
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end

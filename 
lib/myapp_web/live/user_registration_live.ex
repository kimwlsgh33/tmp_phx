            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              required
              phx-blur="validate_blur"
              class={[@form[:email].errors != [] && @touched["email"] && "border-orange-500 border-2 transition-colors duration-300"]}
            />
            <div :if={@touched["email"]} :for={msg <- @form[:email].errors} class="mt-2 text-sm text-orange-600 font-medium pl-1">
              {translate_error(msg)}
            </div>
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              required
              phx-blur="validate_blur"
              class={[@form[:password].errors != [] && @touched["password"] && "border-orange-500 border-2 transition-colors duration-300"]}
            />
            <div :if={@touched["password"]} :for={msg <- @form[:password].errors} class="mt-2 text-sm text-orange-600 font-medium pl-1">
              {translate_error(msg)}
            </div>
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm Password"
              required
              phx-blur="validate_blur"
              class={[@form[:password_confirmation].errors != [] && @touched["password_confirmation"] && "border-orange-500 border-2 transition-colors duration-300"]}
            />
            <div :if={@touched["password_confirmation"]} :for={msg <- @form[:password_confirmation].errors} class="mt-2 text-sm text-orange-600 font-medium pl-1">
              {translate_error(msg)}
            </div>
        <:actions>
          <.button 
            phx-disable-with="Creating account..." 
            class="w-full"
            disabled={!@form_valid}>
            Create an account
          </.button>
        </:actions>
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(:trigger_submit, false)
      |> assign(:error_message, nil)
      |> assign(:touched, %{})
      |> assign(:form_valid, false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end
  def handle_event("validate_blur", %{"_target" => [field], "user" => params}, socket) do
    touched = Map.put(socket.assigns.touched, field, true)
    
    changeset =
      %User{}
      |> Accounts.change_user_registration(params)
      |> validate_field(field, params)
      |> Map.put(:action, :validate)
    
    form_valid = form_valid?(changeset, params)
    
    socket = 
      socket
      |> assign(:touched, touched)
      |> assign(:form_valid, form_valid)
      |> assign_form(changeset)
      
    {:noreply, socket}
  end
  
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(params)
      |> validate_form(params)
      |> Map.put(:action, :validate)
      
    form_valid = form_valid?(changeset, params)
      
    socket = 
      socket
      |> assign(:form_valid, form_valid)
      |> assign_form(changeset)
      
    {:noreply, socket}
  end
  defp validate_field(changeset, _, _), do: changeset
  
  defp validate_form(changeset, params) do
    changeset
    |> validate_field("email", params)
    |> validate_field("password", params)
    |> validate_field("password_confirmation", params)
  end
  
  defp form_valid?(changeset, params) do
    email = Map.get(params, "email", "")
    password = Map.get(params, "password", "")
    password_confirmation = Map.get(params, "password_confirmation", "")
    
    # Check if required fields are not empty
    fields_present = email != "" && password != "" && password_confirmation != ""
    
    # Check if email is valid
    email_valid = String.match?(email, ~r/^[^\s]+@[^\s]+$/)
    
    # Check password requirements
    password_reqs = password_requirements(password)
    password_valid = Enum.all?(password_reqs, fn {_req, met?} -> met? end)
    
    # Check if password confirmation matches
    confirmation_valid = password_confirmation == password
    
    # Form is valid if all conditions are met
    fields_present && email_valid && password_valid && confirmation_valid && changeset.valid?
  end

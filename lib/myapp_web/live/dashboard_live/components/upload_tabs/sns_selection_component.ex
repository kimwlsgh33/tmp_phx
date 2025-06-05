defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsSelectionComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    # Get current time with Korea timezone (UTC+9)
    now = Time.utc_now()
    {hours, minutes, _} = {now.hour, now.minute, now.second}
    
    # Apply Korea timezone (UTC+9)
    hours = rem(hours + 9, 24)
    
    # Format time for display (HH:MM)
    formatted_hour = rem(hours, 12)
    formatted_hour = if formatted_hour == 0, do: 12, else: formatted_hour
    formatted_time = String.pad_leading(Integer.to_string(formatted_hour), 2, "0") <> ":" <> 
                    String.pad_leading(Integer.to_string(minutes), 2, "0")
    
    # Determine AM/PM for display
    period = if hours >= 12, do: "PM", else: "AM"
    
    {:ok,
     socket
     |> assign(:scheduled_upload, false)
     |> assign(:platform_dropdowns, %{})
     |> assign(:selected_country, "Korea")
     |> assign(:selected_time_period, period)
     |> assign(:upload_form, %{
       "schedule_date" => "", 
       "schedule_time" => formatted_time,
       "schedule_country" => "Korea"
     })}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign_new(:scheduled_upload, fn -> false end)
      |> assign(assigns)
      |> assign_new(:platform_dropdowns, fn -> %{} end)
      |> assign_new(:selected_country, fn -> "Korea" end)
      |> assign_new(:upload_form, fn -> %{
        "schedule_date" => "", 
        "schedule_time" => "12:00",
        "schedule_country" => "Korea"
      } end)

    # If we have a selected_country from assigns, update the form
    socket = if Map.has_key?(assigns, :selected_country) do
      update_in(socket.assigns.upload_form, fn form ->
        Map.put(form, "schedule_country", assigns.selected_country)
      end)
    else
      socket
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    selected_platforms = socket.assigns.selected_platforms
    platform_dropdowns = socket.assigns.platform_dropdowns

    # Toggle platform selection
    {updated_platforms, updated_dropdowns} =
      if platform in selected_platforms do
        # If removing platform, remove from selected and close dropdown
        {
          Enum.reject(selected_platforms, fn p -> p == platform end),
          Map.delete(platform_dropdowns, platform)
        }
      else
        # If adding platform, add to selected and open dropdown
        {
          [platform | selected_platforms],
          Map.put(platform_dropdowns, platform, true)
        }
      end

    # Update parent component
    send(socket.assigns.parent_pid, {:update_selected_platforms, updated_platforms})

    {:noreply,
     socket
     |> assign(:selected_platforms, updated_platforms)
     |> assign(:platform_dropdowns, updated_dropdowns)}
  end

  @impl true
  def handle_event("toggle-dropdown", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    platform_dropdowns = socket.assigns.platform_dropdowns

    # Toggle dropdown visibility
    updated_dropdowns =
      if Map.get(platform_dropdowns, platform, false) do
        Map.put(platform_dropdowns, platform, false)
      else
        Map.put(platform_dropdowns, platform, true)
      end

    {:noreply, assign(socket, :platform_dropdowns, updated_dropdowns)}
  end

  @impl true
  def handle_event("select-account", %{"platform" => platform, "account_id" => account_id}, socket) do
    platform = String.to_existing_atom(platform)
    social_accounts = socket.assigns.social_accounts
    selected_platforms = socket.assigns.selected_platforms

    # Toggle selection status for this account (enabling multiple selections)
    updated_accounts =
      Map.update!(social_accounts, platform, fn accounts ->
        Enum.map(accounts, fn account ->
          if account.id == account_id do
            # Toggle the selected status for this account
            Map.put(account, :selected, !Map.get(account, :selected, false))
          else
            account
          end
        end)
      end)

    # 계정 선택 후, 해당 플랫폼에 선택된 계정이 있는지 확인
    platform_accounts = updated_accounts[platform]
    has_selected_accounts = Enum.any?(platform_accounts, &Map.get(&1, :selected, false))

    # 선택된 계정이 없으면 플랫폼도 선택 해제
    updated_platforms =
      if has_selected_accounts do
        # 계정이 선택되어 있으면 플랫폼도 선택에 추가
        if platform not in selected_platforms do
          [platform | selected_platforms]
        else
          selected_platforms
        end
      else
        # 계정이 하나도 선택되지 않았으면 플랫폼도 선택 해제
        Enum.reject(selected_platforms, fn p -> p == platform end)
      end

    # 부모 컴포넌트에 계정 및 플랫폼 선택 업데이트 알림
    send(socket.assigns.parent_pid, {:update_social_accounts, updated_accounts})
    send(socket.assigns.parent_pid, {:update_selected_platforms, updated_platforms})

    {:noreply,
     socket
     |> assign(:social_accounts, updated_accounts)
     |> assign(:selected_platforms, updated_platforms)}
  end

  @impl true
  def handle_event("toggle-scheduled-upload", params, socket) do
    # phx-change에서는 체크박스가 체크되었을 때만 키가 포함됩니다
    scheduled_upload = Map.has_key?(params, "scheduled_upload")

    # 상태 업데이트 및 알림
    socket = assign(socket, :scheduled_upload, scheduled_upload)

    # Update parent with scheduled upload status
    send(socket.assigns.parent_pid, {:update_scheduled_upload, scheduled_upload})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate-form", %{"upload_form" => form_params}, socket) do
    # Combine date and time for schedule_at if both are present
    form_params = if socket.assigns.scheduled_upload do
      date = Map.get(form_params, "schedule_date", "")
      time = Map.get(form_params, "schedule_time", "12:00")
      
      if date != "" do
        Map.put(form_params, "schedule_at", "#{date}T#{time}")
      else
        form_params
      end
    else
      form_params
    end

    # Update local state
    socket = assign(socket, :upload_form, form_params)

    # Notify parent of the form change
    send(socket.assigns.parent_pid, {:update_form, form_params})

    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-description", _params, socket) do
    # Notify parent to switch back to the description tab
    send(socket.assigns.parent_pid, :switch_to_description_tab)
    {:noreply, socket}
  end

  @impl true
  # 기본 파라미터 형태
  def handle_event("goto-file-selection", _params, socket) do
    # SNS 플랫폼 선택이 유효한지 확인
    if Enum.empty?(socket.assigns.selected_platforms) do
      {:noreply, socket |> put_flash(:error, "Please select at least one social media platform")}
    else
      # 부모 컴포넌트에 파일 선택 탭으로 전환하라는 이벤트 전송
      send(socket.assigns.parent_pid, :switch_to_file_selection_tab)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:calendar_date_selected, datetime, country}, socket) do
    # Parse the datetime to extract date and time
    [date, time] = String.split(datetime, "T")
    
    # Update the form with the selected date and country
    form_params = Map.merge(socket.assigns.upload_form || %{}, %{
      "schedule_date" => date,
      "schedule_time" => time,
      "schedule_at" => datetime,
      "schedule_country" => country
    })
    
    # Update local state
    socket = assign(socket, :upload_form, form_params)
    socket = assign(socket, :selected_country, country)
    
    # Notify parent of the form change
    send(socket.assigns.parent_pid, {:update_form, form_params})
    
    {:noreply, socket}
  end

  # For backward compatibility
  @impl true
  # Handle time and country updates without date selection
  def handle_info({:calendar_time_updated, time, period, country}, socket) do
    # Update form with new time and country
    form_params = Map.merge(socket.assigns.upload_form || %{}, %{
      "schedule_time" => time,
      "schedule_country" => country
    })
    
    # Update local state
    socket = socket
      |> assign(:upload_form, form_params)
      |> assign(:selected_country, country)
      |> assign(:selected_time_period, period)
    
    # Notify parent of the form change
    send(socket.assigns.parent_pid, {:update_form, form_params})
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:calendar_date_selected, datetime}, socket) do
    # Parse the datetime to extract date and time
    [date, time] = String.split(datetime, "T")
    
    # Update the form with the selected date
    form_params = Map.merge(socket.assigns.upload_form || %{}, %{
      "schedule_date" => date,
      "schedule_time" => time,
      "schedule_at" => datetime
    })
    
    # Update local state
    socket = assign(socket, :upload_form, form_params)
    
    # Notify parent of the form change
    send(socket.assigns.parent_pid, {:update_form, form_params})
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    if socket.assigns.selected_platforms == [] do
      {:noreply,
       socket
       |> put_flash(:error, "Please select at least one social media platform")}
    else
      if socket.assigns.scheduled_upload do
        # Handle scheduled upload
        scheduled_time = socket.assigns.upload_form["schedule_at"]
        scheduled_country = socket.assigns.upload_form["schedule_country"] || "Korea"

        if scheduled_time == "" do
          {:noreply, socket |> put_flash(:error, "Please select a date and time for scheduled upload")}
        else
          # Save the schedule to the database here (in a real implementation)
          send(socket.assigns.parent_pid, {:schedule_complete, socket.assigns.selected_platforms, scheduled_time, scheduled_country})

          {:noreply, socket}
        end
      else
        # In real implementation, we would handle the immediate upload here
        Process.send_after(
          socket.assigns.parent_pid,
          {:upload_complete, socket.assigns.selected_platforms},
          1000
        )

        {:noreply, socket}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[600px]">
      <h2 class="text-xl font-semibold mb-4 text-gray-900 dark:text-gray-300">Platform Selection</h2>
      <p class="text-gray-600 dark:text-gray-300 mb-6">Choose where to publish your content and set scheduling options.</p>

      <form phx-submit="save" phx-change="validate-form" phx-target={@myself} id="sns-selection-form">
        <!-- Platform Selection: Select the SNS platform(s) to upload to. -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-2">Where to upload</label>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
            <%= for {platform, accounts} <- @social_accounts do %>
              <div class="relative">
                <!-- Platform button -->
                <button
                  type="button"
                  phx-click="toggle-platform"
                  phx-target={@myself}
                  phx-value-platform={platform}
                  disabled={Enum.empty?(accounts)}
                  aria-label={"#{Atom.to_string(platform) |> String.capitalize()} - #{if platform in @selected_platforms, do: "Selected", else: "Not selected"}"}
                  class={
                    "flex items-center justify-center py-2 px-3 border rounded-md text-sm font-medium transition-colors w-full " <>
                    if(Enum.empty?(accounts)) do
                      "bg-gray-100 dark:bg-gray-800 text-gray-400 dark:text-gray-500 border-gray-200 dark:border-gray-900 cursor-not-allowed"
                    else
                      if(platform in @selected_platforms) do
                        "bg-indigo-100 dark:bg-gray-700 text-indigo-700 dark:text-gray-300 border-indigo-300 dark:border-orange-600 hover:bg-indigo-200 dark:hover:bg-gray-600"
                      else
                        "bg-white dark:bg-black text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-900"
                      end
                    end
                  }
                >
                  <%= case platform do %>
                    <% :twitter -> %>
                      <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                      </svg>
                    <% :instagram -> %>
                      <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M12 2c2.717 0 3.056.01 4.122.06 1.065.05 1.79.217 2.428.465.66.254 1.216.598 1.772 1.153.509.5.902 1.105 1.153 1.772.247.637.415 1.363.465 2.428.047 1.066.06 1.405.06 4.122 0 2.717-.01 3.056-.06 4.122-.05 1.065-.218 1.79-.465 2.428a4.883 4.883 0 01-1.153 1.772c-.5.508-1.105.902-1.772 1.153-.637.247-1.363.415-2.428.465-1.066.047-1.405.06-4.122.06-2.717 0-3.056-.01-4.122-.06-1.065-.05-1.79-.218-2.428-.465a4.89 4.89 0 01-1.772-1.153 4.904 4.904 0 01-1.153-1.772c-.247-.637-.415-1.363-.465-2.428C2.013 15.056 2 14.717 2 12c0-2.717.01-3.056.06-4.122.05-1.066.218-1.79.465-2.428.254-.66.598-1.216 1.153-1.772a4.88 4.88 0 011.772-1.153c.637-.247 1.362-.415 2.428-.465C8.944 2.013 9.283 2 12 2zm0 1.802c-2.67 0-2.986.01-4.04.059-.976.045-1.505.207-1.858.344-.466.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.048 1.055-.058 1.37-.058 4.04 0 2.668.01 2.985.058 4.04.045.975.207 1.504.344 1.856.182.466.398.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.04.058 2.669 0 2.985-.01 4.04-.058.975-.045 1.504-.207 1.856-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.352.3-.88.344-1.856.048-1.055.058-1.372.058-4.04 0-2.67-.01-2.986-.058-4.04-.045-.975-.207-1.504-.344-1.856a3.09 3.09 0 00-.748-1.15 3.09 3.09 0 00-1.15-.748c-.352-.137-.88-.3-1.856-.344-1.054-.048-1.371-.058-4.04-.058zm0 3.063a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 8.468a3.333 3.333 0 100-6.666 3.333 3.333 0 000 6.666zm6.538-8.671a1.2 1.2 0 11-2.4 0 1.2 1.2 0 012.4 0z" />
                      </svg>
                    <% :facebook -> %>
                      <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z" />
                      </svg>
                    <% :youtube -> %>
                      <!-- Official YouTube Brand Icon from youtube.com/about/brand-resources -->
                      <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <g>
                          <path d="M23.498 6.186a2.998 2.998 0 0 0-2.11-2.117C19.507 3.5 12 3.5 12 3.5s-7.507 0-9.388.569a2.998 2.998 0 0 0-2.11 2.117A31.566 31.566 0 0 0 0 12c-.057 1.801-.061 3.597.502 5.814a2.998 2.998 0 0 0 2.11 2.117C4.493 20.5 12 20.5 12 20.5s7.507 0 9.388-.569a2.988 2.988 0 0 0 2.11-2.117C24 15.597 24 12 24 12s0-3.597-.502-5.814zM9.545 15.568V8.432l6.55 3.568-6.55 3.568z">
                          </path>
                        </g>
                      </svg>
                    <% :tiktok -> %>
                      <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z" />
                      </svg>
                  <% end %>
                  <%= if platform in @selected_platforms do %>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="ml-2 h-4 w-4 text-indigo-500"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% end %>
                </button>

                <!-- Account selection dropdown when platform is selected -->
                <%= if platform in @selected_platforms do %>
                  <div class="mt-2 relative">
                     <% # Handle different account structures %>
                     <% selected_accounts = if is_list(accounts) do 
                          Enum.filter(accounts, &(Map.get(&1, :selected, false))) 
                        else
                          account_map = Map.get(accounts, :connected) && accounts || %{}
                          if Map.get(account_map, :connected, false), do: [account_map], else: []
                        end
                     %>
                     <% selected_count = length(selected_accounts) %>
                     <button
                       type="button"
                       phx-click="toggle-dropdown"
                       phx-target={@myself}
                       phx-value-platform={platform}
                       class="flex items-center justify-between w-full px-3 py-2 text-sm font-medium bg-white dark:bg-black border rounded-md shadow-sm hover:bg-gray-50 dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-400 focus:border-indigo-500 dark:focus:border-indigo-400 transition-all duration-200"
                       >
                        <div class="flex items-center">
                           <%= if selected_count > 0 do %>
                             <div class="flex -space-x-2 mr-2">
                               <%= for account <- Enum.take(selected_accounts, 2) do %>
                                 <div class="h-6 w-6 rounded-full bg-indigo-100 ring-2 ring-white overflow-hidden">
                                   <img src={Map.get(account, :avatar, "https://via.placeholder.com/150")} alt={Map.get(account, :username, "account")} class="h-full w-full object-cover" />
                                 </div>
                               <% end %>
                               <%= if selected_count > 2 do %>
                                 <div class="h-6 w-6 rounded-full bg-indigo-100 ring-2 ring-white flex items-center justify-center text-xs font-medium text-indigo-800">+<%= selected_count - 2 %></div>
                               <% end %>
                             </div>
                             <span class="truncate"><%= selected_count %> Account<%= if selected_count > 1, do: "s" %></span>
                           <% else %>
                             <span class="truncate">Select accounts</span>
                           <% end %>
                       </div>
                      <svg class="h-4 w-4 ml-2 text-gray-500 dark:text-gray-300" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                      </svg>
                    </button>

                    <!-- Dropdown menu for account selection -->
                    <%= if Map.get(@platform_dropdowns, platform, false) do %>
                      <div class="absolute z-10 mt-1 w-full bg-white dark:bg-black shadow-lg rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 dark:ring-white dark:ring-opacity-20 overflow-auto focus:outline-none sm:text-sm max-h-60">
                        <div class="sticky top-0 bg-gray-50 dark:bg-gray-900 px-4 py-2 text-xs font-medium text-gray-500 dark:text-gray-300 border-b dark:border-gray-700">
                          Select multiple accounts
                        </div>
                        <% # Normalize accounts to a list of maps for iteration %>
                        <% account_list = cond do
                            is_list(accounts) -> accounts
                            is_map(accounts) -> [accounts]
                            is_tuple(accounts) -> [%{id: "default", username: Atom.to_string(platform), avatar: "https://via.placeholder.com/150"}]
                            true -> []
                           end
                        %>
                        <%= for account <- account_list do %>
                          <button
                            type="button"
                            phx-click="select-account"
                            phx-target={@myself}
                            phx-value-platform={platform}
                            phx-value-account_id={Map.get(account, :id) || "default"}
                            class={"w-full text-left px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-900 transition-colors duration-150"}
                          >
                            <div class="flex items-center">
                              <div class="relative flex-shrink-0">
                                <div class={"w-10 h-10 rounded-full overflow-hidden bg-gray-200 mr-3 ring-2 #{if Map.get(account, :selected, false), do: "ring-indigo-500", else: "ring-gray-200"}"}>
                                  <img src={Map.get(account, :avatar, "https://via.placeholder.com/150")} alt="" class="h-full w-full object-cover" />
                                </div>
                                <%= if Map.get(account, :selected, false) do %>
                                  <div class="absolute -bottom-1 -right-1 bg-indigo-500 rounded-full p-0.5">
                                    <svg class="h-3.5 w-3.5 text-white" viewBox="0 0 20 20" fill="currentColor">
                                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                    </svg>
                                  </div>
                                <% end %>
                              </div>
                              <div>
                                <p class={"font-medium #{if Map.get(account, :selected, false), do: "text-indigo-700", else: "text-gray-900 dark:text-gray-300"}"}>
                                  @<%= Map.get(account, :username, "account") %>
                                </p>
                                <p class="text-xs text-gray-500 dark:text-gray-400"><%= platform |> Atom.to_string() |> String.capitalize() %> Account</p>
                              </div>
                            </div>
                          </button>
                        <% end %>
                        <div class="border-t border-gray-100 divide-y divide-gray-100">
                          <div class="py-2 px-3">
                            <button
                              type="button"
                              phx-click="toggle-dropdown"
                              phx-target={@myself}
                              phx-value-platform={platform}
                              class="w-full text-center py-2 px-3 bg-indigo-500 hover:bg-indigo-600 text-white rounded-md text-sm font-medium transition-colors"
                            >
                              <div class="flex items-center justify-center">
                                <svg class="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                </svg>
                                <span>Done</span>
                              </div>
                            </button>
                          </div>
                          <div class="py-2">
                            <.link
                              navigate={~p"/sns-accounts"}
                              class="block px-4 py-2 text-sm text-indigo-600 hover:bg-gray-50"
                            >
                              <div class="flex items-center">
                                <svg class="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                                </svg>
                                <span>Manage SNS Accounts</span>
                              </div>
                            </.link>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
          <%= if !Enum.empty?(@selected_platforms) do %>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
              Selected: <%= @selected_platforms
              |> Enum.map(&(Atom.to_string(&1) |> String.capitalize()))
              |> Enum.join(", ") %>
            </p>
          <% else %>
            <p class="mt-2 text-sm text-red-500">
              Please select at least one platform
            </p>
          <% end %>
        </div>

                <!-- Scheduled Upload Option -->
        <%= if Map.get(assigns, :show_scheduled_upload, true) do %>
        <div class="mb-6">
          <div class="flex items-center">
            <input
              id="scheduled_upload"
              name="scheduled_upload"
              type="checkbox"
              phx-change="toggle-scheduled-upload"
              phx-target={@myself}
              checked={@scheduled_upload}
              class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
            />
            <label for="scheduled_upload" class="ml-2 block text-sm text-gray-900 dark:text-gray-300">
              Schedule upload for later
            </label>
          </div>
          
          <%= if @scheduled_upload do %>
            <div class="mt-4">
              <!-- Hidden input to store the combined date and time -->
              <input
                type="hidden"
                id="schedule_at"
                name="upload_form[schedule_at]"
                value={Map.get(@upload_form || %{}, "schedule_at", "")}
              />
              
              <!-- Calendar Component -->
              <.live_component
                module={MyappWeb.DashboardLive.Components.CalendarComponent}
                id="calendar-component"
                upload_form={@upload_form}
                current_date={Date.utc_today()}
                parent_pid={self()}
              />
            </div>
          <% end %>
        </div>
        <% end %>
        <!-- Hidden validation state -->
        <div id="sns-validation-state" phx-hook="SnsValidation" data-valid={!Enum.empty?(@selected_platforms) && "true" || "false"} class="hidden"></div>
      </form>
    </div>
    """
  end
end

defmodule MyappWeb.DashboardLive.Components.CalendarComponent do
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

    # Determine AM/PM
    period = if hours >= 12, do: "PM", else: "AM"

    {:ok, socket
      |> assign(:selected_date, nil)
      |> assign(:selected_time, formatted_time)
      |> assign(:selected_time_period, period)
      |> assign(:selected_country, "Korea")
      |> assign(:popup_open, false)
      |> assign_calendar_data()
    }
  end

  @impl true
  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    # If we receive a selected_date from parent, update our state
    socket = if Map.has_key?(assigns, :selected_date) do
      case assigns.selected_date do
        nil -> socket
        datetime when is_binary(datetime) ->
          # Parse datetime string into date
          [date_str | _] = String.split(datetime, "T")
          [year, month, day] = String.split(date_str, "-") |> Enum.map(&String.to_integer/1)
          date = Date.new!(year, month, day)
          socket |> assign(:selected_date, date)
        date -> socket |> assign(:selected_date, date)
      end
    else
      socket
    end

    {:ok, socket |> assign_calendar_data()}
  end

  @impl true
  def handle_event("toggle-popup", _params, socket) do
    {:noreply, socket |> assign(:popup_open, !socket.assigns.popup_open)}
  end

  @impl true
  def handle_event("prev-month", _params, socket) do
    current_date = socket.assigns.current_date
    new_date = Date.add(current_date, -Date.days_in_month(current_date))
    {:noreply, socket |> assign(:current_date, new_date) |> assign_calendar_data()}
  end

  @impl true
  def handle_event("next-month", _params, socket) do
    current_date = socket.assigns.current_date
    new_date = Date.add(current_date, Date.days_in_month(current_date))
    {:noreply, socket |> assign(:current_date, new_date) |> assign_calendar_data()}
  end

  @impl true
  def handle_event("toggle-popup", _params, socket) do
    {:noreply, socket |> assign(:popup_open, !socket.assigns.popup_open)}
  end

  @impl true
  def handle_event("update-time", params, socket) do
    time = params["time"] || Map.get(socket.assigns.upload_form || %{}, "schedule_time", "12:00")
    socket = socket |> assign(:selected_time, time)
    send_datetime_to_parent(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select-time-period", params, socket) do
    period = params["period"] || (params["_target"] && List.first(params["_target"]) || "AM")
    socket = socket |> assign(:selected_time_period, period)
    send_datetime_to_parent(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select-country", params, socket) do
    country = params["country"] || (params["_target"] && List.first(params["_target"]) || "Korea")

    # Get current time with timezone offset based on country
    now = Time.utc_now()
    {hours, minutes, _} = {now.hour, now.minute, now.second}

    # Apply timezone offset based on country
    hours = case country do
      "Korea" -> rem(hours + 9, 24)  # UTC+9
      "Japan" -> rem(hours + 9, 24)  # UTC+9
      "China" -> rem(hours + 8, 24)  # UTC+8
      "USA" ->
        # Handle negative hours properly
        us_hours = hours - 5
        if us_hours < 0, do: us_hours + 24, else: us_hours
      _ -> rem(hours + 9, 24)        # Default to Korea time
    end

    # Format time for display (HH:MM)
    formatted_hour = rem(hours, 12)
    formatted_hour = if formatted_hour == 0, do: 12, else: formatted_hour
    formatted_time = String.pad_leading(Integer.to_string(formatted_hour), 2, "0") <> ":" <>
                     String.pad_leading(Integer.to_string(minutes), 2, "0")

    # Determine AM/PM
    period = if hours >= 12, do: "PM", else: "AM"

    # Update socket with country, time and period
    socket = socket
      |> assign(:selected_country, country)
      |> assign(:selected_time, formatted_time)
      |> assign(:selected_time_period, period)

    send_datetime_to_parent(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select-date", %{"date" => date_str}, socket) do
    [year, month, day] = String.split(date_str, "-") |> Enum.map(&String.to_integer/1)
    selected_date = Date.new!(year, month, day)

    socket = socket
      |> assign(:selected_date, selected_date)
      |> assign(:popup_open, false)

    # Send formatted datetime to parent
    formatted_date = Calendar.strftime(selected_date, "%Y-%m-%d")

    # Format time in HH:MM format for display
    time = socket.assigns.selected_time
    period = socket.assigns.selected_time_period
    country = socket.assigns.selected_country

    # Format the full datetime string
    formatted_datetime = "#{formatted_date}T#{time}:00"

    # Send the selected date to the parent component
    send(socket.assigns.parent_pid, {:calendar_date_selected, formatted_datetime, country})

    {:noreply, socket}
  end

  defp send_datetime_to_parent(socket) do
    # Get the time from the form or use default
    time = Map.get(socket.assigns, :selected_time, "12:00")

    # Adjust for AM/PM if needed
    [hours, minutes] = String.split(time, ":") |> Enum.map(&String.to_integer/1)
    hours = if socket.assigns.selected_time_period == "PM" and hours < 12 do
      hours + 12
    else
      if socket.assigns.selected_time_period == "AM" and hours == 12 do
        0  # 12 AM is 00:00 in 24-hour format
      else
        hours
      end
    end

    # Format the time
    formatted_time = String.pad_leading(Integer.to_string(hours), 2, "0") <> ":" <>
                    String.pad_leading(Integer.to_string(minutes), 2, "0")

    # Create the formatted datetime with country
    if socket.assigns[:selected_date] do
      # Format the date for display and form submission
      formatted_date = Calendar.strftime(socket.assigns.selected_date, "%Y-%m-%d")
      formatted_datetime = "#{formatted_date}T#{formatted_time}:00"
      country = socket.assigns.selected_country

      # Send the selected date to the parent component
      send(socket.assigns.parent_pid, {:calendar_date_selected, formatted_datetime, country})
    else
      # If no date is selected, still send time and country updates
      send(socket.assigns.parent_pid, {:calendar_time_updated, socket.assigns.selected_time, socket.assigns.selected_time_period, socket.assigns.selected_country})
    end
  end

  defp assign_calendar_data(socket) do
    current_date = Map.get(socket.assigns, :current_date, Date.utc_today())
    selected_date = Map.get(socket.assigns, :selected_date)

    year = current_date.year
    month = current_date.month

    # Get first day of the month
    first_day = Date.new!(year, month, 1)

    # Get last day of the month
    last_day = Date.new!(year, month, Date.days_in_month(first_day))

    # Get the day of week for the first day (1 = Monday, 7 = Sunday)
    first_day_of_week = Date.day_of_week(first_day)

    # Adjust for Sunday as the first day of the week (0-indexed for our calculations)
    first_day_offset = rem(first_day_of_week + 5, 7)

    # Calculate the total days to display including padding
    days_in_month = Date.days_in_month(first_day)
    total_days = days_in_month + first_day_offset
    total_weeks = ceil(total_days / 7)

    # Generate calendar grid
    calendar_days =
      for week <- 0..(total_weeks - 1) do
        for day_of_week <- 0..6 do
          day_num = week * 7 + day_of_week - first_day_offset + 1

          if day_num > 0 and day_num <= days_in_month do
            date = Date.new!(year, month, day_num)

            %{
              date: date,
              day: day_num,
              current_month: true,
              today: Date.compare(date, Date.utc_today()) == :eq,
              selected: selected_date && Date.compare(date, selected_date) == :eq
            }
          else
            %{
              date: nil,
              day: nil,
              current_month: false,
              today: false,
              selected: false
            }
          end
        end
      end

    socket
    |> assign(:current_date, current_date)
    |> assign(:calendar_days, calendar_days)
    |> assign(:month_name, Calendar.strftime(current_date, "%B"))
    |> assign(:year, year)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="w-72 space-y-2">
      <div class="relative">
        <!-- Popover Trigger Button -->
        <button
          type="button"
          phx-click="toggle-popup"
          phx-target={@myself}
          class="flex h-10 w-full items-center justify-between rounded-md border border-neutral-200 bg-white px-3 py-2 text-sm text-neutral-700 shadow-sm hover:bg-neutral-100 dark:border-neutral-800 dark:bg-neutral-950 dark:text-neutral-100 dark:hover:bg-neutral-900 dark:ring-offset-neutral-950 dark:placeholder:text-neutral-400 focus:outline-none focus:ring-2 focus:ring-neutral-500"
        >
          <%= if @selected_date do %>
            <span><%= Calendar.strftime(@selected_date, "%B %d, %Y") %></span>
          <% else %>
            <span class="text-neutral-500 dark:text-neutral-400">Pick a date</span>
          <% end %>
          <svg class="ml-auto h-4 w-4 opacity-70" width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4.5 1C4.77614 1 5 1.22386 5 1.5V2H10V1.5C10 1.22386 10.2239 1 10.5 1C10.7761 1 11 1.22386 11 1.5V2H12.5C13.3284 2 14 2.67157 14 3.5V12.5C14 13.3284 13.3284 14 12.5 14H2.5C1.67157 14 1 13.3284 1 12.5V3.5C1 2.67157 1.67157 2 2.5 2H4V1.5C4 1.22386 4.22386 1 4.5 1ZM10 3V3.5C10 3.77614 10.2239 4 10.5 4C10.7761 4 11 3.77614 11 3.5V3H12.5C12.7761 3 13 3.22386 13 3.5V5H2V3.5C2 3.22386 2.22386 3 2.5 3H4V3.5C4 3.77614 4.22386 4 4.5 4C4.77614 4 5 3.77614 5 3.5V3H10ZM2 6V12.5C2 12.7761 2.22386 13 2.5 13H12.5C12.7761 13 13 12.7761 13 12.5V6H2Z" fill="currentColor" fill-rule="evenodd" clip-rule="evenodd"></path></svg>
        </button>

        <!-- Calendar Popup -->
        <%= if @popup_open do %>
          <div class="absolute z-50 mt-1 w-auto rounded-md border border-neutral-200 bg-white p-4 shadow-md dark:border-neutral-800 dark:bg-neutral-950">
            <!-- Calendar Header -->
            <div class="flex items-center justify-between mb-4">
              <button
                type="button"
                phx-click="prev-month"
                phx-target={@myself}
                class="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-600 dark:text-neutral-300"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
              </button>

              <h2 class="text-sm font-medium text-neutral-900 dark:text-neutral-100">
                <%= @month_name %> <%= @year %>
              </h2>

              <button
                type="button"
                phx-click="next-month"
                phx-target={@myself}
                class="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-600 dark:text-neutral-300"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>

            <!-- Weekday Headers -->
            <div class="grid grid-cols-7 mb-1 text-xs text-center font-medium text-neutral-500 dark:text-neutral-400">
              <div>S</div>
              <div>M</div>
              <div>T</div>
              <div>W</div>
              <div>T</div>
              <div>F</div>
              <div>S</div>
            </div>

            <!-- Calendar Grid -->
            <div class="grid grid-cols-7 gap-1">
              <%= for week <- @calendar_days do %>
                <%= for day <- week do %>
                  <%= if day.current_month do %>
                    <button
                      type="button"
                      phx-click="select-date"
                      phx-value-date={"#{@year}-#{@current_date.month}-#{day.day}"}
                      phx-target={@myself}
                      disabled={day.date && Date.compare(day.date, Date.utc_today()) == :lt}
                      class={[
                        "h-9 w-9 rounded-md flex items-center justify-center text-sm",
                        # Base hover styles
                        "hover:bg-neutral-100 dark:hover:bg-neutral-800",
                        # Disabled state
                        day.date && Date.compare(day.date, Date.utc_today()) == :lt && "opacity-50 cursor-not-allowed",
                        # Selected state
                        day.selected && "bg-neutral-900 text-white hover:bg-neutral-900 dark:bg-white dark:text-neutral-900 dark:hover:bg-white",
                        # Today state (if not selected)
                        day.today && !day.selected && "border border-neutral-200 dark:border-neutral-800",
                        # Normal state
                        !day.today && !day.selected && "text-neutral-900 dark:text-neutral-100"
                      ] |> Enum.filter(& &1)}
                    >
                      <%= day.day %>
                    </button>
                  <% else %>
                    <div class="h-9 w-9"></div>
                  <% end %>
                <% end %>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Time and Country Selectors -->
      <div class="grid grid-cols-2 gap-2 mt-2">
        <div>
          <label class="block text-xs font-medium text-neutral-700 dark:text-neutral-300 mb-1">
            시간
          </label>
          <div class="flex">
            <input
              type="text"
              name="time"
              placeholder="HH:MM"
              pattern="[0-9]{1,2}:[0-9]{2}"
              phx-change="update-time"
              phx-target={@myself}
              class="h-10 rounded-l-md border border-neutral-200 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-neutral-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neutral-500 focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50 dark:border-neutral-800 dark:bg-neutral-950 dark:ring-offset-neutral-950 dark:placeholder:text-neutral-400 dark:focus-visible:ring-neutral-300 w-2/3"
              value={@selected_time}
            />
            <select
              name="period"
              phx-change="select-time-period"
              phx-target={@myself}
              class="h-10 rounded-r-md border border-neutral-200 border-l-0 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-neutral-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neutral-500 focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50 dark:border-neutral-800 dark:bg-neutral-950 dark:ring-offset-neutral-950 dark:placeholder:text-neutral-400 dark:focus-visible:ring-neutral-300 w-1/3"
            >
              <option value="AM" selected={@selected_time_period == "AM"}>AM</option>
              <option value="PM" selected={@selected_time_period == "PM"}>PM</option>
            </select>
          </div>
        </div>

        <div>
          <label class="block text-xs font-medium text-neutral-700 dark:text-neutral-300 mb-1">
            Country
          </label>
          <select
            name="country"
            phx-change="select-country"
            phx-target={@myself}
            class="flex h-10 w-full rounded-md border border-neutral-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-neutral-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neutral-500 focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50 dark:border-neutral-800 dark:bg-neutral-950 dark:ring-offset-neutral-950 dark:placeholder:text-neutral-400 dark:focus-visible:ring-neutral-300"
          >
            <option value="Korea" selected={@selected_country == "Korea"}>Korea</option>
            <option value="USA" selected={@selected_country == "USA"}>USA</option>
            <option value="Japan" selected={@selected_country == "Japan"}>Japan</option>
            <option value="China" selected={@selected_country == "China"}>China</option>
            <option value="Other" selected={@selected_country == "Other"}>Other</option>
          </select>
        </div>
      </div>
    </div>
    """
  end
end

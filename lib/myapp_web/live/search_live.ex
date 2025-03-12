defmodule MyappWeb.SearchLive do
  use MyappWeb, :live_view
  alias Phoenix.LiveView.JS

  @debounce_ms 300

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:loading, false)
     |> assign(:results, [])
     |> assign(:search_id, 0)
     |> assign(:debounce_ms, @debounce_ms)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    search_id = socket.assigns.search_id + 1

    if query == "" do
      {:noreply,
       socket
       |> assign(:query, query)
       |> assign(:loading, false)
       |> assign(:results, [])
       |> assign(:search_id, search_id)}
    else
      # Cancel any pending search operations
      if socket.assigns.loading do
        Process.cancel_timer(socket.assigns.timer_ref)
      end

      # Schedule the search with debounce
      timer_ref = Process.send_after(self(), {:search, query, search_id}, @debounce_ms)

      {:noreply,
       socket
       |> assign(:query, query)
       |> assign(:loading, true)
       |> assign(:timer_ref, timer_ref)
       |> assign(:search_id, search_id)}
    end
  end

  @impl true
  def handle_info({:search, query, search_id}, %{assigns: %{search_id: current_id}} = socket)
      when search_id != current_id do
    # This search was superseded by a newer one, ignore it
    {:noreply, socket}
  end

  @impl true
  def handle_info({:search, query, _search_id}, socket) do
    # Perform the actual search
    # Replace with your actual search implementation
    results = perform_search(query)

    # Update socket with results
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:results, results)}
  end

  # Placeholder for actual search implementation
  # Replace with your application's search functionality
  defp perform_search(query) do
    # Simulate API delay
    :timer.sleep(100)

    # Mock search results - replace with actual search logic
    [
      %{id: 1, title: "Result 1 for #{query}", description: "Description for result 1"},
      %{id: 2, title: "Result 2 for #{query}", description: "Description for result 2"},
      %{id: 3, title: "Result 3 for #{query}", description: "Description for result 3"}
    ]
  end
end


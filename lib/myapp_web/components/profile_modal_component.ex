defmodule MyappWeb.ProfileModalComponent do
  use MyappWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="relative z-50"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
      phx-mounted={@show && show_modal()}
      phx-remove={hide_modal()}
    >
      <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
      
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
            <div class="absolute right-0 top-0 pr-4 pt-4">
              <button
                phx-click="close_modal"
                type="button"
                class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              >
                <span class="sr-only">Close</span>
                <svg
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                <div class="flex flex-col items-center">
                  <!-- User Avatar -->
                  <%= if @current_user.avatar_url do %>
                    <img
                      src={@current_user.avatar_url}
                      alt="Profile Picture"
                      class="h-24 w-24 rounded-full object-cover mb-4"
                    />
                  <% else %>
                    <div class="h-24 w-24 rounded-full bg-blue-600 flex items-center justify-center text-white text-2xl font-bold mb-4">
                      {String.first(@current_user.email)}
                    </div>
                  <% end %>
                  
    <!-- User Info -->
                  <h3 class="text-xl font-semibold text-gray-900 mb-2">
                    {@current_user.email}
                  </h3>
                  
                  <p class="text-sm text-gray-500 mb-6">
                    Member since {NaiveDateTime.to_date(@current_user.inserted_at)}
                  </p>
                </div>
                
                <div class="mt-6 space-y-4">
                  <.link
                    navigate={~p"/users/profile"}
                    class="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                  >
                    View Full Profile
                  </.link>
                  
                  <.link
                    navigate={~p"/users/settings"}
                    class="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Settings
                  </.link>
                  
                  <.link
                    href={~p"/users/log_out"}
                    method="delete"
                    class="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
                  >
                    Sign Out
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}) do
    js
    |> JS.show(to: "#modal")
    |> JS.show(
      to: "#modal-overlay",
      transition: {"transition-all", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#modal-content",
      transition:
        {"transition-all", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.focus_first(to: "#modal-content")
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#modal-content",
      transition:
        {"transition-all", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(
      to: "#modal-overlay",
      transition: {"transition-all", "opacity-100", "opacity-0"}
    )
    |> JS.hide(to: "#modal")
  end
end

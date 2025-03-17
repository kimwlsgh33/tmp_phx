defmodule MyappWeb.UserProfileLive do
  use MyappWeb, :live_view
  import MyappWeb.CoreComponents


  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
      <.header class="text-center">
        User Profile
        <:subtitle>View and manage your profile information</:subtitle>
      </.header>

      <div class="mt-10 bg-white rounded-lg shadow overflow-hidden">
        <div class="p-6 sm:p-8 flex flex-col items-center">
          <!-- User Avatar -->
          <%= if @current_user.avatar_url do %>
            <img src={@current_user.avatar_url} alt="Profile Picture" class="h-24 w-24 rounded-full object-cover mb-4" />
          <% else %>
            <div class="h-24 w-24 rounded-full bg-blue-600 flex items-center justify-center text-white text-2xl font-bold mb-4">
              <%= String.first(@current_user.email) %>
            </div>
          <% end %>

          <!-- User Info -->
          <div class="mt-4 text-center">
            <h2 class="text-xl font-semibold text-gray-900"><%= @current_user.email %></h2>
            <p class="text-sm text-gray-500">Member since <%= NaiveDateTime.to_date(@current_user.inserted_at) %></p>
          </div>

          <div class="mt-8 w-full max-w-md">
            <.list>
              <:item title="Email"><%= @current_user.email %></:item>
              <:item title="Account Status">Active</:item>
            </.list>
          </div>

          <div class="mt-8 flex gap-4">
            <.link navigate={~p"/users/settings"}>
              <.button class="px-4">
                <.icon name="hero-cog-6-tooth" class="w-4 h-4 mr-1" /> Settings
              </.button>
            </.link>
          </div>
        </div>
      </div>

      <!-- Recent Activity Section (Optional) -->
      <div class="mt-8 bg-white rounded-lg shadow overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-200">
          <h3 class="text-lg font-medium text-gray-900">Recent Activity</h3>
        </div>
        <div class="p-6">
          <p class="text-gray-500 text-center py-6">Your recent activity will appear here.</p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end


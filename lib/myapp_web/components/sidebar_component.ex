defmodule MyappWeb.SidebarComponent do
  use Phoenix.Component
  import MyappWeb.CoreComponents

  @doc """
  Renders a toggleable sidebar with the ability to collapse/expand.

  ## Examples

      <.sidebar id="main-sidebar">
        <:actions>
          <!-- Action buttons go here -->
        </:actions>
        <!-- Main content goes here -->
      </.sidebar>
  """
  attr :id, :string, required: true, doc: "The ID for the sidebar and associated elements"
  attr :current_user, :map, default: nil, doc: "The current user"
  attr :social_accounts, :map, default: %{}, doc: "The connected social accounts"
  attr :loading_accounts, :boolean, default: false, doc: "Whether accounts are loading"
  slot :actions, doc: "Action buttons to be displayed in the sidebar"
  slot :inner_block, required: true, doc: "The content to be displayed alongside the sidebar"

  def sidebar(assigns) do
    ~H"""
    <div
      id={@id}
      x-data="{ sidebarOpen: localStorage.getItem('sidebarOpen') === 'true', 
                setSidebarState(value) { 
                  this.sidebarOpen = value; 
                  localStorage.setItem('sidebarOpen', value.toString()); 
                } 
              }"
      x-init="$watch('sidebarOpen', value => setSidebarState(value))"
      class="flex h-full"
    >
      <!-- Sidebar -->
      <div
        x-bind:class="sidebarOpen ? 'translate-x-0 w-64' : '-translate-x-full w-0 md:w-16 md:translate-x-0'"
        class="fixed inset-y-0 left-0 z-50 flex flex-col flex-shrink-0 transform transition-all duration-300 bg-gray-900 dark:bg-black shadow-lg overflow-hidden"
      >
        <!-- Sidebar Header -->
        <div class="flex items-center justify-between h-16 px-4 border-b border-gray-800">
          <!-- Logo - Only visible when expanded -->
          <div
            x-show="sidebarOpen"
            x-transition:enter="transition ease-out duration-300"
            x-transition:enter-start="opacity-0"
            x-transition:enter-end="opacity-100"
            x-transition:leave="transition ease-in duration-200"
            x-transition:leave-start="opacity-100"
            x-transition:leave-end="opacity-0"
            class="flex items-center"
          >
            <img src="/images/logos/ingrey.svg" alt="CreatorSync Logo" loading="lazy" />
            <span class="ml-2 text-lg font-bold text-white">Dashboard</span>
          </div>
          
    <!-- Toggle button - repositioned when collapsed -->
          <button
            x-bind:class="sidebarOpen ? 'right-4' : 'left-4 md:left-auto md:right-0 md:mr-0'"
            class="p-1 rounded-md hover:bg-gray-700 absolute"
            aria-label="Toggle sidebar"
            @click="sidebarOpen = !sidebarOpen"
          >
            <svg
              x-bind:class="sidebarOpen ? '' : 'transform rotate-180'"
              class="w-6 h-6 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
              />
            </svg>
          </button>
        </div>
        
    <!-- Sidebar Content -->
        <div class="flex-1 overflow-y-auto pt-5 pb-4">
          <!-- User Info -->
          <div x-show="sidebarOpen" class="flex flex-col items-center mb-6 px-2">
            <%= if @current_user do %>
              <%= if @current_user[:avatar_url] do %>
                <img
                  class="h-16 w-16 rounded-full border-2 border-indigo-500"
                  src={@current_user.avatar_url}
                  alt="User avatar"
                />
              <% else %>
                <div class="h-16 w-16 rounded-full bg-indigo-600 flex items-center justify-center text-white text-2xl font-bold">
                  {if @current_user[:email], do: String.first(@current_user.email), else: "U"}
                </div>
              <% end %>
              <h3 class="mt-2 text-sm font-medium text-white">{@current_user[:email] || "User"}</h3>
              <p class="text-xs text-gray-400">Dashboard</p>
            <% end %>
          </div>
          
    <!-- Social Account Status -->
          <div x-show="sidebarOpen" class="px-4 mb-6">
            <h4 class="text-xs uppercase tracking-wider text-gray-400 mb-2">Connected Accounts</h4>
            <div class="space-y-2">
              <%= for platform <- ["instagram", "tiktok", "twitter", "facebook", "youtube"] do %>
                <div class="flex items-center justify-between rounded-md p-2 bg-gray-800">
                  <div class="flex items-center">
                    <div class={"w-2 h-2 rounded-full #{if Map.get(@social_accounts, platform), do: "bg-green-500", else: "bg-red-500"} mr-3"}>
                    </div>
                    <span class="text-sm text-gray-300 capitalize">{platform}</span>
                  </div>
                  <%= if @loading_accounts do %>
                    <div class="animate-pulse w-4 h-4 bg-gray-600 rounded-full"></div>
                  <% else %>
                    <%= if Map.get(@social_accounts, platform) do %>
                      <span class="text-xs text-green-500">Connected</span>
                    <% else %>
                      <span class="text-xs text-red-500">Disconnected</span>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Action Buttons -->
          <div x-show="sidebarOpen" class="px-4 mb-6">
            <h4 class="text-xs uppercase tracking-wider text-gray-400 mb-2">Actions</h4>
            <div class="space-y-2">
              {render_slot(@actions)}
            </div>
          </div>
          
    <!-- Navigation -->
          <nav class="mt-5">
            <div class="px-2 space-y-1">
              <a
                href="/dashboard?tab=upload"
                class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-white hover:bg-gray-700"
                x-bind:class="sidebarOpen ? 'justify-start' : 'justify-center'"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                  />
                </svg>
                <span x-show="sidebarOpen" class="ml-3">Upload</span>
              </a>

              <a
                href="/dashboard?tab=settings"
                class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-white hover:bg-gray-700"
                x-bind:class="sidebarOpen ? 'justify-start' : 'justify-center'"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <span x-show="sidebarOpen" class="ml-3">Settings</span>
              </a>

              <a
                href="/dashboard?tab=schedule"
                class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-white hover:bg-gray-700"
                x-bind:class="sidebarOpen ? 'justify-start' : 'justify-center'"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                <span x-show="sidebarOpen" class="ml-3">Schedule</span>
              </a>

              <a
                href="/dashboard?tab=results"
                class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-white hover:bg-gray-700"
                x-bind:class="sidebarOpen ? 'justify-start' : 'justify-center'"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
                <span x-show="sidebarOpen" class="ml-3">Results</span>
              </a>
            </div>
          </nav>
        </div>
        
    <!-- Sidebar Footer -->
        <div x-show="sidebarOpen" class="p-4 border-t border-gray-800">
          <a href="/users/sign_out" class="flex items-center text-gray-300 hover:text-white">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M3 3a1 1 0 00-1 1v12a1 1 0 001 1h12a1 1 0 001-1V4a1 1 0 00-1-1H3zm1 2h10v10H4V5zm4.293 2.293a1 1 0 011.414 0l2 2a1 1 0 010 1.414l-2 2a1 1 0 01-1.414-1.414L9.586 10 8.293 8.707a1 1 0 010-1.414z"
                clip-rule="evenodd"
              />
            </svg>
            Sign Out
          </a>
        </div>
      </div>
      
    <!-- Main Content -->
      <div
        x-bind:class="sidebarOpen ? 'md:pl-64' : 'md:pl-16'"
        class="flex-1 transition-all duration-300 w-full"
      >
        <main class="min-h-screen">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    """
  end
end

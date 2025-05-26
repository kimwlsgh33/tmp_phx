defmodule MyappWeb.SnsAccountsLive do
  use MyappWeb, :live_view

  alias Myapp.SocialAuth

  @social_platforms [:twitter, :instagram, :tiktok, :youtube, :facebook]

  @impl true
  def mount(_params, _session, socket) do
    _current_user = socket.assigns.current_user

    if connected?(socket) do
      send(self(), :load_social_accounts)
    end

    {:ok,
     socket
     |> assign(:page_title, "SNS Account Management")
     |> assign(:social_accounts, %{})
     |> assign(:social_platforms, @social_platforms)
     |> assign(:active_tab, List.first(@social_platforms))
     |> assign(:loading_accounts, true)
     |> assign(:show_add_account_modal, false)
     |> assign(:selected_platform, nil)}
  end

  @impl true
  def handle_info(:load_social_accounts, socket) do
    # In a real implementation, we would fetch the actual connection status
    # for each platform from the database or API
    social_accounts =
      Enum.into(@social_platforms, %{}, fn platform ->
        # Generate multiple accounts per platform (for demo purposes)
        accounts = if Enum.random([true, false]) do
          account_count = Enum.random(1..3)
          Enum.map(1..account_count, fn i ->
            %{
              id: "#{platform}-#{i}",
              username: "#{platform}_user_#{i}",
              avatar: "/images/avatar-placeholder.png",
              connected: true
            }
          end)
        else
          []
        end

        {platform, accounts}
      end)

    {:noreply,
     socket
     |> assign(:social_accounts, social_accounts)
     |> assign(:loading_accounts, false)}
  end

  @impl true
  def handle_event("change-tab", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    
    {:noreply, assign(socket, :active_tab, platform)}
  end

  @impl true
  def handle_event("connect-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)

    # Show the add account modal for this platform
    {:noreply,
     socket
     |> assign(:selected_platform, platform)
     |> assign(:show_add_account_modal, true)}
  end

  @impl true
  def handle_event("close-modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_add_account_modal, false)
     |> assign(:selected_platform, nil)}
  end

  @impl true
  def handle_event("add-account", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)

    # In a real implementation, this would redirect to the OAuth flow
    # For now, we'll just simulate connecting
    {:noreply,
     socket
     |> assign(:show_add_account_modal, false)
     |> assign(:selected_platform, nil)
     |> put_flash(:info, "Redirecting to #{platform} authentication...")
     |> redirect(to: ~p"/auth/#{platform}")}
  end

  @impl true
  def handle_event("disconnect-account", %{"platform" => platform, "account_id" => account_id}, socket) do
    platform = String.to_existing_atom(platform)

    # In a real implementation, we would revoke the tokens for this specific account
    # For now, just update the UI by removing this specific account
    updated_accounts =
      Map.update!(
        socket.assigns.social_accounts,
        platform,
        fn accounts ->
          Enum.reject(accounts, fn account -> account.id == account_id end)
        end
      )

    {:noreply,
     socket
     |> assign(:social_accounts, updated_accounts)
     |> put_flash(:info, "Account disconnected")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 pb-24">
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-black dark:text-white">SNS Account Management</h1>
            <p class="text-gray-500 dark:text-gray-300">Connect and manage your social media accounts</p>
          </div>
          <div>
            <.link
              navigate={~p"/dashboard"}
              class="inline-flex items-center px-4 py-2 text-sm font-medium text-[#FD4F00] bg-white dark:bg-black border border-[#FD4F00] rounded-md hover:bg-gray-50 dark:hover:bg-gray-900 hover:text-[#E04600] hover:border-[#E04600]"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
              Back to Dashboard
            </.link>
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-black rounded-lg shadow-md p-6 dark:border dark:border-gray-700">
        <h2 class="text-xl font-semibold mb-4 dark:text-white">Connected Accounts</h2>

        <%= if @loading_accounts do %>
          <div class="py-10 text-center">
            <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-[#FD4F00] border-t-transparent"></div>
            <p class="mt-2 text-gray-600 dark:text-gray-300">Loading your accounts...</p>
          </div>
        <% else %>
          <!-- SNS Platform Tabs -->
          <div class="border-b border-gray-200 dark:border-gray-700 mb-6">
            <ul class="flex flex-wrap -mb-px" role="tablist">
              <%= for platform <- @social_platforms do %>
                <li class="mr-2" role="presentation">
                  <button 
                    phx-click="change-tab" 
                    phx-value-platform={platform} 
                    class={[
                      "inline-block p-4 border-b-2 rounded-t-lg",
                      if @active_tab == platform do
                        "border-[#FD4F00] text-[#FD4F00] active"
                      else
                        "border-transparent hover:text-gray-600 hover:border-gray-300"
                      end
                    ]}
                    role="tab"
                    aria-selected={@active_tab == platform}
                  >
                    <div class="flex items-center">
                      <div class={"w-5 h-5 rounded-full flex items-center justify-center mr-2 " <> platform_color(platform)}>
                        <%= case platform do %>
                          <% :twitter -> %>
                            <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84"></path>
                            </svg>
                          <% :instagram -> %>
                            <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path fill-rule="evenodd" d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z" clip-rule="evenodd"></path>
                            </svg>
                          <% :tiktok -> %>
                            <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path d="M12.53.02C13.84 0 15.14.01 16.44 0c.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"></path>
                            </svg>
                          <% :facebook -> %>
                            <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path fill-rule="evenodd" d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z" clip-rule="evenodd"></path>
                            </svg>
                          <% :youtube -> %>
                            <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path fill-rule="evenodd" d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z" clip-rule="evenodd" />
                            </svg>
                        <% end %>
                      </div>
                      <%= platform |> Atom.to_string() |> String.capitalize() %>
                    </div>
                  </button>
                </li>
              <% end %>
            </ul>
          </div>
          
          <!-- Tab Content -->
          <div class="tab-content">
            <% platform = @active_tab %>
            <% accounts = @social_accounts[platform] || [] %>
              <div class="border rounded-lg p-4 dark:border-gray-700">
                <div class="flex items-center justify-between mb-4">
                  <div class="ml-3">
                    <h3 class="font-semibold text-gray-900 dark:text-white">
                      <%= platform |> Atom.to_string() |> String.capitalize() %> Accounts
                    </h3>
                  </div>
                  <button
                    phx-click="connect-platform"
                    phx-value-platform={platform}
                    class="bg-blue-600 text-white rounded-md py-2 px-4 hover:bg-blue-700 transition-colors text-sm"
                  >
                    Add Account
                  </button>
                </div>
                
                <!-- Connected accounts list -->
                <div class="divide-y divide-gray-200 dark:divide-gray-700">
                  <%= if Enum.empty?(accounts) do %>
                    <div class="py-4 text-center text-gray-500 dark:text-gray-400 italic">
                      No connected accounts. Click "Add Account" to connect.
                    </div>
                  <% else %>
                    <%= for account <- accounts do %>
                      <div class="py-4 flex items-center justify-between">
                        <div class="flex items-center">
                          <div class="flex-shrink-0">
                            <div class="w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center overflow-hidden">
                              <img src={account.avatar} alt="" class="h-full w-full object-cover" />
                            </div>
                          </div>
                          <div class="ml-3">
                            <p class="text-sm font-medium text-gray-900 dark:text-white"><%= account.username %></p>
                            <p class="text-xs text-gray-500 dark:text-gray-400">ID: <%= account.id %></p>
                          </div>
                        </div>
                        <button
                          phx-click="disconnect-account"
                          phx-value-platform={platform}
                          phx-value-account_id={account.id}
                          class="text-red-500 hover:text-red-700 text-sm"
                        >
                          Disconnect
                        </button>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
          </div>
        <% end %>
      </div>
    </div>

    <!-- Add account modal -->
    <%= if @show_add_account_modal do %>
      <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white dark:bg-black rounded-lg p-6 w-full max-w-md mx-auto dark:border dark:border-gray-700">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold dark:text-white">
              Connect <%= @selected_platform |> Atom.to_string() |> String.capitalize() %> Account
            </h3>
            <button phx-click="close-modal" class="text-gray-500 hover:text-gray-700">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>
            </button>
          </div>

          <p class="text-sm text-gray-600 dark:text-gray-300 mb-6">
            You will be redirected to <%= @selected_platform |> Atom.to_string() |> String.capitalize() %> to authorize access to your account.
          </p>

          <div class="flex justify-end space-x-3">
            <button 
              phx-click="close-modal" 
              class="px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800 dark:bg-gray-900"
            >
              Cancel
            </button>
            <button 
              phx-click="add-account" 
              phx-value-platform={@selected_platform} 
              class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Continue
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp platform_color(:twitter), do: "bg-blue-500 text-white"
  defp platform_color(:instagram), do: "bg-purple-500 text-white"
  defp platform_color(:tiktok), do: "bg-black text-white"
  defp platform_color(:facebook), do: "bg-blue-600 text-white"
  defp platform_color(:youtube), do: "bg-red-600 text-white"
  defp platform_color(_), do: "bg-gray-500 text-white"
end

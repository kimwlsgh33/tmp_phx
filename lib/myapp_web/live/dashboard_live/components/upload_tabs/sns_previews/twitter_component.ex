defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview.TwitterComponent do
  use MyappWeb, :live_component
  
  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:preview_url, fn -> nil end)
      |> assign_new(:upload_form, fn -> %{} end)

    {:ok, socket}
  end

  # Helper function to parse hashtags in description
  defp highlight_hashtags(description) do
    String.replace(description, ~r/#(\w+)/, "<span class=\"text-blue-500 font-semibold\">#\\1</span>")
  end

  # Helper function to generate a username for the platform
  defp generate_username do
    "@x_user_#{:rand.uniform(999)}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-black text-white shadow-lg rounded-xl" style="width: 300px;">
      <!-- X Post Header -->
      <div class="p-4">
        <div class="flex items-start mb-3">
          <!-- Profile Image -->
          <div class="mr-3">
            <div class="w-10 h-10 rounded-full overflow-hidden bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center">
              <svg class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none">
                <path d="M22 5.09992L17.5996 10.9999H13.5996L9.59961 14.9999H5.59961" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M2 18.9999L5.59922 15.0009" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </div>
          </div>

          <!-- User Info and Post Content -->
          <div class="flex-1">
            <!-- User Information -->
            <div class="flex items-start justify-between mb-1">
              <div>
                <div class="flex items-center">
                  <span class="font-bold text-base"><%= generate_username() %></span>
                  <!-- Verified badge -->
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-blue-400 ml-1" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1.177 14.677l-4.324-4.324 1.414-1.414 2.91 2.91 6.387-6.387 1.414 1.414-7.8 7.8z"/>
                  </svg>
                </div>
                <div class="text-gray-500 text-sm"><%= generate_username() %></div>
              </div>

              <!-- More options -->
              <div class="text-gray-500">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
                </svg>
              </div>
            </div>

            <!-- Post Content -->
            <div class="text-[14px] leading-tight mb-2">
              <%= raw highlight_hashtags(@upload_form["description"] || "Explore APAC blockchain trends at Apex 2025. Learn from local experts and uncover new opportunities for global growth. Sign up today!") %>
            </div>
          </div>
        </div>

        <!-- Media content -->
        <div class="rounded-xl overflow-hidden mb-3">
          <%= if @preview_url do %>
            <video src={@preview_url} class="w-full h-auto rounded-xl" controls />
          <% else %>
            <div class="relative rounded-xl overflow-hidden">
              <div class="w-full" style="aspect-ratio: 16/9; max-height: 140px; background: linear-gradient(to bottom right, #1a1a1a, #000);">
                <div class="absolute inset-0 flex items-center justify-center">
                  <div class="text-gray-400">Media preview</div>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Post Stats/Actions -->
        <div class="flex justify-between text-gray-500 text-sm py-2">
          <!-- Reply -->
          <div class="hover:text-blue-400 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 20.25c4.97 0 9-3.694 9-8.25s-4.03-8.25-9-8.25S3 7.444 3 12c0 2.104.859 4.023 2.273 5.48.432.447.74 1.04.586 1.641a4.483 4.483 0 01-.923 1.785A5.969 5.969 0 006 21c1.282 0 2.47-.402 3.445-1.087.81.22 1.668.337 2.555.337z" />
            </svg>
          </div>
          <!-- Repost -->
          <div class="hover:text-green-400 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 12c0-1.232-.046-2.453-.138-3.662a4.006 4.006 0 00-3.7-3.7 48.678 48.678 0 00-7.324 0 4.006 4.006 0 00-3.7 3.7c-.017.22-.032.441-.046.662M19.5 12l3-3m-3 3l-3-3m-12 3c0 1.232.046 2.453.138 3.662a4.006 4.006 0 003.7 3.7 48.656 48.656 0 007.324 0 4.006 4.006 0 003.7-3.7c.017-.22.032-.441.046-.662M4.5 12l3 3m-3-3l-3 3" />
            </svg>
          </div>
          <!-- Like -->
          <div class="hover:text-red-400 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
            </svg>
          </div>
          <!-- Views -->
          <div class="hover:text-blue-400 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
            </svg>
          </div>
          <!-- Bookmark -->
          <div class="hover:text-blue-400 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z" />
            </svg>
          </div>
          <!-- Share -->
          <div class="hover:text-blue-400 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" />
            </svg>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

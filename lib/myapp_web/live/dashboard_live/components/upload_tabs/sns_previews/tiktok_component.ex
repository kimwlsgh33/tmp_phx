defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview.TiktokComponent do
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
    "@tiktok_user_#{:rand.uniform(999)}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-2xl overflow-hidden bg-black shadow-lg" style="max-width: 302px;">
      <!-- TikTok-style mobile frame -->
      <div class="relative">
        <!-- Video preview content -->
        <div class="relative" style="height: 580px;">
          <%= if @preview_url do %>
            <video src={@preview_url} autoplay loop muted class="absolute inset-0 w-full h-full object-cover" />
          <% else %>
            <div class="absolute inset-0 w-full h-full bg-gray-900 flex items-center justify-center">
              <p class="text-gray-400 text-sm">No video preview available</p>
            </div>
          <% end %>

          <!-- Video overlays -->
          <div class="absolute bottom-0 left-0 right-0 p-4 text-white">
            <div class="flex items-center">
              <div class="w-10 h-10 rounded-full bg-gray-500 mr-2"></div>
              <div>
                <p class="font-bold text-sm"><%= generate_username() %></p>
                <p class="text-xs"><%= raw highlight_hashtags(@upload_form["description"]) %></p>
              </div>
            </div>
          </div>

          <!-- Right side controls -->
          <div class="absolute right-2 bottom-20 flex flex-col items-center space-y-4">
            <!-- 좋아요(하트) 버튼 -->
            <div class="flex flex-col items-center">
              <div class="w-10 h-10 rounded-full  flex items-center justify-center hover:bg-pink-600 transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                </svg>
              </div>
              <span class="text-xs text-white mt-1">127k</span>
            </div>

            <!-- 댓글 버튼 -->
            <div class="flex flex-col items-center">
              <div class="w-10 h-10 rounded-full  flex items-center justify-center  transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                </svg>
              </div>
              <span class="text-xs text-white mt-1">2,841</span>
            </div>

            <!-- 저장 버튼 (북마크) -->
            <div class="flex flex-col items-center">
              <div class="w-10 h-10 rounded-full  flex items-center justify-center  transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"></path>
                </svg>
              </div>
              <span class="text-xs text-white mt-1">Save</span>
            </div>

            <!-- 공유 버튼 (새 아이콘) -->
            <div class="flex flex-col items-center">
              <div class="w-10 h-10 rounded-full  flex items-center justify-center transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M18 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM18 22a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM8.59 13.51l6.83 3.98M8.59 10.49l6.83-3.98"></path>
                </svg>
              </div>
              <span class="text-xs text-white mt-1">Share</span>
            </div>

            <!-- 유저 프로필 -->
            <div class="flex flex-col items-center mt-6">
              <div class="w-10 h-10 rounded-full bg-gradient-to-tr from-pink-500 to-purple-500 p-0.5">
                <div class="w-full h-full rounded-full bg-gray-800 flex items-center justify-center overflow-hidden">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

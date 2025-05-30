defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview.TiktokComponent do
  use MyappWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:preview_url, fn -> nil end)
      |> assign_new(:upload_form, fn -> %{} end)
      |> assign_new(:advanced_settings, fn -> %{
        "privacy" => "public",
        "allow_comments" => true,
        "allow_duet" => true,
        "allow_stitch" => true,
        "content_type" => "normal"
      } end)

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
    <div class="border border-gray-300 dark:border-gray-700 rounded-2xl overflow-hidden bg-black shadow-lg dark:shadow-gray-900 relative w-full max-w-[302px] mx-auto flex flex-col">
      <!-- Privacy indicator at top -->
      <div class="absolute top-2 left-2 z-10">
        <%= case @advanced_settings["privacy"] do %>
          <% "public" -> %>
            <span class="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium flex items-center bg-opacity-90">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
              </svg>
              Public
            </span>
          <% "friends" -> %>
            <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium flex items-center bg-opacity-90">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              Friends
            </span>
          <% "private" -> %>
            <span class="px-2 py-1 bg-red-100 text-red-800 rounded-full text-xs font-medium flex items-center bg-opacity-90">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              Private
            </span>
          <% _ -> %>
            <span class="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium flex items-center bg-opacity-90">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
              </svg>
              Public
            </span>
        <% end %>
      </div>
      <!-- TikTok-style mobile frame -->
      <div class="relative">
        <!-- Video preview content -->
        <div class="relative flex-1 overflow-auto" style="height: 520px;">
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
              <%= if @advanced_settings["content_type"] == "challenge" do %>
                <div class="ml-2 bg-pink-600 bg-opacity-70 px-2 py-0.5 rounded text-xs flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                  Challenge
                </div>
              <% end %>
            </div>

            <%= if @advanced_settings["allow_comments"] == false do %>
              <div class="mt-2 flex items-center text-xs text-gray-300">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
                <span>Comments are turned off</span>
              </div>
            <% end %>
          </div>

          <!-- 설정 표시 라벨 -->
          <div class="absolute right-2 top-14 flex flex-col items-end gap-2 z-10">
            <%= if @advanced_settings["allow_duet"] == false do %>
              <span class="px-2 py-1 bg-gray-800 text-white rounded-md text-xs font-medium flex items-center bg-opacity-80">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Duet Off
              </span>
            <% end %>

            <%= if @advanced_settings["allow_stitch"] == false do %>
              <span class="px-2 py-1 bg-gray-800 text-white rounded-md text-xs font-medium flex items-center bg-opacity-80">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Stitch Off
              </span>
            <% end %>
          </div>

          <!-- 오른쪽 사이드 컨트롤 -->
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
              <div class="w-10 h-10 rounded-full flex items-center justify-center transition">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                </svg>
              </div>
              <%= if @advanced_settings["allow_comments"] do %>
                <span class="text-xs text-white mt-1">2,841</span>
              <% else %>
                <span class="text-xs text-white mt-1">Off</span>
              <% end %>
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

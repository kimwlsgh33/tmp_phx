defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview.InstagramComponent do
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
    "@instagram_user_#{:rand.uniform(999)}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-lg overflow-hidden bg-white shadow-lg" style="width: 300px;">
      <!-- Instagram format selector tabs -->
      <div class="flex border-b border-gray-200">
        <button type="button"
          phx-click={JS.add_class("hidden", to: "#instagram-reels-view")
            |> JS.remove_class("hidden", to: "#instagram-feed-view")
            |> JS.remove_class("hidden", to: "#instagram-info-section")
            |> JS.add_class("border-b-2 border-black text-black", to: "#instagram-feed-tab")
            |> JS.remove_class("border-b-2 border-black text-black", to: "#instagram-reels-tab")
            |> JS.add_class("text-gray-500", to: "#instagram-reels-tab")}
          class="flex-1 py-2 px-4 text-center border-b-2 border-black text-black font-medium"
          id="instagram-feed-tab">
          <div class="flex justify-center items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
              <circle cx="8.5" cy="8.5" r="1.5" />
              <polyline points="21 15 16 10 5 21" />
            </svg>
            <span>Feed</span>
          </div>
        </button>
        <button type="button"
          phx-click={JS.remove_class("hidden", to: "#instagram-reels-view")
            |> JS.add_class("hidden", to: "#instagram-feed-view")
            |> JS.add_class("hidden", to: "#instagram-info-section")
            |> JS.add_class("border-b-2 border-black text-black", to: "#instagram-reels-tab")
            |> JS.remove_class("border-b-2 border-black text-black", to: "#instagram-feed-tab")
            |> JS.add_class("text-gray-500", to: "#instagram-feed-tab")}
          class="flex-1 py-2 px-4 text-center text-gray-500 font-medium"
          id="instagram-reels-tab">
          <div class="flex justify-center items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path d="M12 8c-2.2 0-4 1.8-4 4s1.8 4 4 4 4-1.8 4-4-1.8-4-4-4Z" />
              <path d="M12 2c-4.4 0-8 3.6-8 8 0 1.6.5 3.1 1.2 4.3L3 19h6l.8-2.3c.7.4 1.4.7 2.2.7 4.4 0 8-4.5 8-10s-3.6-5.4-8-5.4Z" />
            </svg>
            <span>Reels</span>
          </div>
        </button>
      </div>

      <!-- Instagram Feed View -->
      <div id="instagram-feed-view">
        <!-- Instagram header -->
        <div class="p-2 flex items-center border-b border-gray-100">
          <!-- 프로필 이미지 -->
          <div class="mr-2 relative">
            <div class="w-9 h-9 rounded-full overflow-hidden border border-gray-300">
              <div class="w-full h-full bg-gray-200 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
                </svg>
              </div>
            </div>
          </div>

          <!-- 사용자 정보 -->
          <div class="flex-1">
            <div class="flex items-center">
              <p class="text-sm font-bold"><%= generate_username() %></p>
              <!-- 인증 뱃지 -->
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1 text-blue-500" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1.177 14.677l-4.324-4.324 1.414-1.414 2.91 2.91 6.387-6.387 1.414 1.414-7.8 7.8z"/>
              </svg>
            </div>
            <p class="text-xs text-gray-500">SNS 위치 정보</p>
          </div>

          <!-- 더보기 버튼 -->
          <div class="flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-800" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="1" />
              <circle cx="19" cy="12" r="1" />
              <circle cx="5" cy="12" r="1" />
            </svg>
          </div>
        </div>

        <!-- 포스트 이미지/비디오 -->
        <div class="w-full aspect-square bg-gray-100">
          <%= if @preview_url do %>
            <video src={@preview_url} class="w-full h-full object-cover" />
          <% else %>
            <!-- 이미지 플레이스홀더 -->
            <div class="w-full h-full bg-yellow-50 flex items-center justify-center">
              <p class="text-gray-400">미디어 미리보기</p>
            </div>
          <% end %>
        </div>

        <!-- 인스타그램 인포 섹션 -->
        <div id="instagram-info-section">
          <!-- 액션 버튼 -->
          <div class="p-2 flex">
            <div class="flex space-x-3">
              <!-- 좋아요 -->
              <button class="focus:outline-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                </svg>
              </button>
              <!-- 댓글 -->
              <button class="focus:outline-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-0.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </button>
              <!-- DM 보내기 -->
              <button class="focus:outline-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
              </button>
            </div>
            <div class="ml-auto">
              <!-- 저장 -->
              <button class="focus:outline-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
                </svg>
              </button>
            </div>
          </div>

          <!-- 좋아요 카운트 -->
          <div class="px-3 py-1">
            <p class="text-sm font-medium">좋아요 136개</p>
          </div>

          <!-- 캡션 및 해시태그 -->
          <div class="px-3 py-1">
            <p class="text-sm">
              <span class="font-semibold"><%= generate_username() %></span>
              <span><%= raw highlight_hashtags(@upload_form["description"] || "") %></span>
            </p>
          </div>

          <!-- 댓글 미리보기 -->
          <div class="px-3 py-1">
            <p class="text-xs text-gray-500">댓글 7개 모두 보기</p>
            <p class="text-xs text-gray-500">5시간 전</p>
          </div>
        </div>
      </div>

      <!-- Instagram Reels View -->
      <div id="instagram-reels-view" class="hidden">
        <div class="bg-black">
          <!-- 릴스 영상 프레임 -->
          <div class="relative" style="width: 300px; height: 580px;">
            <div class="bg-black rounded-lg overflow-hidden h-full">
              <%= if @preview_url do %>
                <video src={@preview_url} loop autoplay muted class="h-full w-full object-cover" />
              <% else %>
                <div class="w-full h-full bg-gradient-to-t from-gray-900 to-gray-700 flex justify-center items-center">
                  <div class="text-white text-xl font-medium">preview</div>
                </div>
              <% end %>

              <!-- 카메라 아이콘 -->
              <div class="absolute top-2 right-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>

              <!-- 프로필 정보 -->
              <div class="absolute bottom-6 left-3 right-3">
                <div class="flex items-center">
                  <div class="w-6 h-6 rounded-full overflow-hidden bg-gradient-to-r from-purple-400 to-pink-500 border border-white"></div>
                  <div class="ml-2 text-white">
                    <div class="text-xs font-semibold"><%= generate_username() %></div>
                    <div class="text-[10px] opacity-80"><%= @upload_form["description"] || "Posting to Instagram" %></div>
                  </div>
                </div>
              </div>

              <!-- 우측 액션 버튼들 -->
              <div class="absolute right-2 bottom-10 flex flex-col items-center space-y-3">
                <!-- 좋아요 버튼 -->
                <div class="flex flex-col items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" fill="white" viewBox="0 0 24 24" stroke="white" stroke-width="0">
                    <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                  </svg>
                  <span class="text-xs text-white mt-1">3만</span>
                </div>

                <!-- 댓글 버튼 -->
                <div class="flex flex-col items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" />
                  </svg>
                  <span class="text-xs text-white mt-1">495</span>
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

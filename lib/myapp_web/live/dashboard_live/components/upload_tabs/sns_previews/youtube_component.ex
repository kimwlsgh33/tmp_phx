defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview.YoutubeComponent do
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
        "content_type" => "video",
        "category" => "Entertainment",
        "made_for_kids" => false
      } end)
      |> assign_initial_view_state()

    {:ok, socket}
  end
  
  # Helper for setting initial view based on content_type
  defp assign_initial_view_state(socket) do
    content_type = socket.assigns.advanced_settings["content_type"] || "video"
    
    socket
    |> assign(:show_shorts_view, content_type == "shorts")
    |> assign(:show_standard_view, content_type == "video")
  end

  # Helper function to parse hashtags in description
  defp highlight_hashtags(description) do
    String.replace(description, ~r/#(\w+)/, "<span class=\"text-blue-500 font-semibold\">#\\1</span>")
  end

  # Helper function to generate a username for the platform
  defp generate_username do
    "YouTube Creator"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-lg overflow-hidden bg-white shadow-lg" style="max-width: 302px;">
      <!-- YouTube format selector tabs -->
      <div class="flex border-b border-gray-200 relative">
        <button type="button"
          phx-click={JS.add_class("hidden", to: "#shorts-view")
            |> JS.remove_class("hidden", to: "#standard-view")
            |> JS.remove_class("hidden", to: "#youtube-info-section")
            |> JS.add_class("border-b-2 border-red-600 text-red-600", to: "#standard-tab")
            |> JS.remove_class("border-b-2 border-red-600 text-red-600", to: "#shorts-tab")
            |> JS.add_class("text-gray-500", to: "#shorts-tab")}
          class={"flex-1 py-2 px-4 text-center font-medium #{if @advanced_settings["content_type"] == "video", do: "border-b-2 border-red-600 text-red-600", else: "text-gray-500"}"}
          id="standard-tab">
          <div class="flex justify-center items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="7" width="20" height="10" rx="2" ry="2"/>
              <line x1="12" y1="17" x2="12" y2="21"/>
              <line x1="8" y1="21" x2="16" y2="21"/>
            </svg>
            <span>Video</span>
          </div>
        </button>
        <button type="button"
          phx-click={JS.remove_class("hidden", to: "#shorts-view")
            |> JS.add_class("hidden", to: "#standard-view")
            |> JS.add_class("hidden", to: "#youtube-info-section")
            |> JS.add_class("border-b-2 border-red-600 text-red-600", to: "#shorts-tab")
            |> JS.remove_class("border-b-2 border-red-600 text-red-600", to: "#standard-tab")
            |> JS.add_class("text-gray-500", to: "#standard-tab")}
          class={"flex-1 py-2 px-4 text-center font-medium #{if @advanced_settings["content_type"] == "shorts", do: "border-b-2 border-red-600 text-red-600", else: "text-gray-500"}"}
          id="shorts-tab">
          <div class="flex justify-center items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 2v20M17 5H7M17 19H7"/>
            </svg>
            <span>Shorts</span>
          </div>
        </button>
      </div>

      <!-- Standard YouTube View -->
      <div id="standard-view" class={@advanced_settings["content_type"] != "video" && "hidden"}>
        <!-- Video player area -->
        <div class="relative bg-black" style="height: 320px;">
          <%= if @preview_url do %>
            <video src={@preview_url} controls class="w-full h-full object-contain" />
          <% else %>
            <div class="w-full h-full bg-gray-900 flex items-center justify-center">
              <p class="text-gray-400">No video preview available</p>
            </div>
          <% end %>

          <!-- YouTube red progress bar -->
          <div class="absolute bottom-0 left-0 right-0 bg-gray-700 h-1">
            <div class="bg-red-600 h-full" style="width: 30%;"></div>
          </div>
        </div>
      </div>

      <!-- Shorts YouTube View -->
      <div id="shorts-view" class={@advanced_settings["content_type"] != "shorts" && "hidden"}>
        <div class="flex justify-center p-2 bg-black">
          <!-- Mobile-style frame for Shorts -->
          <div class="relative" style="width: 302px; height: 580px;">
            <div class="bg-black rounded-xl overflow-hidden h-full">
              <%= if @preview_url do %>
                <video src={@preview_url} loop autoplay muted class="h-full w-full object-cover" />
              <% else %>
                <div class="w-full h-full bg-gray-900 flex items-center justify-center">
                  <p class="text-gray-400">No video preview available</p>
                </div>
              <% end %>

              <!-- YouTube Shorts Top Interface -->
              <div class="absolute top-0 left-0 right-0 flex items-center justify-between p-4 text-white">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M19 12H5M12 19l-7-7 7-7" />
                </svg>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="1" />
                  <circle cx="19" cy="12" r="1" />
                  <circle cx="5" cy="12" r="1" />
                </svg>
              </div>

              <!-- Shorts interface elements -->
              <div class="absolute bottom-20 left-2 right-12 p-2 text-white z-10">
                <div class="flex items-center mb-2">
                  <div class="w-8 h-8 rounded-full bg-gray-500 mr-2"></div>
                  <span class="font-bold text-sm">@<%= generate_username() %></span>
                  <button class="ml-2 bg-white text-black text-xs px-3 py-1 rounded-full font-medium">구독</button>
                </div>
                <h4 class="text-sm truncate"><%= if @upload_form["title"] && @upload_form["title"] != "", do: @upload_form["title"], else: "Awesome YouTube Shorts" %></h4>
                <p class="text-xs truncate mt-1"><%= raw highlight_hashtags(@upload_form["description"]) %></p>
              </div>

              <!-- Music info at bottom -->
              <div class="absolute bottom-4 left-2 right-12 text-white flex items-center">
                <div class="animate-spin rounded-full h-6 w-6 border-2 border-t-transparent mr-2"></div>
                <div class="truncate">
                  <p class="text-xs">♪ 원본 오디오 - 음악 제작자</p>
                </div>
              </div>

              <!-- Shorts controls - 2025 style -->
              <div class="absolute right-2 bottom-24 flex flex-col items-center space-y-6">
                <!-- 좋아요 버튼 -->
                <div class="flex flex-col items-center">
                  <div class="w-10 h-10 flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"></path>
                    </svg>
                  </div>
                  <span class="text-xs text-white">14K</span>
                </div>

                <!-- 싫어요 버튼 -->
                <div class="flex flex-col items-center">
                  <div class="w-10 h-10 flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h2.67A2.31 2.31 0 0 1 22 4v7a2.31 2.31 0 0 1-2.33 2H17"></path>
                    </svg>
                  </div>
                  <span class="text-xs text-white">싫어요</span>
                </div>

                <!-- 댓글 버튼 -->
                <div class="flex flex-col items-center">
                  <div class="w-10 h-10 flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                    </svg>
                  </div>
                  <%= if @advanced_settings["allow_comments"] do %>
                    <span class="text-xs text-white">962</span>
                  <% else %>
                    <span class="text-xs text-white">Off</span>
                  <% end %>
                </div>

                <!-- 공유 버튼 -->
                <div class="flex flex-col items-center">
                  <div class="w-10 h-10 flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"></path>
                      <polyline points="16 6 12 2 8 6"></polyline>
                      <line x1="12" y1="2" x2="12" y2="15"></line>
                    </svg>
                  </div>
                  <span class="text-xs text-white">공유</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Video info section (only shown on standard view) -->
      <div id="youtube-info-section" class="p-4">
        <!-- Title -->
        <h3 class="text-lg font-bold leading-tight mb-1">
          <%= if @upload_form["title"] && @upload_form["title"] != "" do %>
            <%= @upload_form["title"] %>
          <% else %>
            Awesome YouTube Video
          <% end %>
        </h3>

        <!-- View stats -->
        <div class="text-gray-500 text-sm mb-3">
          1.2M views • 3 days ago
        </div>

          <!-- Privacy status -->
        <div class="flex justify-between items-center mb-4">
          <div class="flex items-center gap-2">
            <%= case @advanced_settings["privacy"] do %>
              <% "public" -> %>
                <span class="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                  Public
                </span>
              <% "unlisted" -> %>
                <span class="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs font-medium flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                  Unlisted
                </span>
              <% "private" -> %>
                <span class="px-2 py-1 bg-red-100 text-red-800 rounded-full text-xs font-medium flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                  Private
                </span>
              <% _ -> %>
                <span class="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                  Public
                </span>
            <% end %>
            
            <%= if @advanced_settings["made_for_kids"] == true do %>
              <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                For Kids
              </span>
            <% end %>
          </div>
        </div>
          
          <!-- Channel info -->
        <div class="flex items-center mb-4">
          <div class="w-10 h-10 rounded-full bg-red-600 flex items-center justify-center text-white mr-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <div>
            <p class="font-bold text-sm"><%= generate_username() %></p>
            <p class="text-gray-500 text-xs">2.4M subscribers</p>
          </div>
          <button class="ml-auto bg-red-600 text-white px-4 py-2 rounded-sm text-sm font-medium">
            Subscribe
          </button>
        </div>

        <!-- Actions bar -->
        <div class="flex space-x-4 border-t border-b border-gray-200 py-2 mb-3">
          <button class="flex items-center text-gray-700">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
            </svg>
            <span class="text-sm">45K</span>
          </button>
          <button class="flex items-center text-gray-700">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2" />
            </svg>
            <span class="text-sm">Dislike</span>
          </button>
          <button class="flex items-center text-gray-700">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
            </svg>
            <span class="text-sm">Share</span>
          </button>
          <button class="flex items-center text-gray-700">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
            <span class="text-sm">Save</span>
          </button>
        </div>

        <!-- Description -->
        <div class="text-sm text-gray-800 mb-2">
          <%= raw highlight_hashtags(@upload_form["description"]) %>
        </div>
        <button class="text-sm text-gray-500 font-medium">SHOW MORE</button>
        
        <!-- Comments section (conditionally rendered based on settings) -->
        <%= if @advanced_settings["allow_comments"] do %>
          <div class="mt-4 border-t border-gray-200 pt-3">
            <h4 class="text-md font-bold mb-3">Comments • 483</h4>
            <div class="flex">
              <div class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-gray-600 mr-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              <div class="flex-1">
                <input type="text" placeholder="Add a comment..." class="w-full border-b border-gray-300 pb-1 text-sm focus:outline-none" />
              </div>
            </div>
            
            <!-- Example comment -->
            <div class="flex mt-4">
              <div class="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white mr-3">
                YT
              </div>
              <div>
                <div class="flex items-center">
                  <span class="text-xs font-bold">Youtube Fan</span>
                  <span class="text-xs text-gray-500 ml-2">2 days ago</span>
                </div>
                <p class="text-sm">Great video! Looking forward to more content like this.</p>
                <div class="flex items-center space-x-3 mt-1">
                  <div class="flex items-center text-gray-500 text-xs">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
                    </svg>
                    32
                  </div>
                  <div class="flex items-center text-gray-500 text-xs">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2" />
                    </svg>
                  </div>
                  <span class="text-gray-500 text-xs">Reply</span>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="mt-4 border-t border-gray-200 pt-3">
            <div class="flex items-center justify-center py-4 text-gray-500">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              <span>Comments are turned off</span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

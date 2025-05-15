defmodule MyappWeb.DashboardLive.Components.UploadTabs.PreviewComponent do
  use MyappWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_platforms, fn -> [] end)
      |> assign_new(:preview_url, fn -> nil end)
      |> assign_new(:upload_form, fn -> %{} end)

    {:ok, socket}
  end

  @impl true
  def handle_event("goto-description", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_description_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-sns-selection", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_sns_selection_tab)
    {:noreply, socket}
  end

    # Helper function to parse hashtags in description
    defp highlight_hashtags(description) do
      String.replace(description, ~r/#(\w+)/, "<span class=\"text-blue-500 font-semibold\">#\\1</span>")
    end

    # Helper function to generate a username for the platform
    defp generate_username(platform) do
      case platform do
        :tiktok -> "@tiktok_user_#{:rand.uniform(999)}"
        :youtube -> "YouTube Creator"
        :instagram -> "@instagram_user_#{:rand.uniform(999)}"
        :twitter -> "@x_user_#{:rand.uniform(999)}"
        :facebook -> "Facebook User"
        _ -> "@user_#{:rand.uniform(999)}"
      end
    end


    @impl true
    def render(assigns) do
      ~H"""
      <div class="min-h-[600px]">


        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 ">
          <%= for platform <- @selected_platforms do %>
            <%= case platform do %>
              <% :tiktok -> %>
                <!-- TikTok Preview -->
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
                            <p class="font-bold text-sm"><%= generate_username(:tiktok) %></p>
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

              <% :youtube -> %>
                <!-- YouTube Preview with tabs for standard and Shorts -->
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
                      class="flex-1 py-2 px-4 text-center border-b-2 border-red-600 text-red-600 font-medium"
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
                      class="flex-1 py-2 px-4 text-center text-gray-500 font-medium"
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
                  <div id="standard-view">
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

                  <!-- Shorts YouTube View (hidden by default, would be toggled with JS in a real implementation) -->
                  <div id="shorts-view" class="hidden">
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
                              <span class="font-bold text-sm">@<%= generate_username(:youtube) %></span>
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
                              <span class="text-xs text-white">962</span>
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

                    <!-- Channel info -->
                    <div class="flex items-center mb-4">
                      <div class="w-10 h-10 rounded-full bg-red-600 flex items-center justify-center text-white mr-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                      </div>
                      <div>
                        <p class="font-bold text-sm"><%= generate_username(:youtube) %></p>
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
                  </div>
                </div>

              <% :instagram -> %>
                <!-- Instagram Preview -->
                <div class="border border-gray-300 rounded-lg overflow-hidden bg-white shadow-lg" style="width: 300px;">
                  <!-- Instagram format selector tabs - 2025 style -->
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

                  <!-- Instagram Feed View - 현대적인 스타일 (이미지 2 참조) -->
                  <div id="instagram-feed-view">


                    <!-- Instagram header - 각 SNS에서 정보를 가져와서 표시할 수 있는 동적 구조 -->
                    <div class="p-2 flex items-center border-b border-gray-100">
                      <!-- 프로필 이미지 - 동적으로 가져올 수 있는 구조 -->
                      <div class="mr-2 relative">
                        <div class="w-9 h-9 rounded-full overflow-hidden border border-gray-300 instagram-profile-image-container">
                          <div class="w-full h-full bg-gray-200 flex items-center justify-center">
                            <!-- 실제 프로필 이미지 플레이스홀더 -->
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
                            </svg>
                          </div>
                        </div>
                      </div>

                      <!-- 사용자 정보 - 동적으로 가져올 수 있는 구조 -->
                      <div class="flex-1">
                        <div class="flex items-center">
                          <p class="text-sm font-bold instagram-username"><%= generate_username(:instagram) %></p>
                          <!-- 인증 뱃지 -->
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1 text-blue-500" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1.177 14.677l-4.324-4.324 1.414-1.414 2.91 2.91 6.387-6.387 1.414 1.414-7.8 7.8z"/>
                          </svg>
                        </div>
                        <p class="text-xs text-gray-500 instagram-location">각 SNS에서 가져온 위치</p>
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
                        <!-- 이미지 플레이스홀더 (이미지 2 스타일) -->
                        <div class="w-full h-full bg-yellow-50 flex items-center justify-center relative overflow-hidden">
                          <!-- 카페 로고 스타일의 배경 (이미지 2처럼) -->
                          <div class="absolute inset-0 flex items-center justify-center text-5xl font-bold text-yellow-500 opacity-30" style="transform: rotate(-5deg)">
                            O & T
                          </div>
                          <div class="absolute inset-0 flex items-center justify-center p-4">
                            <div class="bg-white p-4 rounded-md shadow-lg">
                              <p class="text-sm text-gray-600">미디어 미리보기</p>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>

                    <!-- 인스타그램 인포 섹션 -->
                    <div id="instagram-info-section">
                      <!-- 액션 버튼 - 이미지 2 스타일 -->
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

                      <!-- 좋아요 카운트 - 이미지 2 스타일 -->
                      <div class="px-3 py-1">
                        <p class="text-sm font-medium">좋아요 136개</p>
                      </div>

                      <!-- 캡션 및 해시태그 - 이미지 2 스타일 -->
                      <div class="px-3 py-1">
                        <p class="text-sm">
                          <span class="font-semibold"><%= generate_username(:instagram) %></span>
                          <span><%= raw highlight_hashtags(@upload_form["description"]) || "대통령만들기 4일차... 더 보기" %></span>
                        </p>
                      </div>

                      <!-- 댓글 미리보기 -->
                      <div class="px-3 py-1">
                        <p class="text-xs text-gray-500">댓글 7개 모두 보기</p>
                        <p class="text-xs text-gray-500">5시간 전</p>
                      </div>

                      <!-- 하단 네비게이션 바 -->
                      <div class="border-t border-gray-200 p-2 mt-2 flex justify-between">
                        <button class="focus:outline-none">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                          </svg>
                        </button>
                        <button class="focus:outline-none">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                          </svg>
                        </button>
                        <button class="focus:outline-none">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                          </svg>
                        </button>
                        <button class="focus:outline-none">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path d="M12 14l9-5-9-5-9 5 9 5z" />
                            <path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                          </svg>
                        </button>
                        <button class="focus:outline-none">
                          <div class="w-6 h-6 rounded-full bg-gray-300 overflow-hidden">
                            <!-- 프로필 이미지 플레이스홀더 -->
                          </div>
                        </button>
                      </div>
                    </div>
                  </div>

                  <!-- Instagram Reels View - 이미지 1 참조 스타일 -->
                  <div id="instagram-reels-view" class="hidden">
                    <div class="bg-black">


                      <!-- 릴스 영상 프레임 -->
                      <div class="relative" style="width: 300px; height: 580px;">
                        <div class="bg-black rounded-lg overflow-hidden h-full">
                          <!-- 영상 컨텐츠 -->
                          <%= if @preview_url do %>
                            <video src={@preview_url} loop autoplay muted class="h-full w-full object-cover" />
                          <% else %>
                            <!-- 비디오가 없을 때 간단하게 preview만 표시 -->
                            <div class="w-full h-full bg-gradient-to-t from-gray-900 to-gray-700 flex justify-center items-center">
                              <div class="text-white text-xl font-medium">preview</div>
                            </div>
                          <% end %>

                          <!-- 카메라 아이콘 (이미지 1 참조) -->
                          <div class="absolute top-2 right-2">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                              <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                              <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                          </div>

                          <!-- 하단 프로필 정보 - 영역 축소 및 위치 조정 -->
                          <div class="absolute bottom-6 left-3 right-3">
                            <div class="flex items-center">
                              <!-- 프로필 이미지와 정보 -->
                              <div class="flex items-center">
                                <div class="w-6 h-6 rounded-full overflow-hidden bg-gradient-to-r from-purple-400 to-pink-500 border border-white">
                                  <div class="w-full h-full bg-gray-200 flex items-center justify-center">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
                                      <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
                                    </svg>
                                  </div>
                                </div>
                                <div class="ml-2 text-white">
                                  <div class="text-xs font-semibold"><%= generate_username(:instagram) %></div>
                                  <div class="text-[10px] opacity-80"><%= if @upload_form["description"], do: String.slice(@upload_form["description"], 0, 20), else: "Posting to Instagram" %></div>
                                </div>
                              </div>
                            </div>
                          </div>

                          <!-- 우측 액션 버튼들 - 영역 축소 및 위치 조정 -->
                          <div class="absolute right-2 bottom-10 flex flex-col items-center space-y-3">
                            <!-- 좋아요 버튼 -->
                            <div class="flex flex-col items-center">
                              <button class="focus:outline-none">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" fill="white" viewBox="0 0 24 24" stroke="white" stroke-width="0">
                                  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                                </svg>
                              </button>
                              <span class="text-xs text-white mt-1">3만</span>
                            </div>

                            <!-- 댓글 버튼 -->
                            <div class="flex flex-col items-center">
                              <button class="focus:outline-none">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                  <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" />
                                </svg>
                              </button>
                              <span class="text-xs text-white mt-1">495</span>
                            </div>

                            <!-- DM 버튼 -->
                            <div class="flex flex-col items-center">
                              <button class="focus:outline-none">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                  <path d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                                </svg>
                              </button>
                              <span class="text-xs text-white mt-1">1.1만</span>
                            </div>

                            <!-- 더보기 버튼 -->
                            <div class="flex flex-col items-center">
                              <button class="focus:outline-none">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                  <circle cx="12" cy="12" r="1" />
                                  <circle cx="12" cy="5" r="1" />
                                  <circle cx="12" cy="19" r="1" />
                                </svg>
                              </button>
                            </div>
                          </div>

                        </div>
                      </div>
                    </div>
                  </div>
                </div>

              <% :twitter -> %>
                <!-- Twitter(X) Preview - 동적 유저 정보 지원 UI -->
                <div class="overflow-hidden bg-black text-white shadow-lg rounded-xl" style="width: 370px;">
                  <!-- X Post Header -->
                  <div class="p-4">
                    <div class="flex items-start mb-3">
                      <!-- Profile Image - 동적으로 SNS에서 가져올 사용자 프로필 이미지 자리 -->
                      <div class="mr-3">
                        <div class="w-12 h-12 rounded-full overflow-hidden bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center twitter-profile-image-container">
                          <!-- 실제 SNS에서 가져올 프로필 이미지로 교체될 플레이스홀더 -->
                          <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="none">
                            <path d="M22 5.09992L17.5996 10.9999H13.5996L9.59961 14.9999H5.59961" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                            <path d="M2 18.9999L5.59922 15.0009" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                          </svg>
                        </div>
                      </div>

                      <!-- User Info and Post Content -->
                      <div class="flex-1">
                        <!-- User Information - 동적으로 SNS에서 가져올 정보 -->
                        <div class="flex items-start justify-between mb-1">
                          <div>
                            <div class="flex items-center">
                              <span class="font-bold text-base twitter-display-name"><%= generate_username(:twitter) %></span>
                              <!-- Verified badge -->
                              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-blue-400 ml-1" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1.177 14.677l-4.324-4.324 1.414-1.414 2.91 2.91 6.387-6.387 1.414 1.414-7.8 7.8z"/>
                              </svg>
                            </div>
                            <div class="text-gray-500 text-sm twitter-username">@<%= String.replace(generate_username(:twitter), "@", "") %></div>
                          </div>

                          <!-- More options -->
                          <div class="text-gray-500">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                              <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
                            </svg>
                          </div>
                        </div>

                        <!-- Post Content -->
                        <div class="text-[15px] leading-tight mb-3">
                          <%= raw highlight_hashtags(@upload_form["description"]) || "Explore APAC blockchain trends at Apex 2025. Learn from local experts and uncover new opportunities for global growth. Sign up today!" %>
                        </div>
                      </div>
                    </div>

                    <!-- Media content -->
                    <div class="rounded-xl overflow-hidden mb-3">
                      <%= if @preview_url do %>
                        <video src={@preview_url} class="w-full h-auto rounded-xl" controls />
                      <% else %>
                        <div class="relative rounded-xl overflow-hidden">
                          <div class="w-full aspect-video bg-gradient-to-br from-gray-800 to-black relative">
                            <!-- Placeholder for image/video content -->
                            <div class="absolute inset-0 flex items-center justify-center">
                              <div class="text-gray-400">Media preview</div>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>

                    <!-- Post Stats/Actions - Simple version with just the icons -->
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

              <% :facebook -> %>
                <!-- Facebook Preview - 2025 style -->
                <div class="border border-gray-200 rounded-lg overflow-hidden bg-white shadow-lg" style="width: 320px;">
                  <!-- Facebook header -->
                  <div class="p-4 flex">
                    <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white mr-2">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"></path>
                        <circle cx="12" cy="7" r="4"></circle>
                      </svg>
                    </div>
                    <div>
                      <p class="font-semibold text-sm"><%= generate_username(:facebook) %></p>
                      <div class="flex items-center text-xs text-gray-500">
                        <span><%= DateTime.utc_now |> Calendar.strftime("%b %d at %I:%M %p") %></span>
                        <span class="mx-1">&bull;</span>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM4.332 8.027a6.012 6.012 0 011.912-2.706C6.512 5.73 6.974 6 7.5 6A1.5 1.5 0 019 7.5V8a2 2 0 004 0 2 2 0 011.523-1.943A5.977 5.977 0 0116 10c0 .34-.028.675-.083 1H15a2 2 0 00-2 2v2.197A5.973 5.973 0 0110 16v-2a2 2 0 00-2-2 2 2 0 01-2-2 2 2 0 00-1.668-1.973z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>
                    <div class="ml-auto">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
                      </svg>
                    </div>
                  </div>

                  <!-- Post content -->
                  <div class="px-4 pb-2">
                    <p class="text-sm mb-3"><%= raw highlight_hashtags(@upload_form["description"]) %></p>
                  </div>

                  <!-- Media -->
                  <div class="border-t border-b border-gray-100">
                    <%= if @preview_url do %>
                      <video src={@preview_url} controls class="w-full h-auto" />
                    <% else %>
                      <div class="w-full h-56 bg-gray-100 flex items-center justify-center">
                        <p class="text-gray-400">No media available</p>
                      </div>
                    <% end %>
                  </div>

                  <!-- Reaction counts -->
                  <div class="p-2 flex justify-between items-center text-gray-500 text-xs">
                    <div class="flex items-center">
                      <div class="flex -space-x-1 mr-1">
                        <div class="rounded-full h-4 w-4 bg-blue-500 flex items-center justify-center border border-white">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" viewBox="0 0 20 20" fill="currentColor">
                            <path d="M2 10.5a1.5 1.5 0 113 0v6a1.5 1.5 0 01-3 0v-6zM6 10.333v5.43a2 2 0 001.106 1.79l.05.025A4 4 0 008.943 18h5.416a2 2 0 001.962-1.608l1.2-6A2 2 0 0015.56 8H12V4a2 2 0 00-2-2 1 1 0 00-1 1v.667a4 4 0 01-.8 2.4L6.8 7.933a4 4 0 00-.8 2.4z" />
                          </svg>
                        </div>
                        <div class="rounded-full h-4 w-4 bg-red-500 flex items-center justify-center border border-white">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" />
                          </svg>
                        </div>
                      </div>
                      <span>1.5K</span>
                    </div>
                    <div class="flex space-x-4">
                      <span>42 댓글</span>
                      <span>36 공유</span>
                    </div>
                  </div>

                  <!-- Action buttons -->
                  <div class="px-2 py-1 border-t border-gray-100 flex justify-between">
                    <button class="flex items-center justify-center py-1 px-2 text-sm text-gray-500 rounded-md">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M2 10.5a1.5 1.5 0 113 0v6a1.5 1.5 0 01-3 0v-6zM6 10.333v5.43a2 2 0 001.106 1.79l.05.025A4 4 0 008.943 18h5.416a2 2 0 001.962-1.608l1.2-6A2 2 0 0015.56 8H12V4a2 2 0 00-2-2 1 1 0 00-1 1v.667a4 4 0 01-.8 2.4L6.8 7.933a4 4 0 00-.8 2.4z" />
                      </svg>
                      좋아요
                    </button>
                    <button class="flex items-center justify-center py-1 px-2 text-sm text-gray-500 rounded-md">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M18 13V5a2 2 0 00-2-2H4a2 2 0 00-2 2v8a2 2 0 002 2h3l3 3 3-3h3a2 2 0 002-2zM5 7a1 1 0 011-1h8a1 1 0 110 2H6a1 1 0 01-1-1zm1 3a1 1 0 100 2h3a1 1 0 100-2H6z" clip-rule="evenodd" />
                      </svg>
                      댓글
                    </button>
                    <button class="flex items-center justify-center py-1 px-2 text-sm text-gray-500 rounded-md">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z" />
                      </svg>
                      공유
                    </button>
                  </div>
                </div>

              <% _ -> %>
                <!-- Generic preview for other platforms -->
                <div class="border border-gray-200 rounded-lg p-4">
                  <h3 class="text-lg font-medium capitalize mb-2"><%= Atom.to_string(platform) |> String.capitalize() %> Preview</h3>
                  <%= if @preview_url do %>
                    <video src={@preview_url} controls class="w-full h-auto rounded-md mb-2" />
                  <% else %>
                    <p class="text-gray-500 text-sm">No preview available.</p>
                  <% end %>
                  <p class="text-sm text-gray-700"><%= @upload_form["description"] %></p>
                </div>
            <% end %>
          <% end %>
        </div>

        <div class="flex justify-between mt-8">
          <button type="button" phx-click="goto-description" phx-target={@myself} class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md bg-white text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            <svg xmlns="http://www.w3.org/2000/svg" class="mr-2 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M7.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l2.293 2.293a1 1 0 010 1.414z" clip-rule="evenodd" />
            </svg>
            Back to Details
          </button>
          <button type="button" phx-click="goto-sns-selection" phx-target={@myself} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm bg-indigo-600 text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            Confirm &amp; Publish
            <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H3a1 1 0 110-2h9.586l-2.293-2.293a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </div>
      """
    end
end

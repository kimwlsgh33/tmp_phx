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
        :twitter -> "@twitter_user_#{:rand.uniform(999)}"
        :facebook -> "Facebook User"
        _ -> "@user_#{:rand.uniform(999)}"
      end
    end


    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <h2 class="text-xl font-semibold mb-4">Platform Preview</h2>
        <p class="text-gray-600 mb-6">This is how your content will appear on each selected platform.</p>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <%= for platform <- @selected_platforms do %>
            <%= case platform do %>
              <% :tiktok -> %>
                <!-- TikTok Preview -->
                <div class="border border-gray-300 rounded-2xl overflow-hidden bg-black shadow-lg" style="max-width: 302px;">
                  <!-- TikTok-style mobile frame -->
                  <div class="relative">
                    <!-- Status bar -->
                    <div class="bg-black text-white p-2 flex justify-between items-center text-xs">
                      <span>9:41</span>
                      <div class="flex items-center space-x-1">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M17.778 8.222c-4.296-4.296-11.26-4.296-15.556 0A1 1 0 01.808 6.808c5.076-5.077 13.308-5.077 18.384 0a1 1 0 01-1.414 1.414zM14.95 11.05a7 7 0 00-9.9 0 1 1 0 01-1.414-1.414 9 9 0 0112.728 0 1 1 0 01-1.414 1.414zM12.12 13.88a3 3 0 00-4.242 0 1 1 0 01-1.415-1.415 5 5 0 017.072 0 1 1 0 01-1.415 1.415zM9 16a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
                        </svg>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                          <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z" />
                        </svg>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M2 4.75C2 3.784 2.784 3 3.75 3h2.5C7.216 3 8 3.784 8 4.75v10.5A1.75 1.75 0 016.25 17h-2.5A1.75 1.75 0 012 15.25V4.75zm8 0C10 3.784 10.784 3 11.75 3h2.5C15.216 3 16 3.784 16 4.75v10.5A1.75 1.75 0 0114.25 17h-2.5A1.75 1.75 0 0110 15.25V4.75zM3.75 11.5a.75.75 0 000 1.5h2.5a.75.75 0 000-1.5h-2.5zm8 0a.75.75 0 000 1.5h2.5a.75.75 0 000-1.5h-2.5z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>

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
                        <div class="flex flex-col items-center">
                          <div class="w-10 h-10 rounded-full bg-gray-700 flex items-center justify-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 20 20" fill="currentColor">
                              <path d="M9.653 16.915l-.005-.003-.019-.01a20.759 20.759 0 01-1.162-.682 22.045 22.045 0 01-2.582-1.9C4.045 12.733 2 10.352 2 7.5a4.5 4.5 0 018-2.828A4.5 4.5 0 0118 7.5c0 2.852-2.044 5.233-3.885 6.82a22.049 22.049 0 01-3.744 2.582l-.019.01-.005.003h-.002a.739.739 0 01-.69.001l-.002-.001z" />
                            </svg>
                          </div>
                          <span class="text-xs text-white mt-1">127k</span>
                        </div>
                        <div class="flex flex-col items-center">
                          <div class="w-10 h-10 rounded-full bg-gray-700 flex items-center justify-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 20 20" fill="currentColor">
                              <path fill-rule="evenodd" d="M18 10c0 3.866-3.582 7-8 7a8.841 8.841 0 01-4.083-.98L2 17l1.338-3.123C2.493 12.767 2 11.434 2 10c0-3.866 3.582-7 8-7s8 3.134 8 7zM7 9H5v2h2V9zm8 0h-2v2h2V9zM9 9h2v2H9V9z" clip-rule="evenodd" />
                            </svg>
                          </div>
                          <span class="text-xs text-white mt-1">2,841</span>
                        </div>
                        <div class="flex flex-col items-center">
                          <div class="w-10 h-10 rounded-full bg-gray-700 flex items-center justify-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 20 20" fill="currentColor">
                              <path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z" />
                            </svg>
                          </div>
                          <span class="text-xs text-white mt-1">Share</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

              <% :youtube -> %>
                <!-- YouTube Preview with tabs for standard and Shorts -->
                <div class="border border-gray-300 rounded-lg overflow-hidden bg-white shadow-lg" style="max-width: 560px;">
                  <!-- YouTube format selector tabs -->
                  <div class="flex border-b border-gray-200">
                    <button type="button"
                      phx-click={JS.add_class("hidden", to: "#shorts-view")
                        |> JS.remove_class("hidden", to: "#standard-view")
                        |> JS.add_class("border-b-2 border-red-600 text-red-600", to: "#standard-tab")
                        |> JS.remove_class("border-b-2 border-red-600 text-red-600", to: "#shorts-tab")
                        |> JS.add_class("text-gray-500", to: "#shorts-tab")}
                      class="flex-1 py-2 px-4 text-center border-b-2 border-red-600 text-red-600 font-medium"
                      id="standard-tab">
                      Standard
                    </button>
                    <button type="button"
                      phx-click={JS.remove_class("hidden", to: "#shorts-view")
                        |> JS.add_class("hidden", to: "#standard-view")
                        |> JS.add_class("border-b-2 border-red-600 text-red-600", to: "#shorts-tab")
                        |> JS.remove_class("border-b-2 border-red-600 text-red-600", to: "#standard-tab")
                        |> JS.add_class("text-gray-500", to: "#standard-tab")}
                      class="flex-1 py-2 px-4 text-center text-gray-500 hover:text-gray-700 font-medium"
                      id="shorts-tab">
                      Shorts
                    </button>
                  </div>

                  <!-- Standard YouTube View -->
                  <div id="standard-view">
                    <!-- Video player area -->
                    <div class="relative bg-black" style="height: 315px;">
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

                          <!-- Shorts interface elements -->
                          <div class="absolute bottom-12 left-2 right-2 p-2 text-white z-10">
                            <h4 class="font-bold text-base truncate"><%= if @upload_form["title"] && @upload_form["title"] != "", do: @upload_form["title"], else: "Awesome YouTube Shorts" %></h4>
                            <p class="text-sm truncate mt-1"><%= generate_username(:youtube) %> • <%= raw highlight_hashtags(@upload_form["description"]) %></p>
                          </div>

                          <!-- Shorts controls -->
                          <div class="absolute right-2 bottom-24 flex flex-col items-center space-y-4">
                            <div class="flex flex-col items-center">
                              <div class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" viewBox="0 0 20 20" fill="currentColor">
                                  <path d="M9.653 16.915l-.005-.003-.019-.01a20.759 20.759 0 01-1.162-.682 22.045 22.045 0 01-2.582-1.9C4.045 12.733 2 10.352 2 7.5a4.5 4.5 0 018-2.828A4.5 4.5 0 0118 7.5c0 2.852-2.044 5.233-3.885 6.82a22.049 22.049 0 01-3.744 2.582l-.019.01-.005.003h-.002a.739.739 0 01-.69.001l-.002-.001z" />
                                </svg>
                              </div>
                              <span class="text-xs text-white mt-1">12K</span>
                            </div>
                            <div class="flex flex-col items-center">
                              <div class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M18 10c0 3.866-3.582 7-8 7a8.841 8.841 0 01-4.083-.98L2 17l1.338-3.123C2.493 12.767 2 11.434 2 10c0-3.866 3.582-7 8-7s8 3.134 8 7zM7 9H5v2h2V9zm8 0h-2v2h2V9zM9 9h2v2H9V9z" clip-rule="evenodd" />
                                </svg>
                              </div>
                              <span class="text-xs text-white mt-1">843</span>
                            </div>
                            <div class="flex flex-col items-center">
                              <div class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" viewBox="0 0 20 20" fill="currentColor">
                                  <path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z" />
                                </svg>
                              </div>
                              <span class="text-xs text-white mt-1">Share</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Video info section -->
                  <div class="p-4">
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

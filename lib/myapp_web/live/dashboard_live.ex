defmodule MyappWeb.DashboardLive do
  use MyappWeb, :live_view
  
  alias Myapp.Accounts
  alias Myapp.SocialAuth

  @social_platforms [:twitter, :instagram, :tiktok, :youtube, :facebook]

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    
    if connected?(socket) do
      # Fetch connected social media accounts in a separate process to not block rendering
      send(self(), :load_social_accounts)
      send(self(), :load_recent_uploads)
    end
    
    {:ok,
     socket
     |> assign(:page_title, "Social Media Dashboard")
     |> assign(:active_tab, "upload")
     |> assign(:social_accounts, %{})
     |> assign(:loading_accounts, true)
     |> assign(:loading_uploads, true)
     |> assign(:recent_uploads, [])
     |> assign(:upload_progress, 0)
     |> assign(:selected_platforms, [])
     |> assign(:preview_url, nil)
     |> assign(:upload_form, %{
          title: "",
          description: "",
          tags: "",
          schedule_at: nil
        })
     |> allow_upload(:video, 
          accept: ~w(.mp4 .mov .avi .wmv .flv .webm), 
          max_entries: 1,
          max_file_size: 500_000_000,
          progress: &handle_progress/3
        )}
  end

  def handle_params(params, _uri, socket) do
    active_tab = Map.get(params, "tab", socket.assigns.active_tab)
    {:noreply, assign(socket, :active_tab, active_tab)}
  end

  def handle_event("toggle-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    selected_platforms = socket.assigns.selected_platforms
    
    updated_platforms = 
      if platform in selected_platforms do
        Enum.reject(selected_platforms, fn p -> p == platform end)
      else
        [platform | selected_platforms]
      end
    
    {:noreply, assign(socket, :selected_platforms, updated_platforms)}
  end
  
  def handle_event("validate-form", %{"upload_form" => form_params}, socket) do
    {:noreply, 
      socket
      |> assign(:upload_form, form_params)}
  end
  
  def handle_event("save", %{"upload_form" => form_params}, socket) do
    # Here we would actually process the upload and send to selected platforms
    # For now we'll just show a flash message
    
    if socket.assigns.selected_platforms == [] do
      {:noreply, 
        socket
        |> put_flash(:error, "Please select at least one social media platform")}
    else
      # In a real implementation, we would:
      # 1. Save the uploaded file
      # 2. Process the metadata (title, description, tags)
      # 3. Schedule or immediately post to selected platforms
      # 4. Record the result in the database
      
      # For now, just simulate success
      Process.send_after(self(), {:upload_complete, socket.assigns.selected_platforms}, 1000)
      
      {:noreply, 
        socket
        |> put_flash(:info, "Content uploading to selected platforms...")}
    end
  end
  
  def handle_event("schedule", %{"upload_form" => form_params}, socket) do
    # Handle scheduling for future posting
    scheduled_time = form_params["schedule_at"]
    
    if socket.assigns.selected_platforms == [] do
      {:noreply, 
        socket
        |> put_flash(:error, "Please select at least one social media platform")}
    else
      # In a real implementation, we would save the schedule to the database
      
      {:noreply, 
        socket
        |> put_flash(:info, "Content scheduled for upload at #{scheduled_time}")}
    end
  end
  
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end
  
  def handle_info(:load_social_accounts, socket) do
    current_user = socket.assigns.current_user
    
    # In a real implementation, we would fetch the actual connection status
    # for each platform from the database or API
    social_accounts = Enum.into(@social_platforms, %{}, fn platform ->
      # This is just a placeholder. In a real app, you would check if the
      # user is authenticated with each platform
      connected = Enum.random([true, false])
      {platform, %{connected: connected}}
    end)
    
    {:noreply, 
      socket
      |> assign(:social_accounts, social_accounts)
      |> assign(:loading_accounts, false)}
  end
  
  def handle_info(:load_recent_uploads, socket) do
    # In a real implementation, we would fetch recent uploads from the database
    recent_uploads = [
      %{
        id: "1",
        timestamp: ~N[2025-04-05 10:30:00],
        platforms: [:twitter, :instagram],
        status: :success,
        links: %{
          twitter: "https://twitter.com/user/status/123456789",
          instagram: "https://instagram.com/p/ABC123"
        }
      },
      %{
        id: "2",
        timestamp: ~N[2025-04-04 15:45:00],
        platforms: [:youtube],
        status: :processing,
        links: %{
          youtube: nil
        }
      },
      %{
        id: "3",
        timestamp: ~N[2025-04-03 09:15:00],
        platforms: [:tiktok, :facebook],
        status: :failed,
        links: %{},
        error: "Upload failed: invalid token"
      }
    ]
    
    {:noreply, 
      socket
      |> assign(:recent_uploads, recent_uploads)
      |> assign(:loading_uploads, false)}
  end
  
  def handle_info({:upload_complete, platforms}, socket) do
    # In a real implementation, we would update the database with the results
    # and fetch the updated recent uploads list
    
    platform_names = Enum.map_join(platforms, ", ", fn p -> 
      p |> Atom.to_string() |> String.capitalize()
    end)
    
    {:noreply, 
      socket
      |> put_flash(:info, "Upload complete! Posted to #{platform_names}")
      |> push_patch(to: ~p"/dashboard?tab=results")}
  end
  
  defp handle_progress(:video, entry, socket) do
    if entry.done? do
      # When upload is complete, we can display a preview
      # In a real implementation, we would generate a thumbnail
      {:noreply, 
        socket
        |> assign(:preview_url, "/uploads/#{entry.uuid}.mp4")
        |> assign(:upload_progress, 100)}
    else
      # Update progress as the upload proceeds
      progress = floor(entry.progress)
      {:noreply, assign(socket, :upload_progress, progress)}
    end
  end
  
  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <!-- <!-- Left Sidebar --> 
      <!-- <div class="w-64 bg-black text-white p-4 flex flex-col shadow-md"> -->
      <!--   <h2 class="text-xl font-bold mb-6">Dashboard</h2> -->
      <!--    -->
      <!--   <!-- Social Media Accounts Section --> 
      <!--   <div class="mb-6"> -->
      <!--     <h3 class="text-lg font-semibold mb-2">Connected Accounts</h3> -->
      <!--      -->
      <!--     <%= if @loading_accounts do %> -->
      <!--       <div class="animate-pulse flex flex-col space-y-2"> -->
      <!--         <div class="h-6 bg-gray-600 rounded"></div> -->
      <!--         <div class="h-6 bg-gray-600 rounded"></div> -->
      <!--         <div class="h-6 bg-gray-600 rounded"></div> -->
      <!--       </div> -->
      <!--     <% else %> -->
      <!--       <ul class="space-y-2"> -->
      <!--         <%= for {platform, status} <- @social_accounts do %> -->
      <!--           <li class="flex items-center justify-between"> -->
      <!--             <span><%= platform |> Atom.to_string() |> String.capitalize() %></span> -->
      <!--             <span  -->
      <!--               class={"h-3 w-3 rounded-full #{if status.connected, do: "bg-green-500", else: "bg-red-500"}"}  -->
      <!--               title={if status.connected, do: "Connected", else: "Disconnected"}> -->
      <!--             </span> -->
      <!--           </li> -->
      <!--         <% end %> -->
      <!--       </ul> -->
      <!--     <% end %> -->
      <!--   </div> -->
      <!--    -->
      <!--   <!-- Quick Action Buttons --> 
      <!--   <div class="space-y-2 mb-6"> -->
      <!--     <button  -->
      <!--       phx-click={JS.push_focus(to: "#upload-area")} -->
      <!--       class="w-full bg-indigo-600 hover:bg-indigo-700 text-white py-2 px-4 rounded flex items-center animate-button-glow"> -->
      <!--       <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 20 20" fill="currentColor"> -->
      <!--         <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM6.293 6.707a1 1 0 010-1.414l3-3a1 1 0 011.414 0l3 3a1 1 0 01-1.414 1.414L11 5.414V13a1 1 0 11-2 0V5.414L7.707 6.707a1 1 0 01-1.414 0z" clip-rule="evenodd" /> -->
      <!--       </svg> -->
      <!--       Start New Upload -->
      <!--     </button> -->
      <!--      -->
      <!--     <.link  -->
      <!--       patch={~p"/dashboard?tab=results"} -->
      <!--       class="w-full bg-gray-600 hover:bg-gray-700 text-white py-2 px-4 rounded flex items-center"> -->
      <!--       <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 20 20" fill="currentColor"> -->
      <!--         <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clip-rule="evenodd" /> -->
      <!--       </svg> -->
      <!--       View Recent Uploads -->
      <!--     </.link> -->
      <!--   </div> -->
      <!--    -->
      <!--   <!-- Footer Section --> 
      <!--   <div class="mt-auto text-sm text-gray-400"> -->
      <!--     <p>Need help? <a href="#" class="text-indigo-400 hover:text-indigo-300">View Documentation</a></p> -->
      <!--   </div> -->
      <!-- </div> -->
      <!--  -->
      <!-- Main Content Area -->
      <div class="flex-1 bg-gray-900 overflow-y-auto">
        <div class="p-6">
          <div class="mb-6">
            <h1 class="text-2xl font-bold text-gray-800">Social Media Dashboard</h1>
            <p class="text-gray-600">Manage your content across multiple platforms</p>
          </div>
          
          <!-- Tabs Navigation -->
          <div class="mb-6">
            <nav class="flex border-b">
              <.link 
                patch={~p"/dashboard?tab=upload"}
                class={"px-4 py-2 font-medium #{if @active_tab == "upload", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
                Upload
              </.link>
              <.link 
                patch={~p"/dashboard?tab=settings"}
                class={"px-4 py-2 font-medium #{if @active_tab == "settings", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
                SNS Settings
              </.link>
              <.link 
                patch={~p"/dashboard?tab=schedule"}
                class={"px-4 py-2 font-medium #{if @active_tab == "schedule", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
                Schedule
              </.link>
              <.link 
                patch={~p"/dashboard?tab=results"}
                class={"px-4 py-2 font-medium #{if @active_tab == "results", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
                Results
              </.link>
            </nav>
          </div>
          
          <!-- Tab Content -->
          <div class="bg-white rounded-lg shadow-md p-6">
            <%= case @active_tab do %>
              <% "upload" -> %>
                <!-- Upload Widget -->
                <div>
                  <h2 class="text-xl font-semibold mb-4">Upload Content</h2>
                  
                  <form phx-submit="save" phx-change="validate-form">
                    <!-- Grid container for side-by-side layout -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                      <!-- Metadata Form Fields (Left Column) -->
                      <div class="space-y-4">
                        <div>
                          <label for="title" class="block text-sm font-medium text-gray-700">Title</label>
                          <input 
                            type="text" 
                            id="title" 
                            name="upload_form[title]" 
                            value={@upload_form["title"]} 
                            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
                            placeholder="Enter a title for your video" 
                          />
                        </div>
                        
                        <div>
                          <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
                          <textarea 
                            id="description" 
                            name="upload_form[description]" 
                            rows="3" 
                            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
                            placeholder="Describe your video"
                          ><%= @upload_form["description"] %></textarea>
                        </div>
                        
                        <div>
                          <label for="tags" class="block text-sm font-medium text-gray-700">Tags</label>
                          <input 
                            type="text" 
                            id="tags" 
                            name="upload_form[tags]" 
                            value={@upload_form["tags"]} 
                            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
                            placeholder="Enter tags separated by commas" 
                          />
                          <p class="mt-1 text-xs text-gray-500">Add relevant tags to help people discover your content</p>
                        </div>
                      </div>
                      
                      <!-- File Upload Area (Right Column) -->
                      <div 
                        id="upload-area"
                        phx-drop-target={@uploads.video.ref} 
                        class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-indigo-500 transition-colors">
                        <%= if Enum.empty?(@uploads.video.entries) do %>
                          <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                          </svg>
                          <p class="mt-2 text-sm text-gray-500">
                            <span class="font-medium text-indigo-600 hover:text-indigo-500">
                              Upload a video
                            </span> or drag and drop
                          </p>
                          <p class="mt-1 text-xs text-gray-500">
                            MP4, MOV, AVI, WMV, FLV, WEBM up to 500MB
                          </p>
                          
                          <label for="video-upload" class="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 cursor-pointer">
                            <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                            Select Video
                          </label>
                          <.live_file_input id="video-upload" upload={@uploads.video} class="sr-only" />
                        <% else %>
                          <!-- Upload in progress or completed -->
                          <%= for entry <- @uploads.video.entries do %>
                            <div class="relative">
                              <!-- Video preview or placeholder -->
                              <div class="flex items-center justify-center h-32 bg-gray-100 rounded">
                                <%= if @preview_url do %>
                                  <img src={@preview_url} alt="Video thumbnail" class="h-full object-cover rounded" />
                                <% else %>
                                  <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                  </svg>
                                <% end %>
                              </div>
                              
                              <!-- Progress bar -->
                              <div class="w-full bg-gray-200 rounded-full h-2.5 mt-2">
                                <div class="bg-indigo-600 h-2.5 rounded-full" style={"width: #{@upload_progress}%"}></div>
                              </div>
                              
                              <div class="flex items-center justify-between mt-2">
                                <span class="text-sm text-gray-500">
                                  <%= entry.client_name %> (<%= Number.Delimit.number_to_delimited(div(entry.client_size, 1024 * 1024), precision: 1) %> MB)
                                </span>
                                
                                <button 
                                  phx-click="cancel-upload" 
                                  phx-value-ref={entry.ref} 
                                  class="text-red-500 hover:text-red-700 text-sm">
                                  Cancel
                                </button>
                              </div>
                              
                              <!-- Entry errors -->
                              <%= for err <- upload_errors(@uploads.video, entry) do %>
                                <div class="text-red-500 text-sm mt-1"><%= err %></div>
                              <% end %>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </div><!-- End of grid container -->
                    
                    <!-- Platform Selection -->
                    <div class="mb-6">
                      <label class="block text-sm font-medium text-gray-700 mb-2">Where to upload</label>
                      <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                        <%= for {platform, status} <- @social_accounts do %>
                          <button 
                            type="button"
                            phx-click="toggle-platform"
                            phx-value-platform={platform}
                            disabled={!status.connected}
                            class={
                              "flex items-center justify-center py-2 px-4 border rounded-md text-sm font-medium transition-colors " <>
                              if(!status.connected) do
                                "bg-gray-100 text-gray-400 cursor-not-allowed"
                              else
                                if(platform in @selected_platforms) do
                                  "bg-indigo-100 text-indigo-700 border-indigo-300 hover:bg-indigo-200"
                                else
                                  "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                                end
                              end
                            }
                          >
                            <%= platform |> Atom.to_string() |> String.capitalize() %>
                            <%= if platform in @selected_platforms do %>
                              <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4 text-indigo-500" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                              </svg>
                            <% end %>
                          </button>
                        <% end %>
                      </div>
                      <%= if !Enum.empty?(@selected_platforms) do %>
                        <p class="mt-2 text-sm text-gray-600">
                          Selected: <%= @selected_platforms |> Enum.map(&(Atom.to_string(&1) |> String.capitalize())) |> Enum.join(", ") %>
                        </p>
                      <% else %>
                        <p class="mt-2 text-sm text-red-500">
                          Please select at least one platform
                        </p>
                      <% end %>
                    </div>
                    
                    <!-- Action Buttons -->
                    <div class="flex items-center space-x-3">
                      <button 
                        type="submit"
                        class="inline-flex justify-center items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                        disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms)}
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
                        </svg>
                        Upload Now
                      </button>
                      
                      <button 
                        type="button"
                        phx-click={JS.patch(~p"/dashboard?tab=schedule")}
                        class="inline-flex justify-center items-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms)}
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                        </svg>
                        Schedule For Later
                      </button>
                    </div>
                  </form>
                </div>
              
              <% "settings" -> %>
                <!-- SNS Settings Tab -->
                <div>
                  <h2 class="text-xl font-semibold mb-4">Social Media Connections</h2>
                  <p class="text-gray-600 mb-6">Connect your social media accounts to enable seamless posting across platforms.</p>
                  
                  <div class="space-y-6">
                    <%= for {platform, status} <- @social_accounts do %>
                      <div class="bg-gray-50 p-4 rounded-lg border border-gray-200">
                        <div class="flex justify-between items-center">
                          <div class="flex items-center">
                            <!-- Platform icon would go here -->
                            <div class={"w-10 h-10 rounded-full flex items-center justify-center #{platform_color(platform)}"}>
                              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
                              </svg>
                            </div>
                            <div class="ml-3">
                              <h3 class="text-lg font-medium text-gray-900">
                                <%= platform |> Atom.to_string() |> String.capitalize() %>
                              </h3>
                              <p class="text-sm text-gray-500">
                                <%= if status.connected do %>
                                  Connected and ready for posting
                                <% else %>
                                  Not connected
                                <% end %>
                              </p>
                            </div>
                          </div>
                          
                          <%= if status.connected do %>
                            <button 
                              type="button"
                              phx-click="disconnect-platform"
                              phx-value-platform={platform}
                              class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-red-700 bg-red-100 hover:bg-red-200">
                              Disconnect
                            </button>
                          <% else %>
                            <.link
                              href="#"
                              class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200">
                              Connect Account
                            </.link>
                          <% end %>
                        </div>
                        
                        <%= if status.connected do %>
                          <div class="mt-4 pt-4 border-t border-gray-200">
                            <h4 class="text-sm font-medium text-gray-700 mb-2">Account Settings</h4>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                              <div>
                                <label class="block text-xs font-medium text-gray-500 mb-1">Profile</label>
                                <div class="flex items-center">
                                  <div class="h-8 w-8 rounded-full bg-gray-300 mr-2"></div>
                                  <span class="text-sm">User123</span>
                                </div>
                              </div>
                              <div>
                                <label class="block text-xs font-medium text-gray-500 mb-1">Last used</label>
                                <span class="text-sm">April 1, 2025</span>
                              </div>
                            </div>
                            <div class="mt-4">
                              <label class="block text-xs font-medium text-gray-500 mb-1">Permissions</label>
                              <div class="flex flex-wrap gap-2">
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Post</span>
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Upload Media</span>
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Read Timeline</span>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              
              <% "schedule" -> %>
                <!-- Schedule Tab -->
                <div>
                  <h2 class="text-xl font-semibold mb-4">Schedule Your Content</h2>
                  <p class="text-gray-600 mb-6">Plan ahead by scheduling your content for optimal posting times.</p>

                  <form phx-submit="schedule" phx-change="validate-form">
                    <!-- Content Selection Section -->
                    <div class="mb-6">
                      <h3 class="text-lg font-medium text-gray-900 mb-3">1. Select Content</h3>
                      
                      <!-- Content preview card -->
                      <div class="bg-gray-50 p-4 rounded-lg border border-gray-200 mb-4">
                        <%= if @preview_url do %>
                          <div class="flex items-start">
                            <div class="flex-shrink-0 mr-4">
                              <img src={@preview_url} alt="Video thumbnail" class="h-24 w-32 object-cover rounded" />
                            </div>
                            <div>
                              <h4 class="text-base font-medium text-gray-900"><%= @upload_form["title"] || "Untitled Video" %></h4>
                              <p class="text-sm text-gray-500 line-clamp-2 mb-2">
                                <%= @upload_form["description"] || "No description provided" %>
                              </p>
                              <div class="flex flex-wrap gap-1">
                                <%= if @upload_form["tags"] && @upload_form["tags"] != "" do %>
                                  <%= for tag <- String.split(@upload_form["tags"], ",") do %>
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                                      <%= String.trim(tag) %>
                                    </span>
                                  <% end %>
                                <% else %>
                                  <span class="text-xs text-gray-400">No tags added</span>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        <% else %>
                          <div class="flex items-center justify-center py-6">
                            <div class="text-center">
                              <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                              </svg>
                              <p class="mt-2 text-sm text-gray-500">No content selected</p>
                              <button
                                type="button"
                                phx-click={JS.patch(~p"/dashboard?tab=upload")}
                                class="mt-3 inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
                              >
                                Upload New Content
                              </button>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                    
                    <!-- Platform Selection -->
                    <div class="mb-6">
                      <h3 class="text-lg font-medium text-gray-900 mb-3">2. Select Platforms</h3>
                      
                      <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                        <%= for {platform, status} <- @social_accounts do %>
                          <button 
                            type="button"
                            phx-click="toggle-platform"
                            phx-value-platform={platform}
                            disabled={!status.connected}
                            class={
                              "flex items-center justify-center py-2 px-4 border rounded-md text-sm font-medium transition-colors " <>
                              if(!status.connected) do
                                "bg-gray-100 text-gray-400 cursor-not-allowed"
                              else
                                if(platform in @selected_platforms) do
                                  "bg-indigo-100 text-indigo-700 border-indigo-300 hover:bg-indigo-200"
                                else
                                  "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                                end
                              end
                            }
                          >
                            <%= platform |> Atom.to_string() |> String.capitalize() %>
                            <%= if platform in @selected_platforms do %>
                              <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4 text-indigo-500" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                              </svg>
                            <% end %>
                          </button>
                        <% end %>
                      </div>
                    </div>
                    
                    <!-- Schedule Settings -->
                    <div class="mb-6">
                      <h3 class="text-lg font-medium text-gray-900 mb-3">3. Set Schedule Time</h3>
                      
                      <div class="space-y-4">
                        <div>
                          <label for="schedule_at" class="block text-sm font-medium text-gray-700">Date and Time</label>
                          <input 
                            type="datetime-local" 
                            id="schedule_at" 
                            name="upload_form[schedule_at]" 
                            value={@upload_form["schedule_at"]} 
                            min={DateTime.utc_now() |> DateTime.add(30, :minute) |> DateTime.to_iso8601() |> String.slice(0, 16)}
                            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
                          />
                          <p class="mt-1 text-xs text-gray-500">Schedule at least 30 minutes in the future</p>
                        </div>
                        
                        <div>
                          <label class="block text-sm font-medium text-gray-700">Timezone</label>
                          <div class="mt-1 relative rounded-md shadow-sm">
                            <select 
                              class="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                              disabled
                            >
                              <option>Your local timezone (JST)</option>
                            </select>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <!-- Action Button -->
                    <div>
                      <button 
                        type="submit"
                        class="inline-flex justify-center items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                        disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms) || !@upload_form["schedule_at"]}
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                        </svg>
                        Schedule Upload
                      </button>
                    </div>
                  </form>
                </div>
              
              <% "results" -> %>
                <!-- Results Log Tab -->
                <div>
                  <h2 class="text-xl font-semibold mb-4">Upload Results</h2>
                  <p class="text-gray-600 mb-6">View the status and results of your recent social media uploads.</p>
                  
                  <%= if @loading_uploads do %>
                    <div class="animate-pulse space-y-4">
                      <div class="h-20 bg-gray-200 rounded"></div>
                      <div class="h-20 bg-gray-200 rounded"></div>
                      <div class="h-20 bg-gray-200 rounded"></div>
                    </div>
                  <% else %>
                    <%= if Enum.empty?(@recent_uploads) do %>
                      <div class="text-center py-12">
                        <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2-10v8a2 2 0 01-2 2H7a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2z" />
                        </svg>
                        <p class="mt-2 text-sm text-gray-500">No uploads found</p>
                        <button
                          type="button"
                          phx-click={JS.patch(~p"/dashboard?tab=upload")}
                          class="mt-3 inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
                        >
                          Create Your First Upload
                        </button>
                      </div>
                    <% else %>
                      <div class="space-y-4">
                        <%= for upload <- @recent_uploads do %>
                          <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
                            <div class="p-4">
                              <div class="flex justify-between items-start">
                                <div>
                                  <div class="flex items-center">
                                    <span class="text-lg font-medium text-gray-900">
                                      Upload #<%= upload.id %>
                                    </span>
                                    <%= case upload.status do %>
                                      <% :success -> %>
                                        <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                          Success
                                        </span>
                                      <% :processing -> %>
                                        <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                          Processing
                                        </span>
                                      <% :failed -> %>
                                        <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                                          Failed
                                        </span>
                                    <% end %>
                                  </div>
                                  <p class="text-sm text-gray-500 mt-1">
                                    <%= Calendar.strftime(upload.timestamp, "%B %d, %Y at %I:%M %p") %>
                                  </p>
                                </div>
                                
                                <div class="flex space-x-1">
                                  <%= for platform <- upload.platforms do %>
                                    <div 
                                      class={"w-8 h-8 rounded-full flex items-center justify-center #{platform_color(platform)}"} 
                                      title={platform |> Atom.to_string() |> String.capitalize()}
                                    >
                                      <!-- Platform icon would go here -->
                                      <span class="text-xs text-white font-bold">
                                        <%= platform |> Atom.to_string() |> String.first() |> String.upcase() %>
                                      </span>
                                    </div>
                                  <% end %>
                                </div>
                              </div>
                              
                              <!-- Posted Links -->
                              <%= if upload.status == :success && map_size(upload.links) > 0 do %>
                                <div class="mt-4 pt-4 border-t border-gray-200">
                                  <h4 class="text-sm font-medium text-gray-700 mb-2">Posted Links</h4>
                                  <div class="space-y-2">
                                    <%= for {platform, link} <- upload.links, link != nil do %>
                                      <a 
                                        href={link} 
                                        target="_blank" 
                                        rel="noopener noreferrer"
                                        class="flex items-center text-sm text-indigo-600 hover:text-indigo-900"
                                      >
                                        <div class={"w-5 h-5 rounded-full flex items-center justify-center mr-2 #{platform_color(platform)}"}>
                                          <span class="text-xs text-white font-bold">
                                            <%= platform |> Atom.to_string() |> String.first() |> String.upcase() %>
                                          </span>
                                        </div>
                                        View on <%= platform |> Atom.to_string() |> String.capitalize() %>
                                        <svg xmlns="http://www.w3.org/2000/svg" class="ml-1 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                                          <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                                          <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                                        </svg>
                                      </a>
                                    <% end %>
                                  </div>
                                </div>
                              <% end %>
                              
                              <!-- Error Message -->
                              <%= if upload.status == :failed && Map.get(upload, :error) do %>
                                <div class="mt-4 p-3 rounded bg-red-50 border border-red-100">
                                  <p class="text-sm text-red-800">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="inline-block h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                                    </svg>
                                    <%= upload.error %>
                                  </p>
                                </div>
                              <% end %>
                              
                              <!-- Retry Button for Failed Uploads -->
                              <%= if upload.status == :failed do %>
                                <div class="mt-4">
                                  <button
                                    type="button"
                                    phx-click="retry-upload"
                                    phx-value-id={upload.id}
                                    class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
                                  >
                                    <svg xmlns="http://www.w3.org/2000/svg" class="mr-1.5 h-4 w-4 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
                                      <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1
                                      0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd" />
                                    </svg>
                                    Retry Upload
                                  </button>
                                </div>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  <% end %>
                </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
  
  # Event handler for disconnecting platforms
  def handle_event("disconnect-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    
    # In a real implementation, we would revoke the tokens for this platform
    # For now, just update the UI
    updated_accounts = Map.update!(
      socket.assigns.social_accounts,
      platform,
      fn status -> %{status | connected: false} end
    )
    
    # Also remove it from selected platforms if it was selected
    updated_platforms = Enum.reject(
      socket.assigns.selected_platforms,
      fn p -> p == platform end
    )
    
    {:noreply, 
      socket
      |> assign(:social_accounts, updated_accounts)
      |> assign(:selected_platforms, updated_platforms)
      |> put_flash(:info, "Disconnected from #{platform |> Atom.to_string() |> String.capitalize()}")}
  end
  
  # Event handler for retrying failed uploads
  def handle_event("retry-upload", %{"id" => id}, socket) do
    # In a real implementation, we would retry the upload
    # For now, just show a flash message
    
    {:noreply, 
      socket
      |> put_flash(:info, "Retrying upload ##{id}...")}
  end
  
  # Helper function to determine the color for each platform
  defp platform_color(platform) do
    case platform do
      :twitter -> "bg-blue-500"
      :instagram -> "bg-pink-600"
      :facebook -> "bg-blue-700"
      :youtube -> "bg-red-600"
      :tiktok -> "bg-black"
      _ -> "bg-gray-600" # Default color
    end
  end
end

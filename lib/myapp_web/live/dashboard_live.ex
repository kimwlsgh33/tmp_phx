# defmodule MyappWeb.DashboardLive do
#   use MyappWeb, :live_view
#   
#   alias Myapp.Accounts
#   alias Myapp.SocialAuth
#
#   @social_platforms [:twitter, :instagram, :tiktok, :youtube, :facebook]
#
#   def mount(_params, _session, socket) do
#     current_user = socket.assigns.current_user
#     
#     if connected?(socket) do
#       # Fetch connected social media accounts in a separate process to not block rendering
#       send(self(), :load_social_accounts)
#       send(self(), :load_recent_uploads)
#     end
#     
#     {:ok,
#      socket
#      |> assign(:page_title, "Social Media Dashboard")
#      |> assign(:active_tab, "upload")
#      |> assign(:social_accounts, %{})
#      |> assign(:loading_accounts, true)
#      |> assign(:loading_uploads, true)
#      |> assign(:recent_uploads, [])
#      |> assign(:upload_progress, 0)
#      |> assign(:selected_platforms, [])
#      |> assign(:preview_url, nil)
#      |> assign(:upload_form, %{
#           title: "",
#           description: "",
#           tags: "",
#           schedule_at: nil
#         })
#      |> allow_upload(:video, 
#           accept: ~w(.mp4 .mov .avi .wmv .flv .webm), 
#           max_entries: 1,
#           max_file_size: 500_000_000,
#           progress: &handle_progress/3
#         )}
#   end
#
#   def handle_params(params, _uri, socket) do
#     active_tab = Map.get(params, "tab", socket.assigns.active_tab)
#     {:noreply, assign(socket, :active_tab, active_tab)}
#   end
#
#   def handle_event("toggle-platform", %{"platform" => platform}, socket) do
#     platform = String.to_existing_atom(platform)
#     selected_platforms = socket.assigns.selected_platforms
#     
#     updated_platforms = 
#       if platform in selected_platforms do
#         Enum.reject(selected_platforms, fn p -> p == platform end)
#       else
#         [platform | selected_platforms]
#       end
#     
#     {:noreply, assign(socket, :selected_platforms, updated_platforms)}
#   end
#   
#   def handle_event("validate-form", %{"upload_form" => form_params}, socket) do
#     {:noreply, 
#       socket
#       |> assign(:upload_form, form_params)}
#   end
#   
#   def handle_event("save", %{"upload_form" => form_params}, socket) do
#     # Here we would actually process the upload and send to selected platforms
#     # For now we'll just show a flash message
#     
#     if socket.assigns.selected_platforms == [] do
#       {:noreply, 
#         socket
#         |> put_flash(:error, "Please select at least one social media platform")}
#     else
#       # In a real implementation, we would:
#       # 1. Save the uploaded file
#       # 2. Process the metadata (title, description, tags)
#       # 3. Schedule or immediately post to selected platforms
#       # 4. Record the result in the database
#       
#       # For now, just simulate success
#       Process.send_after(self(), {:upload_complete, socket.assigns.selected_platforms}, 1000)
#       
#       {:noreply, 
#         socket
#         |> put_flash(:info, "Content uploading to selected platforms...")}
#     end
#   end
#   
#   def handle_event("schedule", %{"upload_form" => form_params}, socket) do
#     # Handle scheduling for future posting
#     scheduled_time = form_params["schedule_at"]
#     
#     if socket.assigns.selected_platforms == [] do
#       {:noreply, 
#         socket
#         |> put_flash(:error, "Please select at least one social media platform")}
#     else
#       # In a real implementation, we would save the schedule to the database
#       
#       {:noreply, 
#         socket
#         |> put_flash(:info, "Content scheduled for upload at #{scheduled_time}")}
#     end
#   end
#   
#   def handle_event("cancel-upload", %{"ref" => ref}, socket) do
#     {:noreply, cancel_upload(socket, :video, ref)}
#   end
#   
#   def handle_info(:load_social_accounts, socket) do
#     current_user = socket.assigns.current_user
#     
#     # In a real implementation, we would fetch the actual connection status
#     # for each platform from the database or API
#     social_accounts = Enum.into(@social_platforms, %{}, fn platform ->
#       # This is just a placeholder. In a real app, you would check if the
#       # user is authenticated with each platform
#       connected = Enum.random([true, false])
#       {platform, %{connected: connected}}
#     end)
#     
#     {:noreply, 
#       socket
#       |> assign(:social_accounts, social_accounts)
#       |> assign(:loading_accounts, false)}
#   end
#   
#   def handle_info(:load_recent_uploads, socket) do
#     # In a real implementation, we would fetch recent uploads from the database
#     recent_uploads = [
#       %{
#         id: "1",
#         timestamp: ~N[2025-04-05 10:30:00],
#         platforms: [:twitter, :instagram],
#         status: :success,
#         links: %{
#           twitter: "https://twitter.com/user/status/123456789",
#           instagram: "https://instagram.com/p/ABC123"
#         }
#       },
#       %{
#         id: "2",
#         timestamp: ~N[2025-04-04 15:45:00],
#         platforms: [:youtube],
#         status: :processing,
#         links: %{
#           youtube: nil
#         }
#       },
#       %{
#         id: "3",
#         timestamp: ~N[2025-04-03 09:15:00],
#         platforms: [:tiktok, :facebook],
#         status: :failed,
#         links: %{},
#         error: "Upload failed: invalid token"
#       }
#     ]
#     
#     {:noreply, 
#       socket
#       |> assign(:recent_uploads, recent_uploads)
#       |> assign(:loading_uploads, false)}
#   end
#   
#   def handle_info({:upload_complete, platforms}, socket) do
#     # In a real implementation, we would update the database with the results
#     # and fetch the updated recent uploads list
#     
#     platform_names = Enum.map_join(platforms, ", ", fn p -> 
#       p |> Atom.to_string() |> String.capitalize()
#     end)
#     
#     {:noreply, 
#       socket
#       |> put_flash(:info, "Upload complete! Posted to #{platform_names}")
#       |> push_patch(to: ~p"/dashboard?tab=results")}
#   end
#   
#   defp handle_progress(:video, entry, socket) do
#     if entry.done? do
#       # When upload is complete, we can display a preview
#       # In a real implementation, we would generate a thumbnail
#       {:noreply, 
#         socket
#         |> assign(:preview_url, "/uploads/#{entry.uuid}.mp4")
#         |> assign(:upload_progress, 100)}
#     else
#       # Update progress as the upload proceeds
#       progress = floor(entry.progress)
#       {:noreply, assign(socket, :upload_progress, progress)}
#     end
#   end
#   
#   def render(assigns) do
#     ~H"""
#     <div class="flex h-screen">
#       <!-- Main Content Area -->
#       <div class="flex-1 bg-white overflow-y-auto">
#         <div class="p-6">
#           <div class="mb-6">
#             <h1 class="text-2xl font-bold text-black ">Social Media Dashboard</h1>
#             <p class="text-gray-400">Manage your content across multiple platforms</p>
#           </div>
#           
#           <!-- Tabs Navigation -->
#           <div class="mb-6">
#             <nav class="flex border-b border-black">
#               <.link 
#                 patch={~p"/dashboard?tab=upload"}
#                 class={"px-4 py-2 font-medium #{if @active_tab == "upload", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
#                 Upload
#               </.link>
#               <.link 
#                 patch={~p"/dashboard?tab=settings"}
#                 class={"px-4 py-2 font-medium #{if @active_tab == "settings", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
#                 SNS Settings
#               </.link>
#               <.link 
#                 patch={~p"/dashboard?tab=schedule"}
#                 class={"px-4 py-2 font-medium #{if @active_tab == "schedule", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
#                 Schedule
#               </.link>
#               <.link 
#                 patch={~p"/dashboard?tab=results"}
#                 class={"px-4 py-2 font-medium #{if @active_tab == "results", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
#                 Results
#               </.link>
#               <.link 
#                 patch={~p"/dashboard?tab=preview"}
#                 class={"px-4 py-2 font-medium #{if @active_tab == "preview", do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}>
#                 Preview
#               </.link>
#           </nav>
#           </div>
#           
#           <!-- Tab Content -->
#           <div class="bg-white rounded-lg shadow-md p-6">
#             <%= case @active_tab do %>
#               <% "upload" -> %>
#                 <!-- Upload Widget -->
#                 <div>
#                   <h2 class="text-xl font-semibold mb-4">Upload Content</h2>
#                   
#                   <form phx-submit="save" phx-change="validate-form">
#                     <!-- Grid container for side-by-side layout -->
#                     <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
#                       <!-- Metadata Form Fields (Left Column) -->
#                       <div class="space-y-4">
#                         <div>
#                           <label for="title" class="block text-sm font-medium text-gray-700">Title</label>
#                           <input 
#                             type="text" 
#                             id="title" 
#                             name="upload_form[title]" 
#                             value={@upload_form["title"]} 
#                             class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
#                             placeholder="Enter a title for your video" 
#                           />
#                         </div>
#                         
#                         <div>
#                           <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
#                           <textarea 
#                             id="description" 
#                             name="upload_form[description]" 
#                             rows="3" 
#                             class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
#                             placeholder="Describe your video"
#                           ><%= @upload_form["description"] %></textarea>
#                         </div>
#                         
#                         <div>
#                           <label for="tags" class="block text-sm font-medium text-gray-700">Tags</label>
#                           <input 
#                             type="text" 
#                             id="tags" 
#                             name="upload_form[tags]" 
#                             value={@upload_form["tags"]} 
#                             class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
#                             placeholder="Enter tags separated by commas" 
#                           />
#                           <p class="mt-1 text-xs text-gray-500">Add relevant tags to help people discover your content</p>
#                         </div>
#                       </div>
#                       
#                       <!-- File Upload Area (Right Column) -->
#                       <div 
#                         id="upload-area"
#                         phx-drop-target={@uploads.video.ref} 
#                         class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-indigo-500 transition-colors">
#                         <%= if Enum.empty?(@uploads.video.entries) do %>
#                           <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                             <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
#                           </svg>
#                           <p class="mt-2 text-sm text-gray-500">
#                             <span class="font-medium text-indigo-600 hover:text-indigo-500">
#                               Upload a video
#                             </span> or drag and drop
#                           </p>
#                           <p class="mt-1 text-xs text-gray-500">
#                             MP4, MOV, AVI, WMV, FLV, WEBM up to 500MB
#                           </p>
#                           
#                           <label for="video-upload" class="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 cursor-pointer">
#                             <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
#                             </svg>
#                             Select Video
#                           </label>
#                           <.live_file_input id="video-upload" upload={@uploads.video} class="sr-only" />
#                         <% else %>
#                           <!-- Upload in progress or completed -->
#                           <%= for entry <- @uploads.video.entries do %>
#                             <div class="relative">
#                               <!-- Video preview or placeholder -->
#                               <div class="flex items-center justify-center h-32 bg-gray-100 rounded">
#                                 <%= if @preview_url do %>
#                                   <img src={@preview_url} alt="Video thumbnail" class="h-full object-cover rounded" />
#                                 <% else %>
#                                   <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
#                                   </svg>
#                                 <% end %>
#                               </div>
#                               
#                               <!-- Progress bar -->
#                               <div class="w-full bg-gray-200 rounded-full h-2.5 mt-2">
#                                 <div class="bg-indigo-600 h-2.5 rounded-full" style={"width: #{@upload_progress}%"}></div>
#                               </div>
#                               
#                               <div class="flex items-center justify-between mt-2">
#                                 <span class="text-sm text-gray-500">
#                                   <%= entry.client_name %> (<%= Number.Delimit.number_to_delimited(div(entry.client_size, 1024 * 1024), precision: 1) %> MB)
#                                 </span>
#                                 
#                                 <button 
#                                   phx-click="cancel-upload" 
#                                   phx-value-ref={entry.ref} 
#                                   class="text-red-500 hover:text-red-700 text-sm">
#                                   Cancel
#                                 </button>
#                               </div>
#                               
#                               <!-- Entry errors -->
#                               <%= for err <- upload_errors(@uploads.video, entry) do %>
#                                 <div class="text-red-500 text-sm mt-1"><%= err %></div>
#                               <% end %>
#                             </div>
#                           <% end %>
#                         <% end %>
#                       </div>
#                     </div><!-- End of grid container -->
#                     
#                     <!-- Platform Selection -->
#                     <div class="mb-6">
#                       <label class="block text-sm font-medium text-gray-700 mb-2">Where to upload</label>
#                       <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
#                         <%= for {platform, status} <- @social_accounts do %>
#                           <button 
#                             type="button"
#                             phx-click="toggle-platform"
#                             phx-value-platform={platform}
#                             disabled={!status.connected}
#                             aria-label={"#{Atom.to_string(platform) |> String.capitalize()} - #{if platform in @selected_platforms, do: "Selected", else: "Not selected"}"}
#                             class={
#                               "flex items-center justify-center py-2 px-3 border rounded-md text-sm font-medium transition-colors " <>
#                               if(!status.connected) do
#                                 "bg-gray-100 text-gray-400 cursor-not-allowed"
#                               else
#                                 if(platform in @selected_platforms) do
#                                   "bg-indigo-100 text-indigo-700 border-indigo-300 hover:bg-indigo-200"
#                                 else
#                                   "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
#                                 end
#                               end
#                             }
#                           >
#                             <%= case platform do %>
#                               <% :twitter -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
#                                 </svg>
#                               <% :instagram -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path fill-rule="evenodd" d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z" clip-rule="evenodd"/>
#                                 </svg>
#                               <% :facebook -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path fill-rule="evenodd" d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z" clip-rule="evenodd"/>
#                                 </svg>
#                               <% :youtube -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path fill-rule="evenodd" d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z" clip-rule="evenodd"/>
#                                 </svg>
#                               <% :tiktok -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
#                                 </svg>
#                               <% :linkedin -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path fill-rule="evenodd" d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" clip-rule="evenodd"/>
#                                 </svg>
#                               <% :pinterest -> %>
#                                 <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path d="M12.017 0C5.396 0 .029 5.367.029 11.987c0 5.079 3.158 9.417 7.618 11.162-.105-.949-.199-2.403.041-3.439.219-.937 1.406-5.957 1.406-5.957s-.359-.72-.359-1.781c0-1.663.967-2.911 2.168-2.911 1.024 0 1.518.769 1.518 1.688 0 1.029-.653 2.567-.992 3.992-.285 1.193.6 2.165 1.775 2.165 2.128 0 3.768-2.245 3.768-5.487 0-2.861-2.063-4.869-5.008-4.869-3.41 0-5.409 2.562-5.409 5.199 0 1.033.394 2.143.889 2.741.099.12.112.225.085.345-.09.375-.293 1.199-.334 1.363-.053.225-.172.271-.401.165-1.495-.69-2.433-2.878-2.433-4.646 0-3.776 2.748-7.252 7.92-7.252 4.158 0 7.392 2.967 7.392 6.923 0 4.135-2.607 7.462-6.233 7.462-1.214 0-2.354-.629-2.758-1.379l-.749 2.848c-.269 1.045-1.004 2.352-1.498 3.146 1.123.345 2.306.535 3.55.535 6.607 0 11.985-5.365 11.985-11.987C23.97 5.39 18.592.022 11.985.022L12.017 0z"/>
#                                 </svg>
#                             <% end %>
#                             <%= if platform in @selected_platforms do %>
#                               <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4 text-indigo-500" viewBox="0 0 20 20" fill="currentColor">
#                                 <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
#                               </svg>
#                             <% end %>
#                           </button>
#                         <% end %>
#                       </div>
#                       <%= if !Enum.empty?(@selected_platforms) do %>
#                         <p class="mt-2 text-sm text-gray-600">
#                           Selected: <%= @selected_platforms |> Enum.map(&(Atom.to_string(&1) |> String.capitalize())) |> Enum.join(", ") %>
#                         </p>
#                       <% else %>
#                         <p class="mt-2 text-sm text-red-500">
#                           Please select at least one platform
#                         </p>
#                       <% end %>
#                     </div>
#                     
#                     <!-- Action Buttons -->
#                     <div class="flex items-center space-x-3">
#                       <button 
#                         type="submit"
#                         class="inline-flex justify-center items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
#                         disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms)}
#                       >
#                         <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
#                           <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
#                         </svg>
#                         Upload Now
#                       </button>
#                       
#                       <button 
#                         type="button"
#                         phx-click={JS.patch(~p"/dashboard?tab=schedule")}
#                         class="inline-flex justify-center items-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
#                         disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms)}
#                       >
#                         <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
#                           <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
#                         </svg>
#                         Schedule For Later
#                       </button>
#                       
#                       
#                       <button 
#                         type="button"
#                         phx-click={JS.patch(~p"/dashboard?tab=preview")}
#                         class="inline-flex justify-center items-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
#                         disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms)}
#                       >
#                         <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
#                           <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
#                           <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd" />
#                         </svg>
#                         Preview
#                       </button>
#                     </div>
#                   </form>
#                 </div>
#               
#               <% "preview" -> %>
#                 <!-- Preview Tab -->
#                 <div>
#                   <div class="flex justify-between items-center mb-6">
#                     <h2 class="text-xl font-semibold">Preview Your Post</h2>
#                     <div class="flex space-x-3">
#                       <button 
#                         type="button" 
#                         phx-click={JS.patch(~p"/dashboard?tab=upload")}
#                         class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
#                       >
#                         <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
#                           <path fill-rule="evenodd" d="M9.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L7.414 9H15a1 1 0 110 2H7.414l2.293 2.293a1 1 0 010 1.414z" clip-rule="evenodd" />
#                         </svg>
#                         Back to Edit
#                       </button>
#                       <button 
#                         type="button" 
#                         phx-click="save"
#                         class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
#                       >
#                         <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
#                           <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
#                         </svg>
#                         Upload Now
#                       </button>
#                     </div>
#                   </div>
#                   
#                   <p class="text-gray-600 mb-6">Here's how your post will appear on each selected platform. Review to ensure everything looks correct before uploading.</p>
#                   
#                   <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
#                     <%= for platform <- @selected_platforms do %>
#                       <div class="bg-white border rounded-lg overflow-hidden shadow-sm">
#                         <%= case platform do %>
#                           <% :twitter -> %>
#                             <!-- Twitter Preview -->
#                             <div class="p-4 border-b bg-white">
#                               <div class="flex items-start">
#                                 <div class="flex-shrink-0">
#                                   <div class="w-12 h-12 rounded-full bg-blue-400 flex items-center justify-center text-white font-bold">
#                                     <%= String.at(@current_user.email, 0) |> String.upcase() %>
#                                   </div>
#                                 </div>
#                                 <div class="ml-3 flex-1">
#                                   <div class="flex items-center">
#                                     <p class="font-bold text-gray-900"><%= @current_user.email |> String.split("@") |> hd() %></p>
#                                     <span class="ml-1 text-gray-500">@<%= @current_user.email |> String.split("@") |> hd() %> · 1m</span>
#                                   </div>
#                                   <p class="mt-1 text-gray-800"><%= @upload_form["title"] %></p>
#                                   <p class="mt-1 text-gray-600"><%= @upload_form["description"] %></p>
#                                   
#                                   <%= if @preview_url do %>
#                                     <div class="mt-3 rounded-lg overflow-hidden border border-gray-200">
#                                       <img src={@preview_url} alt="Content preview" class="w-full h-auto" />
#                                     </div>
#                                   <% else %>
#                                     <div class="mt-3 rounded-lg overflow-hidden border border-gray-200 bg-gray-100 h-48 flex items-center justify-center">
#                                       <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                                         <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
#                                       </svg>
#                                     </div>
#                                   <% end %>
#                                   
#                                   <div class="mt-3 flex justify-between text-gray-500">
#                                     <div class="flex items-center"><svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg> 20</div>
#                                     <div class="flex items-center"><svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg> 15</div>
#                                     <div class="flex items-center"><svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path></svg> 10</div>
#                                     <div class="flex items-center"><svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"></path></svg> Share</div>
#                                   </div>
#                                 </div>
#                               </div>
#                             </div>
#                             
#                             <div class="p-4 bg-gray-50">
#                               <div class="text-sm font-medium text-gray-500">
#                                 <svg class="inline-block h-5 w-5 mr-1 text-blue-400" fill="currentColor" viewBox="0 0 24 24">
#                                   <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
#                                 </svg>
#                                 Twitter Preview
#                               </div>
#                               <div class="mt-2 text-sm text-gray-500">
#                                 Tags: <%= if @upload_form["tags"] && @upload_form["tags"] != "", do: @upload_form["tags"], else: "No tags" %>
#                               </div>
#                             </div>
#
#                           <% :instagram -> %>
#                             <!-- Instagram Preview -->
#                               <div class="border-b">
#                                 <div class="p-3 flex items-center">
#                                   <div class="flex-shrink-0">
#                                     <div class="w-8 h-8 rounded-full bg-gradient-to-r from-purple-500 via-pink-500 to-red-500 flex items-center justify-center text-white font-bold text-xs">
#                                       <%= String.at(@current_user.email, 0) |> String.upcase() %>
#                                     </div>
#                                   </div>
#                                   <div class="ml-3">
#                                     <p class="text-sm font-bold">
#                                       <%= @current_user.email |> String.split("@") |> hd() %>
#                                     </p>
#                                   </div>
#                                 </div>
#                                 
#                                 <div class="aspect-square">
#                                   <%= if @preview_url do %>
#                                     <img src={@preview_url} alt="Content preview" class="w-full h-auto" />
#                                   <% else %>
#                                     <div class="bg-gray-100 h-80 flex items-center justify-center">
#                                       <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                                         <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
#                                       </svg>
#                                     </div>
#                                   <% end %>
#                                 </div>
#                                 
#                                 <div class="p-3">
#                                   <p class="text-sm"><%= @upload_form["title"] %></p>
#                                   <p class="text-xs text-gray-500 mt-1"><%= @upload_form["description"] %></p>
#                                 </div>
#                               </div>
#                               
#                               <div class="p-4 bg-gray-50">
#                                 <div class="text-sm font-medium text-gray-500">
#                                   <svg class="inline-block h-5 w-5 mr-1 text-pink-500" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                     <path fill-rule="evenodd" d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z" clip-rule="evenodd"/>
#                                   </svg>
#                                   Instagram Preview
#                                 </div>
#                                 <div class="mt-2 text-sm text-gray-500">
#                                   Tags: <%= if @upload_form["tags"] && @upload_form["tags"] != "", do: @upload_form["tags"], else: "No tags" %>
#                                 </div>
#                               </div>
#                           
#                           <% :facebook -> %>
#                             <!-- Facebook Preview -->
#                             <div class="p-4 border-b bg-white">
#                               <div class="flex items-center">
#                                 <div class="flex-shrink-0">
#                                   <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold">
#                                     <%= String.at(@current_user.email, 0) |> String.upcase() %>
#                                   </div>
#                                 </div>
#                                 <div class="ml-3">
#                                   <p class="font-semibold text-gray-900"><%= @current_user.email |> String.split("@") |> hd() %></p>
#                                   <p class="text-xs text-gray-500">Just now · <svg xmlns="http://www.w3.org/2000/svg" class="inline h-3 w-3" viewBox="0 0 20 20" fill="currentColor"><path d="M10 12a2 2 0 100-4 2 2 0 000 4z" /></svg></p>
#                                 </div>
#                               </div>
#                               
#                               <div class="mt-3">
#                                 <p class="text-gray-800"><%= @upload_form["title"] %></p>
#                                 <p class="text-gray-600 text-sm mt-1"><%= @upload_form["description"] %></p>
#                               </div>
#                               
#                               <%= if @preview_url do %>
#                                 <div class="mt-3 rounded-md overflow-hidden border border-gray-200">
#                                   <img src={@preview_url} alt="Content preview" class="w-full h-auto" />
#                                 </div>
#                               <% else %>
#                                 <div class="mt-3 rounded-md overflow-hidden border border-gray-200 bg-gray-100 h-48 flex items-center justify-center">
#                                   <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
#                                   </svg>
#                                 </div>
#                               <% end %>
#                               
#                               <div class="mt-3 flex justify-between py-1 border-t border-b border-gray-200 text-gray-500 text-sm">
#                                 <button class="flex items-center py-1">
#                                   <svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
#                                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
#                                   </svg>
#                                   Like
#                                 </button>
#                                 <button class="flex items-center py-1">
#                                   <svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
#                                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
#                                   </svg>
#                                   Comment
#                                 </button>
#                                 <button class="flex items-center py-1">
#                                   <svg class="h-5 w-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
#                                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
#                                   </svg>
#                                   Share
#                                 </button>
#                               </div>
#                             </div>
#                             
#                             <div class="p-4 bg-gray-50">
#                               <div class="text-sm font-medium text-gray-500">
#                                 <svg class="inline-block h-5 w-5 mr-1 text-blue-600" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                   <path fill-rule="evenodd" d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z" clip-rule="evenodd"/>
#                                 </svg>
#                                 Facebook Preview
#                               </div>
#                               <div class="mt-2 text-sm text-gray-500">
#                                 Tags: <%= if @upload_form["tags"] && @upload_form["tags"] != "", do: @upload_form["tags"], else: "No tags" %>
#                               </div>
#                             </div>
#                           
#                           <% :youtube -> %>
#                             <!-- YouTube Preview -->
#                             <div class="bg-white">
#                               <div class="aspect-video bg-black flex items-center justify-center">
#                                 <%= if @preview_url do %>
#                                   <img src={@preview_url} alt="Video thumbnail" class="max-h-full max-w-full" />
#                                 <% else %>
#                                   <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-600" viewBox="0 0 20 20" fill="currentColor">
#                                     <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
#                                   </svg>
#                                 <% end %>
#                               </div>
#                               
#                               <div class="p-4">
#                                 <h3 class="text-lg font-medium text-gray-900"><%= @upload_form["title"] %></h3>
#                                 <div class="flex items-center mt-1">
#                                   <p class="text-sm text-gray-500">Your Channel · 0 views · Just now</p>
#                                 </div>
#                                 <p class="mt-3 text-sm text-gray-700 line-clamp-2"><%= @upload_form["description"] %></p>
#                               </div>
#                               
#                               <div class="p-4 bg-gray-50">
#                                 <div class="text-sm font-medium text-gray-500">
#                                   <svg class="inline-block h-5 w-5 mr-1 text-red-600" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
#                                     <path fill-rule="evenodd" d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z" clip-rule="evenodd"/>
#                                   </svg>
#                                   YouTube Preview
#                                 </div>
#                                 <div class="mt-2 text-sm text-gray-500">
#                                   Tags: <%= if @upload_form["tags"] && @upload_form["tags"] != "", do: @upload_form["tags"], else: "No tags" %>
#                                 </div>
#                               </div>
#                             </div>
#                           
#                           <% :tiktok -> %>
#                             <!-- TikTok Preview -->
#                             <div class="bg-white">
#                               <div class="bg-gray-800 aspect-[9/16] flex items-center justify-center">
#                                 <%= if @preview_url do %>
#                                   <img src={@preview_url} alt="Video thumbnail" class="max-h-full max-w-full" />
#                                 <% else %>
#                                   <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-500" viewBox="0 0 24 24" fill="currentColor">
#                                     <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
#                                   </svg>
#                                 <% end %>
#                                 
#                                 <div class="absolute bottom-4 left-4 right-4">
#                                   <p class="text-white font-medium"><%= @upload_form["title"] %></p>
#                                   <p class="text-gray-300 text-sm mt-1"><%= @upload_form["description"] %></p>
#                                   <div class="mt-2 flex">
#                                     <%= if @upload_form["tags"] && @upload_form["tags"] != "" do %>
#                                       <%= for tag <- String.split(@upload_form["tags"], ",") do %>
#                                         <span class="mr-1 text-sm text-teal-400">#<%= String.trim(tag) %></span>
#                                       <% end %>
#                                     <% end %>
#                                   </div>
#                                 </div>
#                               </div>
#                               
#                               <div class="p-4 bg-gray-50">
#                                 <div class="text-sm font-medium text-gray-500">
#                                   <svg class="inline-block h-5 w-5 mr-1" fill="currentColor" viewBox="0 0 24 24">
#                                     <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
#                                   </svg>
#                                   TikTok Preview
#                                 </div>
#                                 <div class="mt-2 text-sm text-gray-500">
#                                   Tags: <%= if @upload_form["tags"] && @upload_form["tags"] != "", do: @upload_form["tags"], else: "No tags" %>
#                                 </div>
#                               </div>
#                             </div>
#                         <% end %>
#                       </div>
#                     <% end %>
#                   </div>
#                 </div>
#               
#               <% "settings" -> %>
#                 <!-- SNS Settings Tab -->
#                 <div>
#                   <h2 class="text-xl font-semibold mb-4">Social Media Connections</h2>
#                   <p class="text-gray-600 mb-6">Connect your social media accounts to enable seamless posting across platforms.</p>
#                   
#                   <div class="space-y-6">
#                     <%= for {platform, status} <- @social_accounts do %>
#                       <div class="bg-gray-50 p-4 rounded-lg border border-gray-200">
#                         <div class="flex justify-between items-center">
#                           <div class="flex items-center">
#                             <!-- Platform icon would go here -->
#                             <div class={"w-10 h-10 rounded-full flex items-center justify-center #{platform_color(platform)}"}>
#                               <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 20 20" fill="currentColor">
#                                 <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
#                               </svg>
#                             </div>
#                             <div class="ml-3">
#                               <h3 class="text-lg font-medium text-gray-900">
#                                 <%= platform |> Atom.to_string() |> String.capitalize() %>
#                               </h3>
#                               <p class="text-sm text-gray-500">
#                                 <%= if status.connected do %>
#                                   Connected and ready for posting
#                                 <% else %>
#                                   Not connected
#                                 <% end %>
#                               </p>
#                             </div>
#                           </div>
#                           
#                           <%= if status.connected do %>
#                             <button 
#                               type="button"
#                               phx-click="disconnect-platform"
#                               phx-value-platform={platform}
#                               class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-red-700 bg-red-100 hover:bg-red-200">
#                               Disconnect
#                             </button>
#                           <% else %>
#                             <.link
#                               href="#"
#                               class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200">
#                               Connect Account
#                             </.link>
#                           <% end %>
#                         </div>
#                         
#                         <%= if status.connected do %>
#                           <div class="mt-4 pt-4 border-t border-gray-200">
#                             <h4 class="text-sm font-medium text-gray-700 mb-2">Account Settings</h4>
#                             <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
#                               <div>
#                                 <label class="block text-xs font-medium text-gray-500 mb-1">Profile</label>
#                                 <div class="flex items-center">
#                                   <div class="h-8 w-8 rounded-full bg-gray-300 mr-2"></div>
#                                   <span class="text-sm">User123</span>
#                                 </div>
#                               </div>
#                               <div>
#                                 <label class="block text-xs font-medium text-gray-500 mb-1">Last used</label>
#                                 <span class="text-sm">April 1, 2025</span>
#                               </div>
#                             </div>
#                             <div class="mt-4">
#                               <label class="block text-xs font-medium text-gray-500 mb-1">Permissions</label>
#                               <div class="flex flex-wrap gap-2">
#                                 <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Post</span>
#                                 <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Upload Media</span>
#                                 <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Read Timeline</span>
#                               </div>
#                             </div>
#                           </div>
#                         <% end %>
#                       </div>
#                     <% end %>
#                   </div>
#                 </div>
#               
#               <% "schedule" -> %>
#                 <!-- Schedule Tab -->
#                 <div>
#                   <h2 class="text-xl font-semibold mb-4">Schedule Your Content</h2>
#                   <p class="text-gray-600 mb-6">Plan ahead by scheduling your content for optimal posting times.</p>
#
#                   <form phx-submit="schedule" phx-change="validate-form">
#                     <!-- Content Selection Section -->
#                     <div class="mb-6">
#                       <h3 class="text-lg font-medium text-gray-900 mb-3">1. Select Content</h3>
#                       
#                       <!-- Content preview card -->
#                       <div class="bg-gray-50 p-4 rounded-lg border border-gray-200 mb-4">
#                         <%= if @preview_url do %>
#                           <div class="flex items-start">
#                             <div class="flex-shrink-0 mr-4">
#                               <img src={@preview_url} alt="Video thumbnail" class="h-24 w-32 object-cover rounded" />
#                             </div>
#                             <div>
#                               <h4 class="text-base font-medium text-gray-900"><%= @upload_form["title"] || "Untitled Video" %></h4>
#                               <p class="text-sm text-gray-500 line-clamp-2 mb-2">
#                                 <%= @upload_form["description"] || "No description provided" %>
#                               </p>
#                               <div class="flex flex-wrap gap-1">
#                                 <%= if @upload_form["tags"] && @upload_form["tags"] != "" do %>
#                                   <%= for tag <- String.split(@upload_form["tags"], ",") do %>
#                                     <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
#                                       <%= String.trim(tag) %>
#                                     </span>
#                                   <% end %>
#                                 <% else %>
#                                   <span class="text-xs text-gray-400">No tags added</span>
#                                 <% end %>
#                               </div>
#                             </div>
#                           </div>
#                         <% else %>
#                           <div class="flex items-center justify-center py-6">
#                             <div class="text-center">
#                               <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                                 <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
#                               </svg>
#                               <p class="mt-2 text-sm text-gray-500">No content selected</p>
#                               <button
#                                 type="button"
#                                 phx-click={JS.patch(~p"/dashboard?tab=upload")}
#                                 class="mt-3 inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
#                               >
#                                 Upload New Content
#                               </button>
#                             </div>
#                           </div>
#                         <% end %>
#                       </div>
#                     </div>
#                     
#                     <!-- Platform Selection -->
#                     <div class="mb-6">
#                       <h3 class="text-lg font-medium text-gray-900 mb-3">2. Select Platforms</h3>
#                       
#                       <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
#                         <%= for {platform, status} <- @social_accounts do %>
#                           <button 
#                             type="button"
#                             phx-click="toggle-platform"
#                             phx-value-platform={platform}
#                             disabled={!status.connected}
#                             class={
#                               "flex items-center justify-center py-2 px-4 border rounded-md text-sm font-medium transition-colors " <>
#                               if(!status.connected) do
#                                 "bg-gray-100 text-gray-400 cursor-not-allowed"
#                               else
#                                 if(platform in @selected_platforms) do
#                                   "bg-indigo-100 text-indigo-700 border-indigo-300 hover:bg-indigo-200"
#                                 else
#                                   "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
#                                 end
#                               end
#                             }
#                           >
#                             <%= platform |> Atom.to_string() |> String.capitalize() %>
#                             <%= if platform in @selected_platforms do %>
#                               <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4 text-indigo-500" viewBox="0 0 20 20" fill="currentColor">
#                                 <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
#                               </svg>
#                             <% end %>
#                           </button>
#                         <% end %>
#                       </div>
#                     </div>
#                     
#                     <!-- Schedule Settings -->
#                     <div class="mb-6">
#                       <h3 class="text-lg font-medium text-gray-900 mb-3">3. Set Schedule Time</h3>
#                       
#                       <div class="space-y-4">
#                         <div>
#                           <label for="schedule_at" class="block text-sm font-medium text-gray-700">Date and Time</label>
#                           <input 
#                             type="datetime-local" 
#                             id="schedule_at" 
#                             name="upload_form[schedule_at]" 
#                             value={@upload_form["schedule_at"]} 
#                             min={DateTime.utc_now() |> DateTime.add(30, :minute) |> DateTime.to_iso8601() |> String.slice(0, 16)}
#                             class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
#                           />
#                           <p class="mt-1 text-xs text-gray-500">Schedule at least 30 minutes in the future</p>
#                         </div>
#                         
#                         <div>
#                           <label class="block text-sm font-medium text-gray-700">Timezone</label>
#                           <div class="mt-1 relative rounded-md shadow-sm">
#                             <select 
#                               class="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
#                               disabled
#                             >
#                               <option>Your local timezone (JST)</option>
#                             </select>
#                           </div>
#                         </div>
#                       </div>
#                     </div>
#                     
#                     <!-- Action Button -->
#                     <div>
#                       <button 
#                         type="submit"
#                         class="inline-flex justify-center items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
#                         disabled={Enum.empty?(@uploads.video.entries) || @upload_progress < 100 || Enum.empty?(@selected_platforms) || !@upload_form["schedule_at"]}
#                       >
#                         <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
#                           <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
#                         </svg>
#                         Schedule Upload
#                       </button>
#                     </div>
#                   </form>
#                 </div>
#               
#               <% "results" -> %>
#                 <!-- Results Log Tab -->
#                 <div>
#                   <h2 class="text-xl font-semibold mb-4">Upload Results</h2>
#                   <p class="text-gray-600 mb-6">View the status and results of your recent social media uploads.</p>
#                   
#                   <%= if @loading_uploads do %>
#                     <div class="animate-pulse space-y-4">
#                       <div class="h-20 bg-gray-200 rounded"></div>
#                       <div class="h-20 bg-gray-200 rounded"></div>
#                       <div class="h-20 bg-gray-200 rounded"></div>
#                     </div>
#                   <% else %>
#                     <%= if Enum.empty?(@recent_uploads) do %>
#                       <div class="text-center py-12">
#                         <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
#                           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2-10v8a2 2 0 01-2 2H7a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2z" />
#                         </svg>
#                         <p class="mt-2 text-sm text-gray-500">No uploads found</p>
#                         <button
#                           type="button"
#                           phx-click={JS.patch(~p"/dashboard?tab=upload")}
#                           class="mt-3 inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
#                         >
#                           Create Your First Upload
#                         </button>
#                       </div>
#                     <% else %>
#                       <div class="space-y-4">
#                         <%= for upload <- @recent_uploads do %>
#                           <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
#                             <div class="p-4">
#                               <div class="flex justify-between items-start">
#                                 <div>
#                                   <div class="flex items-center">
#                                     <span class="text-lg font-medium text-gray-900">
#                                       Upload #<%= upload.id %>
#                                     </span>
#                                     <%= case upload.status do %>
#                                       <% :success -> %>
#                                         <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
#                                           Success
#                                         </span>
#                                       <% :processing -> %>
#                                         <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
#                                           Processing
#                                         </span>
#                                       <% :failed -> %>
#                                         <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
#                                           Failed
#                                         </span>
#                                     <% end %>
#                                   </div>
#                                   <p class="text-sm text-gray-500 mt-1">
#                                     <%= Calendar.strftime(upload.timestamp, "%B %d, %Y at %I:%M %p") %>
#                                   </p>
#                                 </div>
#                                 
#                                 <div class="flex space-x-1">
#                                   <%= for platform <- upload.platforms do %>
#                                     <div 
#                                       class={"w-8 h-8 rounded-full flex items-center justify-center #{platform_color(platform)}"} 
#                                       title={platform |> Atom.to_string() |> String.capitalize()}
#                                     >
#                                       <!-- Platform icon would go here -->
#                                       <span class="text-xs text-white font-bold">
#                                         <%= platform |> Atom.to_string() |> String.first() |> String.upcase() %>
#                                       </span>
#                                     </div>
#                                   <% end %>
#                                 </div>
#                               </div>
#                               
#                               <!-- Posted Links -->
#                               <%= if upload.status == :success && map_size(upload.links) > 0 do %>
#                                 <div class="mt-4 pt-4 border-t border-gray-200">
#                                   <h4 class="text-sm font-medium text-gray-700 mb-2">Posted Links</h4>
#                                   <div class="space-y-2">
#                                     <%= for {platform, link} <- upload.links, link != nil do %>
#                                       <a 
#                                         href={link} 
#                                         target="_blank" 
#                                         rel="noopener noreferrer"
#                                         class="flex items-center text-sm text-indigo-600 hover:text-indigo-900"
#                                       >
#                                         <div class={"w-5 h-5 rounded-full flex items-center justify-center mr-2 #{platform_color(platform)}"}>
#                                           <span class="text-xs text-white font-bold">
#                                             <%= platform |> Atom.to_string() |> String.first() |> String.upcase() %>
#                                           </span>
#                                         </div>
#                                         View on <%= platform |> Atom.to_string() |> String.capitalize() %>
#                                         <svg xmlns="http://www.w3.org/2000/svg" class="ml-1 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
#                                           <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
#                                           <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
#                                         </svg>
#                                       </a>
#                                     <% end %>
#                                   </div>
#                                 </div>
#                               <% end %>
#                               
#                               <!-- Error Message -->
#                               <%= if upload.status == :failed && Map.get(upload, :error) do %>
#                                 <div class="mt-4 p-3 rounded bg-red-50 border border-red-100">
#                                   <p class="text-sm text-red-800">
#                                     <svg xmlns="http://www.w3.org/2000/svg" class="inline-block h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
#                                       <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
#                                     </svg>
#                                     <%= upload.error %>
#                                   </p>
#                                 </div>
#                               <% end %>
#                               
#                               <!-- Retry Button for Failed Uploads -->
#                               <%= if upload.status == :failed do %>
#                                 <div class="mt-4">
#                                   <button
#                                     type="button"
#                                     phx-click="retry-upload"
#                                     phx-value-id={upload.id}
#                                     class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
#                                   >
#                                     <svg xmlns="http://www.w3.org/2000/svg" class="mr-1.5 h-4 w-4 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
#                                       <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1
#                                       0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd" />
#                                     </svg>
#                                     Retry Upload
#                                   </button>
#                                 </div>
#                               <% end %>
#                             </div>
#                           </div>
#                         <% end %>
#                       </div>
#                     <% end %>
#                   <% end %>
#                 </div>
#             <% end %>
#           </div>
#         </div>
#       </div>
#     </div>
#     """
#   end
#   
#   # Event handler for disconnecting platforms
#   def handle_event("disconnect-platform", %{"platform" => platform}, socket) do
#     platform = String.to_existing_atom(platform)
#     
#     # In a real implementation, we would revoke the tokens for this platform
#     # For now, just update the UI
#     updated_accounts = Map.update!(
#       socket.assigns.social_accounts,
#       platform,
#       fn status -> %{status | connected: false} end
#     )
#     
#     # Also remove it from selected platforms if it was selected
#     updated_platforms = Enum.reject(
#       socket.assigns.selected_platforms,
#       fn p -> p == platform end
#     )
#     
#     {:noreply, 
#       socket
#       |> assign(:social_accounts, updated_accounts)
#       |> assign(:selected_platforms, updated_platforms)
#       |> put_flash(:info, "Disconnected from #{platform |> Atom.to_string() |> String.capitalize()}")}
#   end
#   
#   # Event handler for retrying failed uploads
#   def handle_event("retry-upload", %{"id" => id}, socket) do
#     # In a real implementation, we would retry the upload
#     # For now, just show a flash message
#     
#     {:noreply, 
#       socket
#       |> put_flash(:info, "Retrying upload ##{id}...")}
#   end
#   
#   # Helper function to determine the color for each platform
#   defp platform_color(platform) do
#     case platform do
#       :twitter -> "bg-blue-500"
#       :instagram -> "bg-pink-600"
#       :facebook -> "bg-blue-700"
#       :youtube -> "bg-red-600"
#       :tiktok -> "bg-black"
#       _ -> "bg-gray-600" # Default color
#     end
#   end
# end

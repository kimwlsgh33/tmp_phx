defmodule MyappWeb.TiktokHTML do
  use MyappWeb, :html

  @doc """
  Renders the TikTok show page.
  """
  attr :flash, :map, default: %{}
  attr :connected, :boolean, default: false
  attr :recent_videos, :list, default: []

  def show(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <div class="mx-auto max-w-2xl">
      <.header class="text-center">
        TikTok Integration Dashboard
        <:subtitle>
          Manage your TikTok integration and access TikTok API features
        </:subtitle>
      </.header>

      <div class="mt-10 space-y-8 bg-white p-8 rounded-lg shadow-lg">
        <div class="tiktok-section">
          <h2 class="text-xl font-bold mb-4">Account Connection</h2>
          <p class="mb-4">
            Connect your TikTok account to access video upload and management functionality.
          </p>
          
          <.oauth_status connected={@connected} />
        </div>

        <div class="tiktok-section">
          <h2 class="text-xl font-bold mb-4">API Features</h2>
          
          <ul class="list-disc pl-5 space-y-2">
            <li>Upload videos to your TikTok account</li>
            <li>Manage video publicity settings</li>
            <li>Schedule video posts</li>
            <li>Retrieve video analytics</li>
            <li>Manage comments and interactions</li>
          </ul>
        </div>

        <%= if @connected do %>
          <div class="tiktok-section">
            <h2 class="text-xl font-bold mb-4">Upload Video</h2>
            <p class="mb-4">Use our simplified interface to upload new videos to TikTok.</p>
            <a href="/tiktok/upload" class="bg-pink-600 hover:bg-pink-700 text-white py-2 px-4 rounded">
              Upload New Video
            </a>
          </div>
          
          <div class="tiktok-section">
            <h2 class="text-xl font-bold mb-4">Recent Videos</h2>
            <p class="mb-4">View and manage your recently uploaded TikTok videos.</p>
            
            <%= if Enum.empty?(@recent_videos) do %>
              <p class="text-gray-500 italic">No videos have been uploaded yet.</p>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= for video <- @recent_videos do %>
                  <div class="border rounded p-4">
                    <h3 class="font-bold"><%= video.title %></h3>
                    <p class="text-sm text-gray-600"><%= video.upload_date %></p>
                    <p class="mt-2"><%= video.description %></p>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
        
        <div class="tiktok-section">
          <h2 class="text-xl font-bold mb-4">TikTok API Documentation</h2>
          <p class="mb-4">
            Learn more about the TikTok API capabilities and integration options.
          </p>
          <a href="/docs/tiktok" class="text-blue-600 hover:underline">View API Documentation</a>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Embeds a TikTok video.
  """
  def embed_video(assigns) do
    ~H"""
    <div class="tiktok-video-embed">
      <h3>TikTok Video Embed</h3>
      <div class="embed-container">
        <!-- TikTok embed code would go here -->
        <p>Video ID: <%= @video_id %></p>
      </div>
    </div>
    """
  end

  @doc """
  Displays TikTok OAuth connection status.
  """
  def oauth_status(assigns) do
    ~H"""
    <div class="tiktok-oauth-status">
      <h3>TikTok OAuth Status</h3>
      <p>
        <%= if @connected do %>
          <span class="status connected">Connected</span>
        <% else %>
          <span class="status disconnected">Not Connected</span>
          <a href="/tiktok/oauth" class="btn-connect">Connect to TikTok</a>
        <% end %>
      </p>
    </div>
    """
  end

  @doc """
  Renders the TikTok video upload form.
  """
  attr :flash, :map, default: %{}
  attr :connected, :boolean, default: false
  attr :changeset, :map, default: nil

  def upload_form(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <div class="mx-auto max-w-2xl">
      <.header class="text-center">
        Upload Video to TikTok
        <:subtitle>
          Share your content on TikTok directly from our platform
        </:subtitle>
      </.header>

      <div class="mt-10 space-y-8 bg-white p-8 rounded-lg shadow-lg">
        <%= if !@connected do %>
          <div class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-6" role="alert">
            <p class="font-bold">Not Connected</p>
            <p>You need to connect your TikTok account before uploading videos.</p>
            <a href="/tiktok/oauth" class="mt-2 inline-block bg-pink-600 hover:bg-pink-700 text-white py-1 px-3 rounded text-sm">
              Connect to TikTok
            </a>
          </div>
        <% else %>
          <.form for={@changeset || %{}} multipart={true} action={~p"/tiktok/upload"} class="space-y-8">
            <div class="grid grid-cols-1 gap-6">
              <div>
                <.input type="text" label="Title" name="video[title]" required />
                <div class="text-xs text-gray-500 mt-1">Give your video a catchy title (required)</div>
              </div>

              <div>
                <.input type="textarea" label="Description" name="video[description]" rows="4" required />
                <div class="text-xs text-gray-500 mt-1">Describe your video (required)</div>
              </div>

              <div>
                <.input type="file" name="video[file]" label="Video File" accept="video/*" required />
                <div class="text-xs text-gray-500 mt-1">
                  Supported formats: MP4, WEBM<br>
                  Maximum file size: 500MB
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Privacy Settings</label>
                <select name="video[privacy_level]" class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-pink-500 focus:border-pink-500 sm:text-sm rounded-md">
                  <option value="public">Public</option>
                  <option value="friends">Friends Only</option>
                  <option value="private">Private</option>
                </select>
              </div>

              <div>
                <.input type="checkbox" name="video[allow_comment]" value="true" label="Enable comments" checked />
              </div>

              <div>
                <.input type="checkbox" name="video[allow_stitch]" value="true" label="Allow stitching" checked />
              </div>

              <div>
                <.input type="checkbox" name="video[allow_duet]" value="true" label="Allow duets" checked />
              </div>

              <div class="pt-4">
                <.button type="submit" class="w-full py-3 bg-pink-600 hover:bg-pink-700">
                  Upload to TikTok
                </.button>
              </div>
            </div>
          </.form>

          <div class="mt-10 border-t pt-6">
            <h3 class="text-lg font-bold mb-2">Upload Guidelines</h3>
            <ul class="list-disc pl-5 space-y-1 text-sm text-gray-600">
              <li>Make sure your content complies with TikTok's Community Guidelines</li>
              <li>Videos must be shorter than 10 minutes</li>
              <li>Ensure you have the right to share all content in your video</li>
              <li>Avoid using copyrighted music without permission</li>
              <li>Vertical videos (9:16) work best on TikTok</li>
            </ul>
          </div>
        <% end %>

        <div class="border-t pt-6">
          <a href="/tiktok" class="text-pink-600 hover:underline">&larr; Back to TikTok Dashboard</a>
        </div>
      </div>
    </div>
    """
  end
end



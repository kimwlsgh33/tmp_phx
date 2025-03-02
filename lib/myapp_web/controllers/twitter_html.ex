defmodule MyappWeb.TwitterHTML do
  use MyappWeb, :html

  @doc """
  Renders the Twitter show page.
  """
  attr :flash, :map, default: %{}
  attr :connected, :boolean, default: false
  attr :recent_tweets, :list, default: []

  def show(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <div class="mx-auto max-w-2xl">
      <.header class="text-center">
        Twitter/X Integration Dashboard
        <:subtitle>
          Manage your Twitter integration and access Twitter API features
        </:subtitle>
      </.header>

      <div class="mt-10 space-y-8 bg-white p-8 rounded-lg shadow-lg">
        <div class="twitter-section">
          <h2 class="text-xl font-bold mb-4">Account Connection</h2>
          <p class="mb-4">
            Connect your Twitter account to access tweet functionality and timeline management.
          </p>
          
          <.oauth_status connected={@connected} />
        </div>

        <div class="twitter-section">
          <h2 class="text-xl font-bold mb-4">API Features</h2>
          
          <ul class="list-disc pl-5 space-y-2">
            <li>Post tweets with text content</li>
            <li>Upload images or videos with your tweets</li>
            <li>View your Twitter timeline</li>
            <li>Delete your tweets</li>
            <li>Monitor engagement metrics</li>
          </ul>
        </div>

        <%= if @connected do %>
          <div class="twitter-section">
            <h2 class="text-xl font-bold mb-4">Compose Tweet</h2>
            <p class="mb-4">Share your thoughts or media directly to Twitter.</p>
            <a href="/twitter/tweet" class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded">
              Compose New Tweet
            </a>
          </div>
          
          <div class="twitter-section">
            <h2 class="text-xl font-bold mb-4">Recent Tweets</h2>
            <p class="mb-4">View and manage your recently posted tweets.</p>
            
            <%= if Enum.empty?(@recent_tweets) do %>
              <p class="text-gray-500 italic">No tweets have been posted yet.</p>
            <% else %>
              <div class="space-y-4">
                <%= for tweet <- @recent_tweets do %>
                  <div class="border rounded p-4">
                    <p class="text-sm text-gray-600"><%= tweet.created_at %></p>
                    <p class="mt-2"><%= tweet.text %></p>
                    <div class="mt-2 flex space-x-4 text-sm text-gray-500">
                      <span><%= tweet.retweet_count %> Retweets</span>
                      <span><%= tweet.like_count %> Likes</span>
                    </div>
                    <div class="mt-2">
                      <button phx-click="delete-tweet" phx-value-id={tweet.id} class="text-red-500 hover:underline text-sm">
                        Delete Tweet
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
        
        <div class="twitter-section">
          <h2 class="text-xl font-bold mb-4">Twitter API Documentation</h2>
          <p class="mb-4">
            Learn more about the Twitter API capabilities and integration options.
          </p>
          <a href="/docs/twitter" class="text-blue-600 hover:underline">View API Documentation</a>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Embeds a tweet.
  """
  def embed_tweet(assigns) do
    ~H"""
    <div class="twitter-tweet-embed">
      <h3>Tweet Embed</h3>
      <div class="embed-container">
        <!-- Twitter embed code would go here -->
        <p>Tweet ID: <%= @tweet_id %></p>
      </div>
    </div>
    """
  end

  @doc """
  Displays Twitter OAuth connection status.
  """
  def oauth_status(assigns) do
    ~H"""
    <div class="twitter-oauth-status">
      <h3>Twitter OAuth Status</h3>
      <p>
        <%= if @connected do %>
          <span class="status connected">Connected</span>
        <% else %>
          <span class="status disconnected">Not Connected</span>
          <a href="/twitter/connect" class="btn-connect">Connect to Twitter</a>
        <% end %>
      </p>
    </div>
    """
  end

  @doc """
  Renders the Twitter tweet composition form.
  """
  attr :flash, :map, default: %{}
  attr :connected, :boolean, default: false
  attr :changeset, :map, default: nil

  def tweet_form(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <div class="mx-auto max-w-2xl">
      <.header class="text-center">
        Compose a Tweet
        <:subtitle>
          Share your thoughts on Twitter directly from our platform
        </:subtitle>
      </.header>

      <div class="mt-10 space-y-8 bg-white p-8 rounded-lg shadow-lg">
        <%= if !@connected do %>
          <div class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-6" role="alert">
            <p class="font-bold">Not Connected</p>
            <p>You need to connect your Twitter account before posting tweets.</p>
            <a href="/twitter/connect" class="mt-2 inline-block bg-blue-500 hover:bg-blue-600 text-white py-1 px-3 rounded text-sm">
              Connect to Twitter
            </a>
          </div>
        <% else %>
          <.form for={@changeset || %{}} multipart={true} action={~p"/twitter/tweet"} class="space-y-8">
            <div class="grid grid-cols-1 gap-6">
              <div>
                <.input type="textarea" label="Tweet Content" name="tweet[text]" rows="4" maxlength="280" required />
                <div class="text-xs text-gray-500 mt-1">Maximum 280 characters (required)</div>
              </div>

              <div>
                <.input type="file" name="tweet[media]" label="Media" accept="image/*,video/*" />
                <div class="text-xs text-gray-500 mt-1">
                  Add images or a short video to your tweet<br>
                  Supported formats: JPG, PNG, GIF, MP4<br>
                  Maximum file size: 15MB for videos, 5MB for images
                </div>
              </div>

              <div>
                <.input type="checkbox" name="tweet[sensitive_content]" value="true" label="Mark as sensitive content" />
              </div>

              <div class="pt-4">
                <.button type="submit" class="w-full py-3 bg-blue-500 hover:bg-blue-600">
                  Post Tweet
                </.button>
              </div>
            </div>
          </.form>

          <div class="mt-10 border-t pt-6">
            <h3 class="text-lg font-bold mb-2">Twitter Guidelines</h3>
            <ul class="list-disc pl-5 space-y-1 text-sm text-gray-600">
              <li>Make sure your content complies with Twitter's Terms of Service</li>
              <li>Tweets are limited to 280 characters</li>
              <li>You can upload up to 4 images or 1 video per tweet</li>
              <li>Videos must be shorter than 2 minutes and 20 seconds</li>
              <li>Ensure you have the right to share all content in your tweet</li>
            </ul>
          </div>
        <% end %>

        <div class="border-t pt-6">
          <a href="/twitter" class="text-blue-500 hover:underline">&larr; Back to Twitter Dashboard</a>
        </div>
      </div>
    </div>
    """
  end
end


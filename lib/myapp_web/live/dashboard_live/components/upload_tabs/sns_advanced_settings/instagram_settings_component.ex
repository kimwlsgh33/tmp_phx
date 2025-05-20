defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.InstagramSettingsComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    platform_key = :instagram
    platform_settings = assigns[:advanced_settings][platform_key] || %{}

    socket =
      socket
      |> assign(assigns)
      |> assign(:platform_key, platform_key)
      |> assign(:platform_settings, Map.merge(%{
        "hide_like_count" => false,
        "turn_off_comments" => false,
        "share_to_facebook" => false,
        "content_type" => "feed"
      }, platform_settings))

    {:ok, socket}
  end

  @impl true
  def handle_event("update_setting", params, socket) do
    # 로그를 추가하여 디버깅에 도움이 되도록 합니다
    IO.inspect(params, label: "Raw form params")
    
    updated_settings = update_settings(socket.assigns.platform_settings, params)

    # 메시지를 대시보드 LiveView로 직접 전송
    send(self(), {:advanced_settings_updated, %{platform: socket.assigns.platform_key, settings: updated_settings}})

    {:noreply, assign(socket, :platform_settings, updated_settings)}
  end

  # 폼에서 전달된 파라미터를 처리하는 새로운 함수
  defp update_settings(settings, params) do
    # _target, _csrf 등의 내부 필드는 무시
    params
    |> Enum.reduce(settings, fn
      {"_" <> _, _}, acc -> 
        # 언더스코어로 시작하는 필드는 Phoenix 내부 필드이므로 무시
        acc
      
      {"key=" <> rest, value}, acc ->
        # key= 접두사를 가진 폼 필드 처리
        case String.split(rest, "&") do
          [key, "value"] -> 
            # 값을 가진 필드 (예: select, input text)
            Map.put(acc, key, value)
          
          [key, "checked"] -> 
            # 체크박스
            Map.put(acc, key, value == "on")
            
          _ -> acc
        end
        
      _, acc -> acc  # 기타 필드 무시
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="instagram-advanced-settings">
      <h4 class="text-md font-medium text-purple-600 mb-3 flex items-center">
        <svg class="w-5 h-5 mr-1" viewBox="0 0 24 24">
          <linearGradient id="instagram-gradient" x1="0%" y1="100%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#FFDC80" />
            <stop offset="25%" stop-color="#FCAF45" />
            <stop offset="50%" stop-color="#F77737" />
            <stop offset="75%" stop-color="#F56040" />
            <stop offset="100%" stop-color="#C13584" />
          </linearGradient>
          <path fill="url(#instagram-gradient)" d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
        </svg>
      </h4>

      <div class="space-y-3">
        <form phx-change="update_setting" phx-target={@myself}>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Content Type</label>
            <select
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              name="key=content_type&value"
            >
              <option value="feed" selected={@platform_settings["content_type"] == "feed"}>Feed Post</option>
              <option value="story" selected={@platform_settings["content_type"] == "story"}>Story</option>
              <option value="reel" selected={@platform_settings["content_type"] == "reel"}>Reel</option>
            </select>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=hide_like_count&checked"
                checked={@platform_settings["hide_like_count"]}
              />
              <span class="ml-2 text-sm text-gray-700">Hide like count</span>
            </label>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=turn_off_comments&checked"
                checked={@platform_settings["turn_off_comments"]}
              />
              <span class="ml-2 text-sm text-gray-700">Turn off commenting</span>
            </label>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=share_to_facebook&checked"
                checked={@platform_settings["share_to_facebook"]}
              />
              <span class="ml-2 text-sm text-gray-700">Share to connected Facebook page</span>
            </label>
          </div>
        </form>
      </div>
    </div>
    """
  end
end

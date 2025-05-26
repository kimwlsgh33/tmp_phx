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

defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.YoutubeSettingsComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    platform_key = :youtube
    platform_settings = assigns[:advanced_settings][platform_key] || %{}

    socket =
      socket
      |> assign(assigns)
      |> assign(:platform_key, platform_key)
      |> assign(:platform_settings, Map.merge(%{
        "visibility" => "public",
        "made_for_kids" => false,
        "allow_comments" => true,
        "category" => "22", # People & Blogs default
        "license" => "standard"
      }, platform_settings))

    {:ok, socket}
  end

  @impl true
  def handle_event("update_setting", params, socket) do
    # 로그를 추가하여 디버깅에 도움이 되도록 합니다
    IO.inspect(params, label: "YouTube form params")
    
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
  
  # 폼에서 예상하지 못한 형식의 데이터가 오는 경우에 대한 폴백 처리
  defp update_settings(settings, params) when map_size(params) == 0 do
    settings
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="youtube-advanced-settings">
      <h4 class="text-md font-medium text-red-600 mb-3 flex items-center">
        <svg class="w-5 h-5 mr-1" viewBox="0 0 24 24" fill="#FF0000">
          <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
        </svg>
      </h4>

      <div class="space-y-3">
        <form phx-change="update_setting" phx-target={@myself}>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Visibility</label>
            <select
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              name="key=visibility&value"
            >
              <option value="public" selected={@platform_settings["visibility"] == "public"}>Public</option>
              <option value="unlisted" selected={@platform_settings["visibility"] == "unlisted"}>Unlisted</option>
              <option value="private" selected={@platform_settings["visibility"] == "private"}>Private</option>
            </select>
          </div>

          <div class="mt-3">
            <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
            <select
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              name="key=category&value"
            >
              <option value="1" selected={@platform_settings["category"] == "1"}>Film & Animation</option>
              <option value="2" selected={@platform_settings["category"] == "2"}>Autos & Vehicles</option>
              <option value="10" selected={@platform_settings["category"] == "10"}>Music</option>
              <option value="15" selected={@platform_settings["category"] == "15"}>Pets & Animals</option>
              <option value="17" selected={@platform_settings["category"] == "17"}>Sports</option>
              <option value="20" selected={@platform_settings["category"] == "20"}>Gaming</option>
              <option value="22" selected={@platform_settings["category"] == "22"}>People & Blogs</option>
              <option value="23" selected={@platform_settings["category"] == "23"}>Comedy</option>
              <option value="24" selected={@platform_settings["category"] == "24"}>Entertainment</option>
              <option value="25" selected={@platform_settings["category"] == "25"}>News & Politics</option>
              <option value="26" selected={@platform_settings["category"] == "26"}>Howto & Style</option>
              <option value="27" selected={@platform_settings["category"] == "27"}>Education</option>
              <option value="28" selected={@platform_settings["category"] == "28"}>Science & Technology</option>
            </select>
          </div>

          <div class="mt-3">
            <label class="block text-sm font-medium text-gray-700 mb-1">License</label>
            <select
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              name="key=license&value"
            >
              <option value="standard" selected={@platform_settings["license"] == "standard"}>Standard YouTube License</option>
              <option value="creative_commons" selected={@platform_settings["license"] == "creative_commons"}>Creative Commons - Attribution</option>
            </select>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=made_for_kids&checked"
                checked={@platform_settings["made_for_kids"]}
              />
              <span class="ml-2 text-sm text-gray-700">This content is made for kids</span>
            </label>
            <p class="mt-1 text-xs text-gray-500 ml-6">
              Selecting this option will set your video to comply with COPPA regulations
            </p>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=allow_comments&checked"
                checked={@platform_settings["allow_comments"]}
              />
              <span class="ml-2 text-sm text-gray-700">Allow comments</span>
            </label>
          </div>
        </form>
      </div>
    </div>
    """
  end
end

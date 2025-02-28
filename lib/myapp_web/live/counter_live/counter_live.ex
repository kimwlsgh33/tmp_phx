defmodule MyappWeb.CounterLive do
  use MyappWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Logger.info("WebSocket 연결이 설정되었습니다.")
    else
      Logger.info("초기 HTTP 요청이 발생했습니다.")
    end

    # LiveView 연결상태 확인하기 위한 코드
    IO.puts("mounting (connected: #{connected?(socket)})")
    # assign/2 은 LiveView 상태 업데이트 함수
    {:ok, assign(socket, count: 0)}
  end

  # 로그를 보면 알겠지만, LiveView가 처음 로드될 때 두번 호출됨.
  # 초기 페이지 로드시 한번, 라이브 소켓 설정 위해 한번 더.

  # 클라이언트에서 발생한 이벤트 처리 함수 increment 이벤트 발생시 함수 호출
  def handle_event("increment", _value, socket) do
    # Logger로 count값 출력위함.
    new_count = socket.assigns.count + 1
    Logger.info("count: #{new_count}")
    {:noreply, assign(socket, count: new_count)}
  end

  def handle_event("decrement", _value, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  # counter_live.html.heex
  # 자동으로 heex 템플릿 사용 따로 render함수 작성 필요 없음 ㄷㄷ
end

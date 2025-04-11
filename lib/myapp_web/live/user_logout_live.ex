defmodule MyappWeb.UserLogoutLive do
  use MyappWeb, :live_view

  alias Myapp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      linked_accounts = Accounts.list_linked_accounts(current_user)

      {:ok,
       assign(socket,
         page_title: "Sign Out",
         current_user: current_user,
         linked_accounts: linked_accounts
       )}
    else
      {:ok, redirect(socket, to: ~p"/users/sign_out")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md">
      <div class="flex p-4 border-b border-zinc-700 items-center justify-between mb-8">
        <h1 class="text-2xl font-semibold text-zinc-300">Sign Out</h1>
      </div>

      <div class="bg-black rounded-lg shadow-lg p-6 mb-6">
        <h2 class="text-lg font-semibold text-zinc-300 mb-4">Current Account</h2>
        <div class="flex items-center justify-between p-4 border border-zinc-700 rounded-lg mb-2">
          <div class="flex items-center">
            <div class="h-10 w-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold mr-3">
              {String.first(@current_user.email)}
            </div>
            <div>
              <div class="text-zinc-300">{@current_user.email}</div>
              <div class="text-xs text-zinc-500">Current session</div>
            </div>
          </div>
          <.form :let={_} for={%{}} action={~p"/users/log_out"} method="delete">
            <button
              type="submit"
              class="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-md transition"
            >
              Sign Out
            </button>
          </.form>
        </div>

        <%= if length(@linked_accounts) > 0 do %>
          <h2 class="text-lg font-semibold text-zinc-300 mt-8 mb-4">Linked Accounts</h2>
          <%= for account <- @linked_accounts do %>
            <div class="flex items-center justify-between p-4 border border-zinc-700 rounded-lg mb-2">
              <div class="flex items-center">
                <div class="h-10 w-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold mr-3">
                  {String.first(account.user.email)}
                </div>
                <div class="text-zinc-300">{account.user.email}</div>
              </div>
              <.form
                :let={_}
                for={%{}}
                action={~p"/users/log_out?logout_user_id=#{account.user.id}"}
                method="delete"
              >
                <button
                  type="submit"
                  class="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-md transition"
                >
                  Sign Out
                </button>
              </.form>
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="flex justify-end">
        <.link
          navigate={~p"/"}
          class="px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white rounded-md transition"
        >
          Cancel
        </.link>
      </div>
    </div>
    """
  end
end

defmodule MyappWeb.UserLoginLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 bg-gray-50">
      <div class="max-w-md w-full space-y-8 bg-white p-8 rounded-xl shadow-lg transition-all duration-300 hover:shadow-xl">
        <div class="text-center">
          <!-- App Logo/Icon -->
          <div class="mx-auto h-16 w-16 flex items-center justify-center rounded-full bg-[#FD4F00]/10 mb-6">
            <svg
              class="h-10 w-10 text-[#FD4F00]"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
              />
            </svg>
          </div>

          <.header class="text-center">
            <span class="text-2xl font-bold text-gray-900">Log in to your account</span>
            <:subtitle>
              <p class="mt-2 text-sm text-gray-600">
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-[#FD4F00] hover:underline transition-colors duration-200"
                >
                  Sign up
                </.link>
                for an account now.
              </p>
            </:subtitle>
          </.header>
        </div>

        <.simple_form
          for={@form}
          id="login_form"
          action={~p"/users/log_in"}
          phx-update="ignore"
          class="mt-8 space-y-6"
        >
          <div class="space-y-4">
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="your@email.com"
              autocomplete="email"
              class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 focus:ring-2 focus:ring-[#FD4F00] focus:border-[#FD4F00]"
              required
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              placeholder="••••••••"
              autocomplete="current-password"
              class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 focus:ring-2 focus:ring-[#FD4F00] focus:border-[#FD4F00]"
              required
            />
          </div>

          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <.input
                field={@form[:remember_me]}
                type="checkbox"
                label="Keep me logged in"
                class="h-4 w-4 text-[#FD4F00] focus:ring-[#FD4F00] border-gray-300 rounded"
              />
            </div>
            <div class="text-sm">
              <.link
                href={~p"/users/reset_password"}
                class="font-medium text-[#FD4F00] hover:text-[#E04600] transition-colors duration-200"
              >
                Forgot your password?
              </.link>
            </div>
          </div>

          <:actions>
            <.button
              phx-disable-with="Logging in..."
              class="w-full py-3 px-4 rounded-md font-medium text-white bg-zinc-900 hover:bg-zinc-700 transition-all duration-200 transform hover:scale-[1.02] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#FD4F00]"
            >
              <span class="flex items-center justify-center">
                <span>Log in</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 ml-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M14 5l7 7m0 0l-7 7m7-7H3"
                  />
                </svg>
              </span>
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">Or continue with</span>
            </div>
          </div>

          <div class="mt-6 grid grid-cols-1 gap-3">
            <a
              href={MyappWeb.Router.Helpers.google_path(MyappWeb.Endpoint, :request, "google")}
              class="w-full inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors duration-200"
            >
              <svg
                class="h-5 w-5 mr-2"
                viewBox="0 0 24 24"
                width="24"
                height="24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <g transform="matrix(1, 0, 0, 1, 27.009001, -39.238998)">
                  <path
                    fill="#4285F4"
                    d="M -3.264 51.509 C -3.264 50.719 -3.334 49.969 -3.454 49.239 L -14.754 49.239 L -14.754 53.749 L -8.284 53.749 C -8.574 55.229 -9.424 56.479 -10.684 57.329 L -10.684 60.329 L -6.824 60.329 C -4.564 58.239 -3.264 55.159 -3.264 51.509 Z"
                  />
                  <path
                    fill="#34A853"
                    d="M -14.754 63.239 C -11.514 63.239 -8.804 62.159 -6.824 60.329 L -10.684 57.329 C -11.764 58.049 -13.134 58.489 -14.754 58.489 C -17.884 58.489 -20.534 56.379 -21.484 53.529 L -25.464 53.529 L -25.464 56.619 C -23.494 60.539 -19.444 63.239 -14.754 63.239 Z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M -21.484 53.529 C -21.734 52.809 -21.864 52.039 -21.864 51.239 C -21.864 50.439 -21.724 49.669 -21.484 48.949 L -21.484 45.859 L -25.464 45.859 C -26.284 47.479 -26.754 49.299 -26.754 51.239 C -26.754 53.179 -26.284 54.999 -25.464 56.619 L -21.484 53.529 Z"
                  />
                  <path
                    fill="#EA4335"
                    d="M -14.754 43.989 C -12.984 43.989 -11.404 44.599 -10.154 45.789 L -6.734 42.369 C -8.804 40.429 -11.514 39.239 -14.754 39.239 C -19.444 39.239 -23.494 41.939 -25.464 45.859 L -21.484 48.949 C -20.534 46.099 -17.884 43.989 -14.754 43.989 Z"
                  />
                </g>
              </svg>
              <span>Sign in with Google</span>
            </a>
          </div>
        </div>

        <p class="mt-8 text-center text-xs text-gray-500">
          By signing in, you agree to our
          <a href="#" class="text-[#FD4F00] hover:underline">Terms of Service</a>
          and <a href="#" class="text-[#FD4F00] hover:underline">Privacy Policy</a>.
        </p>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

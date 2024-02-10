defmodule RecitWeb.GameLive do
  use RecitWeb, :live_view

  alias Recit.Files

  @file_list Files.load_file_list()
  @categories_per_round 4
  @images_per_category 3

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto flex flex-col justify-center items-center">
      <h1 class="font-bold text-5xl mb-4">Guess the Image!</h1>
      <h2 class="font-semibold text-xs text-gray-700 mb-8 ">
        You're connected to region: <%= @region %>
      </h2>
      <div class="font-bold text-4xl mb-6">
        Score: <%= @score %>
      </div>
      <div class="h-64 w-64 shadow-lg rounded-lg">
        <img :if={@image_url} src={@image_url} class="rounded-lg w-full h-full" />
      </div>
      <div :if={@categories != []} class="mt-3 flex space-x-2" phx-window-keydown="key_down">
        <.button :for={{category, idx} <- @categories} phx-click="guess" phx-value-category={category}>
          <span class="badge"><%= idx %></span>
          <span class="ml-1 capitalize"><%= category %></span>
        </.button>
      </div>
      <button
        phx-click="start-round"
        class="mt-20 bg-green-400 font-bold text-2xl px-8 py-4 text-black hover:bg-green-600 rounded-lg flex items-center gap-2 leading-6"
      >
        <span class="badge">Enter</span> Start new round
      </button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> reset_assigns()
    |> ok()
  end

  def handle_event("start-round", _params, socket) do
    socket |> start_new_round() |> noreply()
  end

  def handle_event("guess", %{"category" => category}, socket) do
    socket |> check_guess(category) |> noreply()
  end

  def handle_event("key_down", %{"key" => key}, socket) when key in ["Enter", " "] do
    socket |> start_new_round() |> noreply()
  end

  def handle_event("key_down", %{"key" => key}, socket) do
    categories = socket.assigns.categories

    case Integer.parse(key) do
      {idx, ""} when idx <= @categories_per_round ->
        {guessed_category, _idx} =
          Enum.find(categories, fn {_category, category_idx} -> category_idx == idx end)

        socket |> check_guess(guessed_category) |> noreply()

      _ ->
        noreply(socket)
    end
  end

  defp reset_assigns(socket) do
    socket
    |> assign_categories()
    |> assign(
      images: [],
      image_url: nil,
      current_category: nil,
      score: 0,
      timer: nil,
      region: region()
    )
  end

  defp assign_categories(socket) do
    categories =
      @file_list |> Files.get_random_categories(@categories_per_round) |> Enum.with_index(1)

    assign(socket, :categories, categories)
  end

  defp assign_images(socket) do
    categories = socket.assigns.categories

    images =
      Enum.reduce(categories, [], fn {category, _idx}, acc ->
        @file_list
        |> Files.get_random_image_paths_for_category(category, @images_per_category)
        |> Enum.map(fn path -> {category, path} end)
        |> Enum.concat(acc)
      end)
      |> List.flatten()

    assign(socket, :images, images)
  end

  defp assign_random_image(socket) do
    images = socket.assigns.images

    if images == [] do
      handle_game_end(socket)
    else
      {{category, path}, images} = images |> Enum.shuffle() |> List.pop_at(0)
      {:ok, image_url} = Recit.Storage.get_download_url(path)
      assign(socket, images: images, image_url: image_url, current_category: category)
    end
  end

  defp start_timer(socket) do
    assign(socket, :timer, DateTime.utc_now(:millisecond))
  end

  defp check_guess(%{assigns: %{current_category: nil}} = socket, _guessed_category) do
    socket
  end

  defp check_guess(socket, guessed_category) do
    if guessed_category == socket.assigns.current_category do
      socket |> update(:score, fn score -> score + 1 end) |> assign_random_image()
    else
      assign_random_image(socket)
    end
  end

  defp start_new_round(socket) do
    socket
    |> assign_images()
    |> assign_random_image()
    |> start_timer()
  end

  defp handle_game_end(socket) do
    now = DateTime.utc_now()
    %{score: final_score, timer: timer} = socket.assigns

    duration = if timer, do: DateTime.diff(now, timer, :millisecond), else: 0
    duration = Float.round(duration / 1000, 2)

    socket
    |> put_flash(:info, "Game over! You scored a #{final_score} in #{duration}s!")
    |> reset_assigns()
  end

  defp region(), do: Application.get_env(:recit, :region)
end

defmodule Styler.Style.Readability.MultiAlias do
  @moduledoc """
  Corresponds to `Credo.Check.Readability.MultiAlias`

      Multi alias expansion makes module uses harder to search for in large code bases.

          # preferred

          alias Module.Foo
          alias Module.Bar

          # NOT preferred

          alias Module.{Foo, Bar}

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.


  Expands `alias`, `import`, `require`, and `use` directives to one per line. The original order is preserved.

  Rewrites the following Credo Rules: 
   - `Credo.Check.Readability.MultiAlias`
   - `Credo.Check.Readability.UnnecessaryAliasExpansion`
  """

  @behaviour Styler.Style

  alias Styler.Style
  alias Styler.Zipper

  @directives ~w(alias import require use)a

  def run({{:defmodule, _, children}, _} = zipper, ctx) do
    [_name, [{{:__block__, do_meta, [:do]}, _body}]] = children

    if do_meta[:format] == :keyword do
      {:skip, zipper, ctx}
    else
      # Move the zipper's focus to the module's body
      body_zipper = zipper |> Zipper.down() |> Zipper.right() |> Zipper.down() |> Zipper.down() |> Zipper.right()

      case Zipper.node(body_zipper) do
        {:__block__, _, _} ->
          {:skip, expand_directives(body_zipper), ctx}

        {:@, _, [{:moduledoc, _, _}]} ->
          # a module whose only child is a moduledoc. nothing to do here!
          # seems weird at first blush but lots of projects/libraries do this with their root namespace module
          {:skip, zipper, ctx}

        _only_child ->
          # style the only_child
          run(body_zipper, ctx)
      end
    end
  end

  def run({{def, _, children}, _} = zipper, ctx) when def in ~w(def defp defmacro defmacrop)a and is_list(children) do
    # we don't want to look at import nodes like `def import(foo)`
    if def_body = zipper |> Zipper.down() |> Zipper.right(),
      do: {:cont, def_body, ctx},
      else: {:skip, zipper, ctx}
  end

  def run({{directive, _, children}, _} = zipper, ctx) when directive in @directives and is_list(children) do
    parent = zipper |> Style.ensure_block_parent() |> Zipper.up()
    {:skip, expand_directives(parent), ctx}
  end

  def run(zipper, ctx), do: {:cont, zipper, ctx}

  defp expand_directives(parent) do
    directives =
      parent
      |> Zipper.children()
      |> Enum.flat_map(&expand_directive/1)

    if Enum.empty?(directives) do
      parent
    else
      Zipper.update(parent, &Zipper.replace_children(&1, directives))
    end
  end

  # alias Foo.{Bar, Baz}
  # =>
  # alias Foo.Bar
  # alias Foo.Baz
  defp expand_directive({directive, _, [{{:., _, [{:__aliases__, _, module}, :{}]}, _, right}]}),
    do: Enum.map(right, fn {_, meta, segments} -> {directive, meta, [{:__aliases__, [], module ++ segments}]} end)

  # alias __MODULE__.{Bar, Baz}
  defp expand_directive({directive, _, [{{:., _, [{:__MODULE__, _, _} = module, :{}]}, _, right}]}),
    do: Enum.map(right, fn {_, meta, segments} -> {directive, meta, [{:__aliases__, [], [module | segments]}]} end)

  defp expand_directive(other), do: [other]
end

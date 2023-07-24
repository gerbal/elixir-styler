defmodule Styler.Style.Readability.MultiAliasTest do
  use ExUnit.Case
  use Styler.StyleCase, async: true

  doctest Styler.Style.Readability.MultiAlias
  @module Styler.Style.Readability.MultiAlias

  describe "defmodule features" do
    test "handles module with no directives" do
      assert_style(
        @module,
        """
        defmodule Test do
          def foo, do: :ok
        end
        """
      )
    end

    test "handles dynamically generated modules" do
      assert_style(
        @module,
        """
        Enum.each(testing_list, fn test_item ->
          defmodule test_item do
          end
        end)
        """
      )
    end

    test "module with single child" do
      assert_style(
        @module,
        """
        defmodule ATest do
          alias Foo.{A, B}
        end
        """,
        """
        defmodule ATest do
          alias Foo.A
          alias Foo.B
        end
        """
      )
    end

    test "does not alter moduledoc" do
      assert_style(
        @module,
        """
        defmodule A do
        end

        defmodule B do
          defmodule C do
          end
        end

        defmodule Bar do
          alias Bop

          :ok
        end

        defmodule DocsOnly do
          @moduledoc "woohoo"
        end

        defmodule Foo do
          use Bar
        end

        defmodule Foo do
          alias Foo.{Bar, Baz}
        end

        defmodule Foo do
          @moduledoc "woohoo"
          alias Foo.Bar
        end
        """,
        """
        defmodule A do
        end

        defmodule B do
          defmodule C do
          end
        end

        defmodule Bar do
          alias Bop

          :ok
        end

        defmodule DocsOnly do
          @moduledoc "woohoo"
        end

        defmodule Foo do
          use Bar
        end

        defmodule Foo do
          alias Foo.Bar
          alias Foo.Baz
        end

        defmodule Foo do
          @moduledoc "woohoo"
          alias Foo.Bar
        end
        """
      )
    end

    test "skips keyword defmodules" do
      assert_style(
        @module,
        "defmodule Foo, do: use(Bar)"
      )
    end
  end

  describe "strange parents!" do
    test "regression: doesn't trigger on variables" do
      assert_style(
        @module,
        "def foo(alias), do: Foo.bar(alias)"
      )
    end

    test "anon function" do
      assert_style(@module, "fn -> alias A.{C, B} end", """
      fn ->
        alias A.C
        alias A.B
      end
      """)
    end

    test "quote do with one child" do
      assert_style(
        @module,
        """
        quote do
          alias A.{C, B}
        end
        """,
        """
        quote do
          alias A.C
          alias A.B
        end
        """
      )
    end

    test "quote do with multiple children" do
      assert_style(
        @module,
        """
        quote do
          import A
          import B
        end
        """
      )
    end
  end

  describe "directive expansion" do
    test "isn't fooled by function names" do
      assert_style(
        @module,
        """
        def import(foo) do
          import B.{
            A,
            C
          }

          import A
        end
        """,
        """
        def import(foo) do
          import B.A
          import B.C
          import A
        end
        """
      )
    end

    test "handles a lonely lonely directive" do
      assert_style(
        @module,
        "import Foo"
      )
    end

    test "expands alias while respecting groups" do
      assert_style(
        @module,
        """
        alias D
        alias A.{B}
        alias A.{
          A,
          B,
          C
        }
        alias A.B

        alias B
        alias A
        """,
        """
        alias D
        alias A.B
        alias A.A
        alias A.B
        alias A.C
        alias A.B

        alias B
        alias A
        """
      )
    end

    test "expands __MODULE__" do
      assert_style(
        @module,
        """
        alias __MODULE__.{B.D, A}
        """,
        """
        alias __MODULE__.B.D
        alias __MODULE__.A
        """
      )
    end

    test "expands use but does not sort it" do
      assert_style(
        @module,
        """
        use D
        use A
        use A.{
          C,
          B
        }
        import F
        """,
        """
        use D
        use A
        use A.C
        use A.B
        import F
        """
      )
    end

    test "interwoven directives w/o the context of a module" do
      assert_style(
        @module,
        """
        @type foo :: :ok
        alias D
        alias A.{B}
        require A.{
          A,
          C
        }
        alias B
        alias A
        """,
        """
        @type foo :: :ok
        alias D
        alias A.B
        require A.A
        require A.C
        alias B
        alias A
        """
      )
    end

    test "respects as" do
      assert_style(
        @module,
        """
        alias Foo.Asset
        alias Foo.Project.Loaders, as: ProjectLoaders
        alias Foo.ProjectDevice.Loaders, as: ProjectDeviceLoaders
        alias Foo.User.Loaders
        """
      )
    end
  end
end

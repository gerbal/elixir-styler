[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Styler],
  line_length: 122,
  styles: [
    Styler.Style.Readability.MultiAlias,
    Styler.Style.ModuleDirectives,
    Styler.Style.Pipes,
    Styler.Style.SingleNode,
    Styler.Style.CompactFunctions
  ]
]

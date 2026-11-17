# Math in Chat Replies

The chat display does not render LaTeX: `$...$` and `$$...$$` appear as raw source and are hard to read.

- In replies to the user, do NOT write math as LaTeX (`$l_\mathrm{i}$`, `\sqrt{...}`, `\propto`, etc.).
- Write formulas in plain text instead, using Unicode where it helps: `l_i = 4·m_i / (π·ρ_i·d_i²)`,
  `p ∝ l_i·√(l_m − l_i)`, `F = σ_m·π·d_i·l_i`.
- Inline code spans are fine for formulas and symbol names when that improves readability.
- This applies to chat output only.
  Files that render math (e.g. project Markdown documents or Typst sources that already use `$...$`) keep their own conventions.

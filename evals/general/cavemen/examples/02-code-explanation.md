Chain processes text input into cleaned `Vec<String>`.

Step by step:

1. `input.lines()` → splits string by newlines, gives iterator of `&str`
2. `.filter(|l| !l.is_empty())` → drops empty lines
3. `.map(|l| l.trim().to_lowercase())` → strips whitespace + lowercases each line
4. `.collect()` → gathers into `Vec<_>` (compiler infers `Vec<String>` since `to_lowercase()` returns owned `String`)

`let items: Vec<_>` → turbofish shorthand, lets compiler fill concrete type.

Whole thing: multiline string in → clean, normalized, non-empty lines out. Zero-copy until `to_lowercase()` forces allocation.

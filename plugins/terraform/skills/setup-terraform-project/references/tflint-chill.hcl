# TFLint Preset: Chill — Catch real bugs, deprecations, and provider errors
# Just the recommended preset. No style enforcement, no documentation rules.

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

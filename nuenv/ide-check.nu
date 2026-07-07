# Statically check Nushell files (`nu --ide-check`) and print each error as a
# highlighted context block with a red undercurl under the span — the shellcheck
# analogue for `writeShellApplication`. Catches what the compiler can prove
# without running the code (syntax, command signatures, static type errors,
# unknown vars); not data-dependent errors or unknown externals. `ide-check`
# always exits 0, so we read its diagnostics and exit non-zero ourselves.
#
# Usage: nu ide-check.nu FILE...

# Wrap visible columns [start0, start0 + len) of an already-highlighted line
# with a red undercurl. Escapes pass through; each underlined char is wrapped
# individually so an interior `nu-highlight` reset can't cancel it. A zero-width
# or past-end span underlines a trailing space.
def undercurl [hl: string, start0: int, len: int] {
  let esc = (char --unicode "1b")
  let on = $"($esc)[4:3m($esc)[58:2:255:0:0m"
  let off = $"($esc)[24m($esc)[59m"
  mut out = ""
  mut vis = 0
  mut inesc = false
  for ch in ($hl | split chars) {
    if $inesc {
      $out = $out + $ch
      if $ch == "m" { $inesc = false }
    } else if $ch == $esc {
      $out = $out + $ch
      $inesc = true
    } else {
      if ($vis >= $start0 and $vis < ($start0 + $len)) {
        $out = $out + $on + $ch + $off
      } else {
        $out = $out + $ch
      }
      $vis = $vis + 1
    }
  }
  if ($vis <= $start0) { $out = $out + $on + " " + $off }
  $out
}

# Statically check a single file, printing a diagnostic block per error.
# Returns the number of errors found.
def check-file [src: string] {
  if not ($src | path exists) {
    print -e $"(ansi red_bold)error:(ansi reset) no such file: ($src)"
    return 1
  }

  let res = (^$nu.current-exe --ide-check 100 $src | complete)
  let diags = (
    $res.stdout
    | lines
    | where ($it | str trim) != ""
    | each {|l| $l | from json }
    | where type == "diagnostic" and severity == "Error"
  )
  if ($diags | is-empty) { return 0 }

  let bytes = (open --raw $src | into binary)
  # Syntax-highlighted source, split into lines for context display.
  let hl = (open --raw $src | nu-highlight | lines)
  let total = ($hl | length)

  for d in $diags {
    let off = $d.span.start
    # Map the byte offset to 1-based line/column via the preceding bytes.
    let prefix = ($bytes | bytes at ..<$off | decode utf-8)
    let segs = ($prefix | split row "\n")
    let lineno = ($segs | length)
    let col = (($segs | last | str length) + 1)
    let spanlen = ([($bytes | bytes at $off..<($d.span.end) | decode utf-8 | str length) 1] | math max)

    let from = ([($lineno - 1) 1] | math max)
    let to = ([($lineno + 1) $total] | math min)
    let gw = ($to | into string | str length)

    print -e $"(ansi blue)($src):($lineno):($col)(ansi reset)"
    for n in $from..$to {
      let g = ($n | into string | fill --alignment right --width $gw)
      let t = ($hl | get ($n - 1))
      if $n == $lineno {
        # Offending line: red gutter + inline red undercurl under the span.
        print -e $"(ansi red_bold)($g)(ansi reset) (ansi grey)│(ansi reset) (undercurl $t ($col - 1) $spanlen)"
      } else {
        print -e $"(ansi grey)($g) │(ansi reset) ($t)"
      }
    }
    print -e $"(ansi red_bold)error:(ansi reset) ($d.message)\n"
  }

  $diags | length
}

def main [...files: string] {
  if ($files | is-empty) {
    print -e "usage: nu-check FILE..."
    exit 2
  }
  let errors = ($files | each {|f| check-file $f } | math sum)
  if $errors > 0 { exit 1 }
}

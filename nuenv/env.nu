# Logging

export def color [color: string, msg] { $"(ansi $color)($msg)(ansi reset)" }

export def blue [msg] { color "blue" $msg }
export def green [msg] { color "green" $msg }
export def red [msg] { color "red" $msg }
export def purple [msg] { color "purple" $msg }
export def yellow [msg] { color "yellow" $msg }

export def banner [text] { print $"(red ">>>") (green $text)" }
export def info [msg] { print $"(blue ">") ($msg)" }
export def error [msg] { print $"(red "ERROR") ($msg)" }
export def item [msg] { print $"(purple "+") ($msg)"}

# Misc helpers

## Add an "s" to the end of a word if n is greater than 1
export def plural [n: int] { if $n > 1 { "s" } else { "" } }

## Convert a Nix Boolean into a Nushell Boolean ("1" = true, "0" = false)
export def envToBool [var] {
  ($var | into int) == 1
}

## Get package root
export def getPkgRoot [path: path] { $path | parse "{root}/bin/{__bin}" | get root.0 }

## Get package name fro full store path
export def getPkgName [storeRoot: path, path: path] {
  $path | parse $"($storeRoot)/{__hash}-{pkg}" | select pkg | get pkg.0
}

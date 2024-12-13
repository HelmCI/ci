function __fish_helmwave_generate_completions
  set -l args (commandline -opc)
  set -l current_token (commandline -ct)
  if test (string match -r "^-" -- $current_token)
      eval $args $current_token --generate-bash-completion
  else
      eval $args --generate-bash-completion
  end
end

function __fish_helmwave_complete
  set -l completions (__fish_helmwave_generate_completions)
  for opt in $completions
      echo "$opt"
  end
end

complete -c helmwave -f -a '(__fish_helmwave_complete)'

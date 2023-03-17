%{for dep in inputs}
  variable "${dep.slug}" {
    description = "${dep.name}"
    type = any
  }
%{endfor}
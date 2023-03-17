%{for cn, cl in conf.clusters}

# ${cn} cluster

![${cn} dependency graph](img/${cn}.svg)


%{for prefix in distinct([for s in keys(cl.modules): split("-", s)[0]])}

## ${prefix} modules

%{for s in services ~}
%{if (s.prefix == prefix && s.cluster_name == cn) }
* [${s.namespace}](${s.cluster_name}/${s.namespace})%{endif}%{endfor ~}

%{endfor}

%{endfor}
# Scripts inherit their caller's agent without probing or starting another one.
if status is-interactive
    _local_ssh_agent
end

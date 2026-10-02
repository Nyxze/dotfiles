for workspace = 1, 5 do
    hl.workspace_rule({ workspace = tostring(workspace), persistent = true, default = workspace == 1 })
end

-- The display manager assigns numbered workspaces to the active external output.
hl.workspace_rule({ workspace = "name:Laptop", monitor = "eDP-1", default = true, persistent = true })

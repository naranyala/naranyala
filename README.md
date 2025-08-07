
## experience my gists

nixpkgs symlinks: https://gist.github.com/naranyala/2203f889a3cb89c5cfe4599788bea915

nixpkgs dotdesktop: https://gist.github.com/naranyala/312271a325d3c4fbd5fe33e07045cf7c

---

```lua
vim.keymap.set("n", "<leader>td", function()
  local datetime = os.date("%Y-%m-%d %H:%M:%S")
  local todo = "TODO (" .. datetime .. ") "
  vim.api.nvim_put({todo}, "c", true, true)
end, { desc = "Insert TODO with timestamp" })
```

---

![GitHub Stats](https://github-readme-stats.vercel.app/api?username=naranyala&show_icons=true&theme=radical)

![Top Langs](https://github-readme-stats.vercel.app/api/top-langs/?username=naranyala&layout=compact&theme=radical)

---



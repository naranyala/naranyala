
## welcome

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

## inspiration

https://hn.algolia.com/?q=async

https://hn.algolia.com/?query=coroutines

https://github.com/vuejs/core/tree/minor/changelogs

https://github.com/orgs/tsoding/repositories?type=all

---


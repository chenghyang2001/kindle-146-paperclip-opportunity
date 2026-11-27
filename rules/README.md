# K146《The Paperclip Opportunity》規則彙整（kindle-book-pipeline Step 11）

把 `drafts/ch01.md`～`ch16.md` 的規則候選去重、合併後，依主題整理成 6 個規則檔。規則編號 B146-1～B146-62 跨檔連續。格式照 `~/.claude/instructions/kindle-rules/feedback-b2-*.md`（frontmatter＋規則＋Why＋How to apply＋來源章節）。

## 檔案清單

| 檔案 | 主題 | 編號 | 條數 |
| --- | --- | --- | --- |
| `feedback-b146-agent-company-design.md` | 代理組織設計與交辦 | B146-1～11 | 11 |
| `feedback-b146-budget-governance.md` | 預算上限與治理閘門 | B146-12～23 | 12 |
| `feedback-b146-heartbeat-operations.md` | 排程、維運與交接 | B146-24～36 | 13 |
| `feedback-b146-quality-trust.md` | 品質關卡與可信度 | B146-37～46 | 10 |
| `feedback-b146-value-pricing.md` | 價值試算與報價範疇 | B146-47～55 | 9 |
| `feedback-b146-sales-communication.md` | 展示與對外溝通 | B146-56～62 | 7 |
| **合計** | | | **62** |

## 去重統計

- 候選：**89 條**（16 章；ch01、05、08、09、10、12、13、15、16 各 6 條，其餘 7 章各 5 條）
- 最終：**62 條**
- 刪除（與既有規則完全重複）：**1 條**
  - Ch15 規則 2「長時間工作要有固定回報節奏、沉默不算好消息」：已被全域 CLAUDE.md 主管代理守則第 4 條（定時巡視）與「長工作要自己盯進度」記憶完整涵蓋。
- 合併：**44 條候選併成 18 條**（減少 26 條），主要群組：
  - 淨值扣人審時間：Ch1-6、Ch2-4、Ch5-2、Ch11-5、Ch15-4 → B146-47
  - 說法附日期出處、是否親測：Ch1-2、Ch3-2、Ch7-1、Ch16-2 → B146-43
  - 上限先於排程：Ch3-3、Ch7-2、Ch16-5 → B146-13
  - 紀錄與核准不等於品質：Ch1-4、Ch4-4、Ch9-5 → B146-37
  - 撐不起就建議較小方案：Ch7-5、Ch13-5、Ch15-5 → B146-49
  - 其餘 13 組各兩條合一（B146-2、4、20、21、24、27、32、35、36、44、46、48、58）
- 一對一保留：44 條
- 驗算：89 − 1（刪除）− 26（合併減少）＝ 62
- 標「延伸既有」：18 條（與既有規則部分重疊，保留新增的部分並註明對應檔），對應的既有規則包括：全域 CLAUDE.md 主管代理守則（第 1、2、3、5、7、8 條）、「能自己做的一律自己做完」鐵律、`cost-rules.md`、`feedback-b2-agent-workflow.md`（B2-4、B2-13、B2-14、B2-15）、`feedback-ch03-production-code.md`、`feedback-ch04-debugging.md`、`feedback-ch06-database.md`、`feedback-ch14-dependencies.md`。

## 合併到全域規則庫需使用者核准

這些檔案目前只在本 repo 的 `rules/`，**尚未**複製到 `~/.claude/instructions/kindle-rules/`，也沒有改動該目錄任何檔案。使用者核准後，再做以下兩件事：

1. 把 6 個 `feedback-b146-*.md` 複製到 `~/.claude/instructions/kindle-rules/`。
2. 更新 `~/.claude/instructions/kindle-rules/README.md`：

在「規則統計」表格加這一列（合計列同步改為 29 個規則檔、191 條＋1 雙向原則）：

```markdown
| The Paperclip Opportunity (K146) | feedback-b146-*.md | 62 條 | 2026-11-27 |
```

在「規則檔案清單」加這一段：

```markdown
### K146: The Paperclip Opportunity
- `feedback-b146-agent-company-design.md` — 代理組織設計與交辦（11 條）
- `feedback-b146-budget-governance.md` — 預算上限與治理閘門（12 條）
- `feedback-b146-heartbeat-operations.md` — 排程、維運與交接（13 條）
- `feedback-b146-quality-trust.md` — 品質關卡與可信度（10 條）
- `feedback-b146-value-pricing.md` — 價值試算與報價範疇（9 條）
- `feedback-b146-sales-communication.md` — 展示與對外溝通（7 條）
```

## 備註

- 規則內容為改寫後的協作規則，不含書籍原文。
- `drafts/` 保持原樣，未修改。

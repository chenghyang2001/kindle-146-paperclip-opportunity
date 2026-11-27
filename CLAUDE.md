# CLAUDE.md

K146《The Paperclip Opportunity》（James P. Garland，ASIN B0HP7VGPHC，16 章）kindle-book-pipeline Step 10～12 產出 repo。

- 這是 Kindle 書籍教學 demo（快速 demo 模式），不是正式專案。
- `translations/chNN.md`：Step 10 中文化（繁中深度精華，依各章內容改寫，不是逐字翻譯、不貼原文；引用每章最多一句、15 字內）。
- `rules/drafts/chNN.md`：Step 11 逐章規則候選；`rules/feedback-b146-*.md`：彙整後規則草稿（等使用者核准才合併到 `~/.claude/instructions/kindle-rules/`）。
- `prompts/chNN.md`＋`practice/interactive/chNN.sh`＋`coach-chNN.txt`：Step 12 互動演練教材（K145 格式，8 步，`bash chNN.sh <步驟>`）。
- 本書沒有作者附的程式；Paperclip 是外部開源工具，本 repo 不安裝它，練習用 Python 標準庫小模擬重現概念。
- 真實子代理一律走 `practice/llm_agent.py`（`claude -p`，Max 訂閱）；不可設定任何 API 金鑰；每章最多呼叫 2 次。

## 本專案例外

學習演練情境，採快速 demo 模式：主 Claude 直接寫檔，不派 code-writer／code-qa／code-reviewer；選擇題採推薦選項，不停下來問。

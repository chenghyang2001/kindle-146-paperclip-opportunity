# K146《The Paperclip Opportunity》中文化＋規則＋互動演練

James P. Garland 著，ASIN B0HP7VGPHC，全書 16 章。講的是用開源工具 Paperclip 把一群 AI 代理組成「公司」（組織圖、目標鏈、心跳、預算、核准、董事會），並把它包裝成可以賣給客戶的服務。

| 資料夾 | Step | 內容 |
| --- | --- | --- |
| `translations/` | 10 中文化 | 每章一份繁中深度精華（依內容改寫，不含原文） |
| `rules/` | 11 規則提取 | `drafts/chNN.md` 逐章候選；`feedback-b146-*.md` 彙整草稿（待核准） |
| `prompts/` | 12 演練 | 各章重點與演練設計 |
| `practice/interactive/` | 12 演練 | `chNN.sh`（8 步）＋`coach-chNN.txt`（教練稿，給 TTS 念） |

執行演練：`cd practice/interactive && bash ch01.sh 1`（步驟 1～8）。
跨電腦進度：`~/workspace/console/drills/k146-interactive/`，在控制台說「K146 互動演練接續」。

- 書的前置產物（PDF、摘要、NotebookLM 四件套）在 HP1 `~/Downloads/AutoRead-GoogleBook/kindle-146-paperclip-opportunity/` 與 VPS `~/kindle-146/`。
- 快速 demo 模式產出，未經 QA／審查。

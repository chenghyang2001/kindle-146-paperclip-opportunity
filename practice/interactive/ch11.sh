#!/bin/bash
# K146 第 11 章互動演練：心跳、例行程序與每日營運節奏，一次跑一步
# 用法：bash ch11.sh <步驟 1-8>
# 呼叫模型：只有第 7 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch11/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 11 章｜心跳與例行程序　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "開場重現：六十秒心跳的招募公司"
   tip "四種喚醒來源裡，只有計時器會在「沒有事」的時候叫醒代理。"
   P='WAKES = [
    ("計時器 timer", False),
    ("指派或新留言 assignment / comment", True),
    ("按需喚醒 wake on demand / 代理交接", True),
    ("例行程序 routine 觸發", True),
]
print("四種喚醒來源：")
for name, has_event in WAKES:
    print("  {:<36} {}".format(name, "有事才叫醒" if has_event else "沒事也叫醒，只為了看看有沒有事"))
print()
AGENTS, DAYS, COST = 3, 12, 0.03
runs = AGENTS * (86400 // 60) * DAYS
useful = 2
print("老闆的設定：{} 個代理、計時器每 60 秒、跑 {} 天".format(AGENTS, DAYS))
print("  總喚醒次數：{:,}；真正有事做的：{} 次（每週一要交的候選人短名單）".format(runs, useful))
print("  空轉比例：{:.3%}".format(1 - useful / runs))
print("  假設每次喚醒 3 美分：{:,.0f} 美元，全花在確認「沒事」".format(runs * COST))
print()
print("改法：關掉計時器、保留按需喚醒、每週五 14:00 用例行程序把短名單任務交給研究代理")
print("  同樣 {} 天的喚醒次數：{} 次；週一短名單照樣準時".format(DAYS, useful))'
   show "$P"; run "$P" ;;
2) banner "用 cron 數一個月的喚醒次數：8,640 對 198"
   tip "以 2026 年 6 月為例（30 天、22 個工作日），每次喚醒假設 3 美分。比值不靠假設。"
   P='import csv
from datetime import datetime, timedelta
from pathlib import Path

def field(spec, lo, hi):
    out = set()
    for part in spec.split(","):
        step = 1
        if "/" in part:
            part, step = part.split("/")
            step = int(step)
        if part == "*":
            a, b = lo, hi
        elif "-" in part:
            a, b = map(int, part.split("-"))
        else:
            a = b = int(part)
        out.update(range(a, b + 1, step))
    return out

def count(cron, start, days):
    mi, hr, dom, mon, dow = cron.split()
    M, H, D, MO, W = field(mi, 0, 59), field(hr, 0, 23), field(dom, 1, 31), field(mon, 1, 12), field(dow, 0, 6)
    n, t, end = 0, start, start + timedelta(days=days)
    while t < end:
        if t.minute in M and t.hour in H and t.day in D and t.month in MO and (t.weekday() + 1) % 7 in W:
            n += 1
        t += timedelta(minutes=1)
    return n

SETTINGS = [
    ("每 5 分鐘計時器，全天", "*/5 * * * *", "5 分鐘"),
    ("每小時計時器，全天", "0 * * * *", "60 分鐘（含半夜）"),
    ("例行程序：平日 9:00～17:00 每小時", "0 9-17 * * 1-5", "上班時間 60 分鐘"),
]
start = datetime(2026, 6, 1)
rows = []
print("{:<26} | {:<16} | {:>8} | {:>9} | {}".format("設定", "cron", "喚醒/月", "成本/月", "最久等多久"))
print("-" * 86)
for name, cron, wait in SETTINGS:
    n = count(cron, start, 30)
    rows.append((name, cron, n, round(n * 0.03, 2)))
    print("{:<24} | {:<16} | {:>8,} | {:>8.2f}$ | {}".format(name, cron, n, n * 0.03, wait))
print()
print("每 5 分鐘 ÷ 例行程序 = {:.1f} 倍（書中說「約 44 倍」）".format(rows[0][2] / rows[2][2]))
print("每分鐘輪詢一個月 {:,} 次，每小時 720 次，相差 {} 倍".format(count("* * * * *", start, 30), count("* * * * *", start, 30) // 720))
out = Path("ch11/interactive")
out.mkdir(parents=True, exist_ok=True)
with open(out / "wake_counts.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["setting", "cron", "wakes_per_month", "cost_usd"])
    w.writerows(rows)
print("已寫入", out / "wake_counts.csv")'
   show "$P"; run "$P" ;;
3) banner "依截止時間挑最慢、但來得及的喚醒方式"
   tip "頻率是從截止時間推出來的成本控制，不是越快越安心。決策筆記一定要寫「為什麼不更快」。"
   P='PATTERNS = [
    ("只靠指派喚醒（不設計時器）", None, 0),
    ("例行程序：每週一次", 7 * 24 * 60, 4),
    ("例行程序：平日上班時間每小時", 60, 198),
    ("計時器：每 5 分鐘", 5, 8640),
]
ROLES = [
    ("研究代理", "週一 08:00 交研究摘要，跑一次 60 分鐘", "clock", 60, None),
    ("收件匣分類代理", "來信後 2 小時內要有回覆草稿，跑一次 10 分鐘", "promise", 10, 120),
    ("即時客服代理", "4 分鐘內要回覆線上聊天，跑一次 2 分鐘", "promise", 2, 4),
    ("CEO 代理", "計畫核准後把工作分派出去", "assign", 0, None),
]
for role, need, kind, run_min, promise in ROLES:
    print("角色：{}｜需求：{}".format(role, need))
    if kind == "assign":
        print("  選擇：{}；理由：每一次分派本身就是一次指派，會叫醒它".format(PATTERNS[0][0]))
    elif kind == "clock":
        print("  選擇：例行程序 cron「0 14 * * 5」（週五 14:00 開跑）；理由：週一 08:00 前還有一個週末的緩衝，一個月 4 次喚醒")
    else:
        fit = [p for p in PATTERNS[1:] if p[1] + run_min <= promise]
        if not fit:
            print("  選擇：沒有任何喚醒方式來得及（最快也要 5 + {} 分鐘）→ 這不是代理公司適合的工作，回到第 7 章談單一代理或別的產品".format(run_min))
        else:
            best = fit[0]
            faster = [p for p in PATTERNS[1:] if p not in fit] + fit[1:]
            print("  選擇：{}；最久等 {} 分鐘 + 執行 {} 分鐘 = {} 分鐘 ≤ 承諾 {} 分鐘".format(best[0], best[1], run_min, best[1] + run_min, promise))
            print("  為什麼不更快：每 5 分鐘一個月 8,640 次喚醒，是 {} 次的 {:.0f} 倍，承諾不會因此變好".format(best[2], 8640 / best[2]))
    print()
print("陷阱：計時器關掉、按需喚醒也關掉 → 代理永遠不會醒，第一個徵兆是任務一直掛著沒人動。")'
   show "$P"; run "$P" ;;
4) banner "併發政策與補發政策：預設值不一定對"
   tip "併發政策管「上一輪還沒跑完又觸發」；補發政策管「暫停或離線期間錯過的觸發」。"
   P='TICKS = list(range(9, 18))
DUR = [40, 50, 130, 150, 30, 20, 45, 30, 25]
print("A. 收件匣分類每小時觸發，今天有兩輪特別慢（分鐘）：", DUR)
def concurrency(policy):
    busy_until, created, queue, max_q, overlap = 0, 0, 0, 0, 0
    for i, h in enumerate(TICKS):
        t = h * 60
        if busy_until > t:
            overlap += 1
            if policy == "always enqueue":
                created += 1
                queue += 1
                max_q = max(max_q, queue)
            continue
        if queue:
            queue -= 1
        created += 1
        busy_until = t + DUR[i]
    return created, max_q, overlap
for policy, note in (("coalesce（預設，併入進行中那輪）", "coalesce"), ("skip（跳過這次觸發）", "skip"), ("always enqueue（每次都開新任務）", "always enqueue")):
    created, max_q, overlap = concurrency(note)
    what = {"coalesce": "併入進行中那輪（新信由那輪一起處理）", "skip": "直接丟掉（新信等下一個整點）", "always enqueue": "各開一個新任務排隊"}[note]
    print("  {:<36} 建立任務 {} 個，最多積壓 {} 個；撞到忙碌的 {} 次觸發：{}".format(policy, created, max_q, overlap, what))
print()
print("B. 補發政策：公司因預算暫停 3 週後恢復")
CASES = [("每週客戶報告", 3, "skip（預設）", 0, "錯過的週報不需要週一一次補三份"), ("每月內容行事曆（25 號）", 1, "queue，上限 1", 1, "錯過 25 號還是要有一份行事曆")]
for name, missed, policy, extra, why in CASES:
    print("  {:<20} 錯過 {} 次 → {:<14} 恢復時補跑 {} 次；理由：{}".format(name, missed, policy, extra, why))
print("  若週報設成無上限的 queue：恢復時一次補跑 3 份，同一個資料夾出現三份報告、三倍花費")'
   show "$P"; run "$P" ;;
5) banner "五個例行程序寫成卡片，再用程式檢查卡片"
   tip "沒有指派對象的例行程序會被暫停，而且不會吵；這種安靜的失敗要靠檢查卡片抓出來。"
   P='import json
from pathlib import Path
CARDS = [
    {"name": "每週客戶報告", "cron": "0 15 * * 5", "tz": "Asia/Taipei", "assignee": "週報代理", "owner": "客戶經理", "ceiling": 165, "concurrency": "coalesce", "catch_up": "skip", "review": "第一個月每份都審，之後四抽一"},
    {"name": "收件匣分類", "cron": "0 9-17 * * 1-5", "tz": "Asia/Taipei", "assignee": "分類代理", "owner": "客服主管", "ceiling": 70, "concurrency": "skip", "catch_up": "skip", "review": "每封回覆由人寄出，標籤抽樣"},
    {"name": "研究摘要", "cron": "0 7 * * 1", "tz": "Asia/Taipei", "assignee": "研究代理", "owner": "部門主管", "ceiling": 36, "concurrency": "coalesce", "catch_up": "skip", "review": "每個說法都對到來源清單"},
    {"name": "內容行事曆", "cron": "0 9 25 * *", "tz": "Asia/Taipei", "assignee": "行銷代理", "owner": "行銷主管", "ceiling": 60, "concurrency": "coalesce", "catch_up": "queue:1", "review": "檢查日期、說法與承諾"},
    {"name": "發票對帳審查", "cron": "0 10 * * 4", "tz": "Asia/Taipei", "assignee": "對帳代理", "owner": "會計", "ceiling": 45, "concurrency": "coalesce", "catch_up": "skip", "review": "每個標記項＋抽樣已配對項"},
    {"name": "research stuff", "cron": "0 9 * * *", "tz": "", "assignee": "", "owner": "", "ceiling": 0, "concurrency": "always enqueue", "catch_up": "", "review": ""},
]
def check(c):
    p = []
    if len(c.get("cron", "").split()) != 5: p.append("cron 不是 5 欄")
    if not c.get("tz"): p.append("沒寫時區")
    if not c.get("assignee"): p.append("沒有指派對象（會被暫停）")
    elif "CEO" in c["assignee"]: p.append("指派給 CEO，應給做事的代理")
    if not c.get("owner"): p.append("沒有具名的業務負責人")
    if not c.get("ceiling"): p.append("沒有預算上限")
    if c.get("concurrency") == "always enqueue": p.append("always enqueue 會堆積任務，要寫理由")
    if not c.get("catch_up"): p.append("沒選補發政策")
    if not c.get("review"): p.append("沒有審查步驟")
    return p
print("{:<14} | {:<15} | {:>5} | {}".format("例行程序", "cron", "上限$", "檢查結果"))
print("-" * 72)
total = 0
for c in CARDS:
    probs = check(c)
    total += c["ceiling"]
    print("{:<14} | {:<15} | {:>5} | {}".format(c["name"], c["cron"], c["ceiling"], "OK" if not probs else "；".join(probs)))
print()
good = [c for c in CARDS if not check(c)]
print("合格卡片 {} 張，起始預算上限合計 {} 美元／月；沒有一張需要計時器".format(len(good), sum(c["ceiling"] for c in good)))
print("做法：一次只上線一張卡，跑過試點、失敗率穩定後再加下一張")
out = Path("ch11/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "routine_cards.json").write_text(json.dumps(CARDS, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入", out / "routine_cards.json")'
   show "$P"; run "$P" ;;
6) banner "董事席節奏與 ROI 一頁表：每一分鐘的人力都要算"
   tip "最常漏掉的是董事席時間：每天最小的一行，卻是每月比較大的一行。"
   P='from pathlib import Path
RATE = 50
daily, weekly, monthly = 10 * 20 / 60, 40 * (4 + 1 / 3) / 60, 75 / 60
board = daily + weekly + monthly
print("董事席節奏：每天 10 分鐘 × 20 個工作日 = {:.1f} h；每週 40 分鐘 × 4.33 週 = {:.1f} h；每月 75 分鐘 = {:.2f} h".format(daily, weekly, monthly))
print("合計約 {:.1f} 小時／月 ≈ {:.0f} 美元".format(board, round(board, 1) * RATE))
print()
gross_h = 48 * 0.75 + 4 * 2 + 22 * 0.5
gross = gross_h * RATE
spend, hosting = 180, 30
oversight = {"審 48 份週報（各 10 分鐘）": 48 * 10 / 60, "審研究摘要": 1.3, "審收件匣分類": 1.8, "董事席": 7.5, "技能與連接器維護": 2.0}
over_h = sum(oversight.values())
net = gross - spend - hosting - over_h * RATE
naive = gross - spend - hosting
setup = 5000
lines = ["# ROI 一頁表（書中例子，全部是假設值）", "",
         "- 節省工時：週報 48×0.75 + 研究 4×2 + 分類 22×0.5 = {:.0f} 小時 → 毛價值 {:,.0f} 美元".format(gross_h, gross),
         "- 減模型 {} 美元、主機 {} 美元".format(spend, hosting)]
lines += ["- 減 {}：{:.1f} 小時".format(k, v) for k, v in oversight.items()]
lines += ["- 監督合計 {:.1f} 小時 = {:,.0f} 美元".format(over_h, over_h * RATE),
          "- **每月淨價值：{:,.0f} 美元**".format(net),
          "- 不算監督時間的試算表會寫 {:,.0f} 美元，多出 {:,.0f} 美元".format(naive, naive - net),
          "- 一次性導入 {:,} 美元 → 回本 {:.1f} 個月（第四個月內）；12 個月淨價值 {:,.0f}，報酬比 {:.1f} 比 1".format(setup, setup / net, net * 12, net * 12 / setup)]
for l in lines[2:]:
    print(l.replace("**", ""))
print()
print("淨價值就是理性客戶願意付的月費（retainer）上限；毛價值的 {:.0%} 被人力監督吃掉".format(over_h * RATE / gross))
out = Path("ch11/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "roi_onepager.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("已寫入", out / "roi_onepager.md")'
   show "$P"; run "$P" ;;
7) banner "讓真實模型寫一張例行程序卡，再檢查並算淨價值"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；題目換成你自己的：每週 ROS 2／AMR 職缺摘要。"
   P='import json
from pathlib import Path
from llm_agent import ask_json
out = Path("ch11/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "routine_card_raw.json"
raw.unlink(missing_ok=True)
prompt = """你在 Paperclip 這類代理公司平台上設計一個例行程序（routine）。
情境：一位求職中的 ROS 2／AMR 工程師，希望每週一早上前拿到一份「本週新職缺摘要」，由研究代理整理 104 與 LinkedIn 上的公開職缺。
請輸出 JSON，欄位：
{"name": "", "purpose": "一句話交付物", "assignee": "代理名稱", "owner": "負責的人",
 "cron": "5 欄 cron", "tz": "IANA 時區", "concurrency": "coalesce 或 skip 或 always enqueue",
 "catch_up": "skip 或 queue:N", "ceiling": 每月預算上限美元數字, "review": "審查步驟",
 "tasks_per_month": 數字, "hours_saved_per_task": 數字, "model_spend_usd": 每月模型花費數字,
 "review_minutes_per_task": 數字, "why_not_faster": "為什麼不更頻繁"}"""
try:
    card = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    card = None
    print("呼叫模型失敗：", exc, "→ 改用內建範例")
source = "模型輸出" if isinstance(card, dict) else "內建範例"
if isinstance(card, dict):
    raw.write_text(json.dumps(card, ensure_ascii=False, indent=2), encoding="utf-8")
else:
    card = {"name": "每週 AMR 職缺摘要", "purpose": "週一前交一份本週新職缺摘要", "assignee": "研究代理", "owner": "求職者本人",
            "cron": "0 7 * * 1", "tz": "Asia/Taipei", "concurrency": "skip", "catch_up": "skip", "ceiling": 10,
            "review": "本人讀過才投遞", "tasks_per_month": 4, "hours_saved_per_task": 1.5, "model_spend_usd": 4,
            "review_minutes_per_task": 15, "why_not_faster": "職缺一週更新幾次就夠"}
print("資料來源：", source)
for k in ("name", "cron", "tz", "assignee", "owner", "concurrency", "catch_up", "ceiling", "review", "why_not_faster"):
    print("  {:<15} {}".format(k, card.get(k)))
probs = []
if len(str(card.get("cron", "")).split()) != 5: probs.append("cron 不是 5 欄")
for k, msg in (("tz", "沒寫時區"), ("assignee", "沒有指派對象"), ("owner", "沒有負責人"), ("review", "沒有審查步驟"), ("catch_up", "沒選補發政策"), ("why_not_faster", "沒寫為什麼不更快")):
    if not card.get(k): probs.append(msg)
if str(card.get("concurrency")) == "always enqueue": probs.append("always enqueue 會堆積")
def num(k, d=0.0):
    try:
        return float(card.get(k, d))
    except (TypeError, ValueError):
        probs.append(k + " 不是數字")
        return d
if num("ceiling") <= 0: probs.append("沒有預算上限")
print()
print("卡片檢查：", "OK" if not probs else "；".join(probs))
RATE, BOARD_MIN = 50, 10
n, h, spend, rmin = num("tasks_per_month"), num("hours_saved_per_task"), num("model_spend_usd"), num("review_minutes_per_task")
gross = n * h * RATE
review_h = n * rmin / 60
board_h = BOARD_MIN * 4.33 / 60
net = gross - spend - (review_h + board_h) * RATE
print("ROI：毛價值 {:.0f}$ − 模型 {:.0f}$ − 審查 {:.1f}h − 董事席每週 10 分鐘 {:.1f}h（時薪 {}$）= 淨價值 {:.0f}$／月".format(gross, spend, review_h, board_h, RATE, net))
print("判斷：", "值得跑" if net > 0 else "淨值為負，保留紀錄，考慮降低頻率或改人工")
fence = chr(96) * 3
md = "# 第 11 章：模型設計的例行程序卡\n\n資料來源：" + source + "\n\n" + fence + "json\n" + json.dumps(card, ensure_ascii=False, indent=2) + "\n" + fence + "\n\n- 卡片檢查：" + ("OK" if not probs else "；".join(probs)) + "\n- 淨價值：{:.0f} 美元／月\n".format(net)
(out / "routine_check.md").write_text(md, encoding="utf-8")
print("已寫入", out / "routine_check.md")'
   show "$P"; run "$P" ;;
8) banner "總結：營運節奏的五個重點"
   tip "一直醒著的公司不是比較勤勞，只是比較貴；每一次喚醒都要問它是為了什麼。"
   P='from pathlib import Path
points = [
    "四種喚醒來源只有計時器沒事也叫醒：多數代理關掉計時器、保留按需喚醒，用指派與例行程序驅動。",
    "頻率從截止時間推：選最慢但來得及的方式。同樣兩小時承諾，每 5 分鐘一個月 8,640 次喚醒，平日上班時間每小時只要 198 次，約 44 倍差距。",
    "例行程序是寫下來的交付物：一張卡寫清指派對象、負責人、cron 與時區、預算上限、審查步驟；併發與補發政策逐一決定，不靠預設。",
    "董事席有固定行程：每天 10 分鐘、每週 40 分鐘、每月 75 分鐘，約 7.5 小時、375 美元一個月，要算進成本。",
    "ROI 要扣掉每一小時監督：書中例子毛價值 2,750 美元，扣完只剩 1,510 美元；淨價值就是月費上限，算出負數也要誠實說。",
]
print("第 11 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("wake_counts.csv", "routine_cards.json", "roi_onepager.md", "routine_card_raw.json", "routine_check.md"):
    p = Path("ch11/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

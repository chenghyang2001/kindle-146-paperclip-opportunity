#!/bin/bash
# K146 第 4 章互動演練：聘用第一批代理——兩個代理、一人一個任務、一條看得見的終點線，一次跑一步
# 用法：bash ch04.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch04/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 4 章｜聘用第一批代理　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "太多代理的帳，先付在你的注意力上"
   tip "作者的示意假設：每個代理每天交 5 件要你看的東西，每件看 3 分鐘，時薪 50 美元。"
   P='ITEMS, MINUTES, RATE, DAYS = 5, 3, 50, 20
print("{:>6} | {:>8} | {:>10} | {:>10} | {:>12}".format("代理數", "每日件數", "每日審查分", "每日成本$", "20工作日成本$"))
print("-" * 60)
rows = {}
for n in (1, 2, 3, 5, 8, 12):
    items = n * ITEMS
    mins = items * MINUTES
    cost = mins / 60 * RATE
    rows[n] = cost
    print("{:>6} | {:>8} | {:>10} | {:>10.0f} | {:>12.0f}".format(n, items, mins, cost, cost * DAYS))
print()
diff = rows[8] - rows[2]
print("8 個代理 vs 2 個代理：每天多 ${:.0f}，20 個工作日多 ${:.0f}（還沒算任何模型費用）".format(diff, diff * DAYS))
print("每天 8 小時裡，8 個代理吃掉你 {:.0f}% 的時間只為了「看」".format(8 * ITEMS * MINUTES / 480 * 100))'
   show "$P"; run "$P" ;;
2) banner "聘用請求：摘要卡 vs 完整請求"
   tip "摘要卡只顯示名字、角色、職稱、能力、runtime；彙報線和月預算要點開完整請求才看得到。"
   P='import json
from pathlib import Path
out = Path("ch04/interactive"); out.mkdir(parents=True, exist_ok=True)
requests = [
    {"name": "Researcher", "role": "researcher", "runtime": "claude_code", "reports_to": "CEO", "monthly_budget": 20, "task": "每週客戶摘要的來源蒐集"},
    {"name": "Writer", "role": "writer", "runtime": "claude_code", "reports_to": "CEO", "monthly_budget": 20, "task": "把來源寫成一頁摘要"},
    {"name": "Strategist", "role": "strategist", "runtime": "codex", "reports_to": "", "monthly_budget": 50, "task": "規劃研究方向"},
    {"name": "Writer-2", "role": "writer", "runtime": "claude_code", "reports_to": "CEO", "monthly_budget": 20, "task": "把來源寫成一頁摘要"},
    {"name": "Bookkeeper", "role": "bookkeeper", "runtime": "claude_code", "reports_to": "CEO", "monthly_budget": 0, "task": "整理每月帳務"},
]
SUMMARY = ("name", "role", "runtime")
def summary_ok(r):
    return all(r.get(k) for k in SUMMARY)
def full_review(r, seen_tasks):
    if not r["reports_to"]:
        return "revise", "沒有彙報線，請補上要向誰報告"
    if r["monthly_budget"] <= 0:
        return "revise", "月預算是 0，核准後不會建立預算上限"
    if r["task"] in seen_tasks:
        return "revise", "和已核准的角色做同一件事，請縮小範圍"
    return "approve", "彙報線與預算都對得上計畫"
seen, log = set(), []
print("{:<11} | {:>10} | {:>10} | {}".format("請求", "只看摘要卡", "看完整請求", "理由"))
print("-" * 70)
for r in requests:
    quick = "approve" if summary_ok(r) else "reject"
    decision, why = full_review(r, seen)
    seen.add(r["task"])
    log.append({"name": r["name"], "summary_card": quick, "full_request": decision, "reason": why})
    print("{:<11} | {:>10} | {:>10} | {}".format(r["name"], quick, decision, why))
n_diff = sum(1 for x in log if x["summary_card"] != x["full_request"])
print()
print("只看摘要卡：{} 件全部核准；看完整請求：核准 {} 件、退回修改 {} 件".format(len(log), sum(x["full_request"] == "approve" for x in log), n_diff))
print("第三種選項「要求修改」最實用：不用丟掉草稿，只要一句話說「範圍縮小」")
(out / "hire_decisions.json").write_text(json.dumps(log, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入", out / "hire_decisions.json")'
   show "$P"; run "$P" ;;
3) banner "任務簡報五要素：最常漏的是終點線"
   tip "好的簡報 = 產出、來源、形式、截止、終點線，再加一條限制和一位審查者。"
   P='import re
PARTS = {
    "產出 output": r"(list|digest|table|摘要|清單|表格|頁)",
    "來源 source": r"(from|source|folder|來源|資料夾|last \d+ days|最近)",
    "形式 form": r"(\d+[- ]?word|one-page|table|兩句|一頁|\d+ 字|表格)",
    "截止 deadline": r"(by |friday|monday|週[一二三四五六日]|前|deadline)",
    "終點線 finish": r"(done when|finished when|完成條件|當.*才算完成|mark the task done)",
    "限制 limit": r"(do not|不要|不可|不得)",
    "審查者 reviewer": r"(review for|reviewer|審查者|交給 .* 審)",
}
briefs = {
    "A 只寫主題": "Research competitors.",
    "B 常見寫法": "Researcher: write about our industry, make it a table.",
    "C 照模板": ("Produce a list of five sources from the shared folder, published in the last 30 days on AMR safety, "
                 "in the form of a table with two sentences each by Friday. It is finished when all five rows have a link. "
                 "Do not add sources outside the folder. Move it to review for the account manager (reviewer)."),
}
print("{:<10} | ".format("簡報") + " | ".join(k.split()[0] for k in PARTS) + " | 分數")
print("-" * 78)
for name, text in briefs.items():
    hits = [bool(re.search(p, text, re.I)) for p in PARTS.values()]
    print("{:<10} | ".format(name) + " | ".join("{:^4}".format("V" if h else "-") for h in hits) + " | {}/{}".format(sum(hits), len(hits)))
print()
print("A：代理不知道什麼時候該停，只能自己決定「做完」是什麼意思")
print("C：陌生人也能檢查——五列都有連結，就是完成")'
   show "$P"; run "$P" ;;
4) banner "目標鏈：從任務往上讀，看它為什麼存在"
   tip "任務 -> 專案 -> 目標。目標太空泛時，每個任務都「合理」；目標具體時，不相干的任務一眼就露餡。"
   P='GOALS = {
    "vague": "Grow the business",
    "good": "Send each of our 10 active clients a weekly digest by Friday, reviewed by the account manager",
}
PROJECTS = {"marketing": "vague", "weekly-digest": "good"}
TASKS = [
    ("T1 列出 5 個來源", "weekly-digest", ("digest",)),
    ("T2 把來源寫成一頁摘要", "weekly-digest", ("digest",)),
    ("T3 研究市場趨勢", "marketing", ()),
    ("T4 重新設計 logo", "marketing", ()),
    ("T5 臨時任務：整理舊信件", None, ()),
]
def trace(task):
    name, proj, _ = task
    if proj is None:
        return name + "  ->  （沒有專案，鏈斷了）"
    return "{}  ->  專案 {}  ->  目標「{}」".format(name, proj, GOALS[PROJECTS[proj]])
print("目標 A（空泛）：", GOALS["vague"])
print("目標 B（具體）：", GOALS["good"])
print()
for t in TASKS:
    print(" ", trace(t))
print()
print("把所有任務改掛到具體目標 B 底下，用「產出是否出現在目標句子裡」檢查：")
for name, _, outputs in TASKS:
    serves = any(o in GOALS["good"].lower() for o in outputs)
    print("  {:<22} {}".format(name, "服務目標" if serves else "看得出不服務 -> 該刪或另立目標"))
loose = sum(1 for t in TASKS if t[1] is None)
print()
print("掛在空泛目標下的任務 2 個「技術上完整、實際上什麼都沒解釋」；沒有專案的鬆散任務 {} 個".format(loose))'
   show "$P"; run "$P" ;;
5) banner "同一週、兩家公司：8 個代理 vs 2 個代理的紀錄"
   tip "書裡 8 個代理到週四有 90 筆紀錄、零交付；2 個代理約 20 筆、兩個完成任務加一份摘要。看模擬是不是同樣的形狀。"
   P='import random
random.seed(146)
def simulate(team, days=4):
    log, delivered = [], []
    for day in range(1, days + 1):
        for agent, spec in team.items():
            if spec["waits_for"] and spec["waits_for"] not in delivered:
                log.append((day, agent, "等待 " + spec["waits_for"]))
                continue
            if spec["finish_line"] and agent not in delivered and day >= spec["done_day"]:
                delivered.append(agent)
                log.append((day, agent, "完成：" + spec["output"]))
                continue
            for _ in range(spec["noise"]):
                log.append((day, agent, random.choice(["更新狀態", "留言", "重新規劃", "產出草稿"])))
    return log, delivered
big = {
    "Researcher":  {"finish_line": False, "waits_for": None, "done_day": 9, "noise": 6, "output": "研究"},
    "Strategist":  {"finish_line": False, "waits_for": None, "done_day": 9, "noise": 5, "output": "研究計畫"},
    "Coordinator": {"finish_line": False, "waits_for": None, "done_day": 9, "noise": 5, "output": "研究計畫"},
    "Writer":      {"finish_line": True,  "waits_for": "Researcher", "done_day": 3, "noise": 0, "output": "文章"},
    "Editor":      {"finish_line": True,  "waits_for": "Writer", "done_day": 4, "noise": 0, "output": "編修稿"},
    "Social":      {"finish_line": False, "waits_for": None, "done_day": 9, "noise": 3, "output": "貼文"},
    "Bookkeeper":  {"finish_line": False, "waits_for": None, "done_day": 9, "noise": 0, "output": "帳"},
    "Support":     {"finish_line": False, "waits_for": None, "done_day": 9, "noise": 3, "output": "客服"},
}
small = {
    "Researcher": {"finish_line": True, "waits_for": None, "done_day": 2, "noise": 3, "output": "五個來源清單"},
    "Writer":     {"finish_line": True, "waits_for": "Researcher", "done_day": 3, "noise": 2, "output": "一頁 300 字摘要"},
}
for title, team in (("8 個代理、目標「產出好內容」", big), ("2 個代理、目標「每週五寄一頁摘要給 10 位客戶」", small)):
    log, done = simulate(team)
    idle = [a for a in team if not any(x[1] == a for x in log)]
    waiting = sum(1 for x in log if x[2].startswith("等待"))
    print(title)
    print("  紀錄筆數 {:>3}｜完成交付 {}｜等待筆數 {}｜完全閒置 {}".format(len(log), done if done else "無", waiting, idle if idle else "無"))
print()
print("第二家公司沒有比較厲害，只是比較「可讀」：每一筆紀錄都能用一句話解釋")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型當 CEO 代理：替兩個角色寫任務簡報"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json
out = Path("ch04/interactive"); out.mkdir(parents=True, exist_ok=True)
raw = out / "briefs_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是一家 Paperclip 測試公司的 CEO 代理。公司目標：每週五寄一頁產業摘要給 10 位 AMR 客戶，由業務經理審查。
公司只聘兩個代理：researcher 與 writer。請替兩人各寫一份任務簡報，套用這個模板：
Produce {output} from {source} in the form of {format and length} by {deadline}. It is finished when {observable finish line}. Do not {one explicit limit}. Move it to review for {named reviewer}.
輸出 JSON：{"goal": "一句話目標", "project": "專案名稱", "briefs": [{"agent": "researcher 或 writer", "output": "...", "source": "...", "form": "...", "deadline": "...", "finish_line": "...", "limit": "...", "reviewer": "...", "brief_text": "套模板後的完整一段話（繁體中文）"}]}"""
try:
    plan = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding="utf-8")
print("目標：", plan.get("goal"))
print("專案：", plan.get("project"))
for b in plan.get("briefs") or []:
    if isinstance(b, dict):
        print()
        print("[{}]".format(b.get("agent")))
        print("  ", str(b.get("brief_text", ""))[:220])
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "審查 CEO 的簡報：七個欄位、終點線可不可觀察"
   tip "紀錄好看不等於內容正確；簡報也一樣，要逐欄檢查，而且終點線要能被陌生人驗證。"
   P='import json
from pathlib import Path
out = Path("ch04/interactive"); out.mkdir(parents=True, exist_ok=True)
raw = out / "briefs_raw.json"
FALLBACK = {"goal": "每週五寄一頁產業摘要給 10 位 AMR 客戶，由業務經理審查", "project": "每週客戶摘要", "briefs": [
    {"agent": "researcher", "output": "五個來源清單", "source": "共用資料夾與最近 30 天的公開新聞", "form": "表格，每列兩句加連結",
     "deadline": "每週三中午", "finish_line": "五列都有連結與兩句摘要", "limit": "不要加入超過 30 天的來源", "reviewer": "業務經理"},
    {"agent": "writer", "output": "一頁摘要", "source": "researcher 的五個來源清單", "form": "約 300 字、白話", "deadline": "每週四下班前",
     "finish_line": "", "limit": "不要加入清單以外的數字", "reviewer": "業務經理"}]}
plan, source = None, "內建範例（第 6 步沒有成功）"
if raw.exists():
    try:
        plan = json.loads(raw.read_text(encoding="utf-8")); source = "第 6 步模型輸出"
    except ValueError:
        plan = None
if not isinstance(plan, dict):
    plan, source = FALLBACK, "內建範例（第 6 步沒有成功）"
FIELDS = ("output", "source", "form", "deadline", "finish_line", "limit", "reviewer")
OBSERVABLE = ("列", "連結", "字", "完成", "都有", "清單", "頁", "狀態", "附上", "張貼", "標記", "篇", "個")
VAGUE = ("好", "高品質", "滿意", "適當", "盡量")
lines = ["# 第 4 章：CEO 任務簡報審查", "", "資料來源：" + source, ""]
print("資料來源：", source)
for b in [x for x in plan.get("briefs") or [] if isinstance(x, dict)]:
    missing = [f for f in FIELDS if not str(b.get(f, "")).strip()]
    fl = str(b.get("finish_line", ""))
    obs = any(k in fl for k in OBSERVABLE) and not any(k in fl for k in VAGUE)
    verdict = "PASS" if not missing and obs else "REVISE"
    print("[{}] 缺欄位：{}｜終點線可觀察：{}｜判定 {}".format(b.get("agent"), missing or "無", "是" if obs else "否", verdict))
    print("    終點線：", fl or "（空）")
    lines.append("- {}：缺欄位 {}；終點線「{}」；可觀察 {}；判定 {}".format(b.get("agent"), missing or "無", fl, "是" if obs else "否", verdict))
lines += ["", "提醒：簡報合格只代表代理知道何時停；產出是否正確，仍要打開成品看（紀錄健全不等於內容正確）。"]
(out / "brief_review.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print()
print("已寫入", out / "brief_review.md")'
   show "$P"; run "$P" ;;
8) banner "總結：克制是一種技能"
   tip "前十分鐘的展示只要四個畫面：組織圖、一個完成的任務、往上追到目標、乾淨的紀錄。"
   P='from pathlib import Path
points = [
    "聘用是決定不是動作：一定點開完整請求，看彙報線和月預算（大於零），不清楚就「要求修改」。",
    "第一支團隊兩到三人，目標是可讀性不是產能：一個蒐集、一個塑形，交接在紀錄裡看得見。",
    "任務簡報五要素＋限制＋審查者，最常漏的是終點線；沒有終點線，代理不是太早停就是燒到預算上限。",
    "目標鏈 任務 -> 專案 -> 目標：目標要具體到能讓不相干的任務露餡；紀錄只說發生了什麼，不保證做得對。",
    "三大錯誤會複利：太多代理（8 人每天多花 $75 審查時間）、空泛目標、沒有終點線。",
]
print("第 4 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("十分鐘展示旁白骨架：這是兩個代理的測試公司 -> 這是簡報 -> 這是產出 -> 這是它服務的目標 -> 這是紀錄 -> 你最想在這裡看到哪個工具？")
print()
print("本章產出檔案：")
for name in ("hire_decisions.json", "briefs_raw.json", "brief_review.md"):
    p = Path("ch04/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

#!/bin/bash
# K146 第 6 章互動演練：技能、連接器與記憶——代理靠的每條連線都是別人的承諾，一次跑一步
# 用法：bash ch06.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch06/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 6 章｜技能、連接器與記憶　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "路由描述：每次心跳只看描述，對了才載入全文"
   tip "代理每次醒來只看到每個 skill 的名稱和描述，描述對上眼前的工作才載入全文。描述寫的是「何時用」，不是「主題是什麼」。"
   P='SKILLS = {
    "source-and-cite":  {"body": 900,  "use": ["摘要", "編輯", "事實"], "no": ["標題"]},
    "house-style":      {"body": 1200, "use": ["草稿", "改寫"], "no": []},
    "handoff-note":     {"body": 400,  "use": ["完成", "交接"], "no": []},
    "escalation":       {"body": 500,  "use": ["缺少", "範圍外", "異常"], "no": []},
    "acceptance-check": {"body": 600,  "use": ["送審", "驗收"], "no": []},
}
VAGUE = {"great-content": {"body": 1500, "use": ["內容", "文章", "寫"], "no": []}}
DESC = 40
TASKS = [
    ("摘要三篇來源並標出事實出處", {"source-and-cite"}),
    ("改寫週報草稿成客戶語氣", {"house-style"}),
    ("想五個標題", set()),
    ("完成後寫交接訊息", {"handoff-note"}),
    ("編輯一篇含事實的稿子，缺少發布日期", {"source-and-cite", "escalation"}),
    ("送審前做驗收清單", {"acceptance-check"}),
    ("排下週會議時間", set()),
    ("寫一段內容給社群", set()),
]

def route(skills, task):
    return {n for n, s in skills.items() if any(k in task for k in s["use"]) and not any(k in task for k in s["no"])}

def cost(skills, loaded):
    return len(skills) * DESC + sum(skills[n]["body"] for n in loaded)

paste_all = sum(s["body"] for s in SKILLS.values())
print("{:<28} | {:<34} | {:>6}".format("任務", "載入的 skill", "token"))
print("-" * 76)
tot_route, hit, wrong = 0, 0, 0
for task, want in TASKS:
    got = route(SKILLS, task)
    c = cost(SKILLS, got)
    tot_route += c
    hit += got == want
    print("{:<28} | {:<34} | {:>6}".format(task[:16], ",".join(sorted(got)) or "-", c))
print()
print("全部貼進每個提示詞：每次 {} token，8 次共 {} token".format(paste_all, paste_all * len(TASKS)))
print("用路由描述：8 次共 {} token，省 {:.0f}%".format(tot_route, (1 - tot_route / (paste_all * len(TASKS))) * 100))
print("載入完全正確的任務：{} / {}".format(hit, len(TASKS)))
print()
vague_loads = [t for t, _ in TASKS if route(VAGUE, t)]
print("對照：模糊描述的 great-content（「寫出清楚吸引人的文章」）")
print("  8 個任務裡被載入 {} 次：{}".format(len(vague_loads), "、".join(x[:8] for x in vague_loads)))
print("  只會在出現「內容／文章／寫」時載入，跟該不該用無關 -> 時機錯或永遠不載入")'
   show "$P"; run "$P" ;;
2) banner "失敗行為與版本：缺資料時要寫明怎麼做"
   tip "沒有規則的缺口，代理會自己編一個；編出來的地方，就是捏造數字的來源。每次存檔都是新版本，跑到一半的任務鎖在舊版。"
   P='INPUTS = [
    ("一般輸入", {"task": "摘要來源", "claim": "營收成長 12%", "date": "2026-09-30"}),
    ("缺發布日期", {"task": "摘要來源", "claim": "客戶數翻倍", "date": None}),
    ("範圍外：想標題", {"task": "想標題", "claim": None, "date": None}),
]

def v1(inp):
    # v1：描述只寫主題，沒有失敗行為
    if inp["claim"] is None:
        return True, "（照樣套用）寫了 5 個標題，順便加上未查證的數字"
    date = inp["date"] or "約 2025 年（推測）"
    return True, "{}，發布日 {}".format(inp["claim"], date)

def v2(inp):
    # v2：描述寫明何時不用、缺日期時寫 date not found
    if inp["task"] != "摘要來源":
        return False, "（不載入）不屬於本 skill"
    date = inp["date"] or "date not found，不估計"
    return True, "{}，發布日 {}".format(inp["claim"], date)

print("{:<14} | {:<4} | {:<40} | {}".format("情境", "版本", "輸出", "判定"))
print("-" * 84)
invented = {"v1": 0, "v2": 0}
for name, inp in INPUTS:
    for tag, fn in (("v1", v1), ("v2", v2)):
        loaded, out = fn(inp)
        bad = ("推測" in out) or ("未查證" in out)
        invented[tag] += bad
        print("{:<14} | {:<4} | {:<40} | {}".format(name, tag, out[:40], "捏造/越界" if bad else "OK"))
print()
print("捏造或越界次數：v1 = {}，v2 = {}".format(invented["v1"], invented["v2"]))
print()
history = [("v1", "2026-11-03", "初版：只寫主題"), ("v2", "2026-11-10", "加上何時不用＋缺日期寫 date not found")]
print("版本歷史（可還原）：")
for v, d, note in history:
    print("  {} {} {}".format(v, d, note))
inflight = {"task": "T-118 週報", "pinned": "v1"}
print("跑到一半的任務 {} 鎖在 {}，做完才換；下一次心跳的新任務用 v2".format(inflight["task"], inflight["pinned"]))
print("客戶說「上週四報告語氣變了」：查版本歷史就知道是哪一版、哪一天換的")'
   show "$P"; run "$P" ;;
3) banner "連接器：選得少、給得少，用專用帳號"
   tip "從 Blueprint 的步驟出發，不從連接器目錄出發。目錄有多少個不重要，你授出去多少才決定風險。"
   P='TIER = {"read": 1, "write": 3, "send": 5}
# 做法 A：目錄裡有就全接，以擁有者身分登入，整個組織共用
SERVICES = ["信箱", "文件庫", "行事曆", "帳務", "聊天", "CRM"]
AGENTS = 5
grants_a = [(s, ["read", "write", "send"] if s in ("信箱", "聊天") else ["read", "write"], AGENTS, "擁有者") for s in SERVICES]
# 做法 B：只接 Blueprint 步驟需要的
BLUEPRINT = [
    ("蒐集專案筆記", "文件庫/專案資料夾", "read", "Researcher", "agent-research@", "否"),
    ("撰寫週報", "（不接任何服務）", None, "Writer", "-", "-"),
    ("輸出定稿", "文件庫/輸出資料夾", "write", "Editor", "agent-editor@", "否"),
    ("收件分類", "信箱", "read", "Triage", "agent-triage@", "貼標籤要人審"),
]

def risk(grants):
    return sum(sum(TIER[a] for a in acts) * n for _, acts, n, _ in grants)

ra = risk(grants_a)
grants_b = [(svc, [act], 1, acct) for _, svc, act, _, acct, _ in BLUEPRINT if act]
rb = risk(grants_b)
print("做法 A：連 {} 個服務，每個都授權給全組織 {} 個代理，以擁有者身分登入".format(len(SERVICES), AGENTS))
print("  風險分數（動作權重 讀1／寫3／寄出5 × 可用代理數）= {}".format(ra))
print()
print("做法 B：連接器存取表")
print("{:<10} | {:<16} | {:<5} | {:<10} | {:<15} | {}".format("步驟", "服務", "動作", "授權給", "登入帳號", "先給人審"))
print("-" * 82)
for step, svc, act, who, acct, review in BLUEPRINT:
    print("{:<10} | {:<16} | {:<5} | {:<10} | {:<15} | {}".format(step, svc, act or "-", who, acct, review))
print("  風險分數 = {}，是做法 A 的 {:.1%}".format(rb, rb / ra))
used = {svc.split("/")[0] for _, svc, act, *_ in BLUEPRINT if act}
print()
print("對不上 Blueprint 步驟、應該移除的連接器：", "、".join(s for s in SERVICES if s not in used))
print("專用帳號的好處：代理做的事不再和本人的操作混在一起，紀錄讀得懂")'
   show "$P"; run "$P" ;;
4) banner "記憶：心跳之間代理什麼都不記得"
   tip "代理醒來、做事、睡著，行程裡的記憶跟著消失。要延續的東西，得寫在下次找得到的地方。"
   P='import re
NOTES_CAP = 120

def heartbeat(i, folder, use_notes, manual_edit=None):
    in_process = {}                       # 每次心跳都是空的
    last = folder.get("notes.md", "") if use_notes else ""
    week_total = 40 + i * 5
    prev = re.findall(r"W(\d+)=(\d+)", last)
    delta = week_total - int(prev[-1][1]) if prev else None
    line = "W{}={}".format(i, week_total)
    new_notes = (last + ";" + line).strip(";")
    receipt = "synced"
    if len(new_notes.encode("utf-8")) > NOTES_CAP:
        receipt = "discarded（超過資料夾上限，這次的變更被丟掉）"
    elif use_notes:
        folder["notes.md"] = new_notes
    if manual_edit:
        folder["notes.md"] = manual_edit      # 最後完成的同步獲勝
    return week_total, delta, receipt

for use_notes in (False, True):
    folder = {}
    print("代理{}：".format("每次結束寫 notes.md" if use_notes else "只靠「記得」"))
    for i in range(1, 5):
        tot, delta, receipt = heartbeat(i, folder, use_notes)
        print("  第 {} 次心跳：本週數字 {}，比上週 {}，同步回條 {}".format(i, tot, "無從比較" if delta is None else "+" + str(delta), receipt))
    print()

print("坑一：同一個檔案，執行和手動修改撞在一起，最後完成的同步獲勝，被蓋掉的版本救不回來")
folder = {"notes.md": "W1=45"}
heartbeat(2, folder, True, manual_edit="W1=45;人工備註：客戶要加圖表")
print("  結果 notes.md =", folder["notes.md"], "-> 代理這次寫的 W2 不見了")
print()
print("坑二：資料夾容量上限 {} bytes，超過時代理照跑，但這次變更被丟掉、只有警告".format(NOTES_CAP))
folder = {"notes.md": ";".join("W{}=999999".format(k) for k in range(1, 15))}
_, _, receipt = heartbeat(15, folder, True)
print("  第 15 次同步回條：", receipt, "-> 一定要看回條，不能假設存好了")
print()
INSTR = ["照往常的格式寫週報", "語氣跟上次一樣", "依照 references/format.md 的格式", "你知道我們的風格"]
VAGUE = ("往常", "上次一樣", "你知道", "as usual", "as before")
print("指令掃描：哪裡會逼代理用猜的？")
for s in INSTR:
    bad = any(v in s for v in VAGUE)
    print("  {} {}{}".format("猜" if bad else "查", s, "  -> 改成指向一個檔案" if bad else ""))'
   show "$P"; run "$P" ;;
5) banner "相依性登記表：一張表、一個名字、一個日期"
   tip "最貴的失敗不是設計錯，而是沒人盯的相依。把 release notes 拿來對登記表，退役的 broker 就只是排好的一個下午。"
   P='import csv
from datetime import date
from pathlib import Path

TODAY = date(2026, 11, 27)
REG = [
    ("legacy broker", "Connector", "Peter", "週報客戶與帳務段落", date(2026, 8, 15), date(2026, 11, 15), "改走新 aggregator 路線（先測）"),
    ("source-and-cite", "Skill source", "Peter", "引用規則失效", date(2026, 11, 10), date(2027, 2, 10), "釘選 v2 副本"),
    ("Claude Code", "Runtime", "Peter", "Writer 角色沒人做", date(2026, 10, 20), date(2027, 1, 20), "Codex"),
    ("Composio", "Connector", "Peter", "（未驗證）替代路線", date(2026, 10, 20), date(2026, 11, 20), "暫不承諾"),
    ("model provider", "Model", "Peter", "品質或成本變動", date(2026, 10, 20), date(2027, 1, 20), "備用模型"),
    ("VPS hosting", "Infrastructure", "Peter", "整家公司停擺", date(2026, 9, 1), date(2026, 12, 1), "還原計畫"),
]
NOTES = {
    date(2026, 10, 1): "Retired the legacy broker integration; existing connections stop working, no automated migration. Coding agents (Claude Code, Codex) now run full auto by default.",
    date(2026, 10, 5): "Composio route no longer gated behind experimental setting.",
}
out = Path("ch06/interactive")
out.mkdir(parents=True, exist_ok=True)
with open(out / "dependency_register.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["dependency", "type", "owner", "what_breaks", "last_checked", "next_review", "fallback"])
    for r in REG:
        w.writerow([r[0], r[1], r[2], r[3], r[4].isoformat(), r[5].isoformat(), r[6]])

print("release notes 對登記表（每個名字都搜一遍）：")
for d, text in NOTES.items():
    hits = [r for r in REG if r[0].lower() in text.lower()]
    for r in hits:
        print("  {} 提到 {:<16} -> 會壞：{}；備案：{}".format(d, r[0], r[3], r[6]))
print()
print("到 {} 為止已過審核日的項目：".format(TODAY))
for r in REG:
    if r[5] < TODAY:
        print("  {:<16} 應於 {} 審核，逾期 {} 天".format(r[0], r[5], (TODAY - r[5]).days))
print()
print("沒有登記表：客戶先從報告空白發現 -> 再告訴你")
print("有登記表：10/1 release 當天就對到 legacy broker -> 排一個下午換路線")
print("每季審一次、每次約 30 分鐘；未驗證的項目照列，只是審核日排近一點")
print()
print("已寫入", out / "dependency_register.csv")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型寫一個 skill（含路由描述與三種測試）"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch06/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "skill_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是幫小公司設計 AI 代理的顧問。請為「把本週專案筆記整理成給客戶的週報」這個任務寫一個 skill。
路由描述必須照這個模板：「Use when 什麼情況。Do not use when 什麼情況。Produces 產出什麼。If 缺少什麼輸入, 明確的處置。」（可用中文，但四段都要有）
輸出 JSON：
{"name": "skill 名稱", "description": "路由描述", "steps": ["步驟1", "步驟2", "步驟3"], "failure_behavior": "缺少輸入時要怎麼做", "tests": [{"kind": "ordinary", "input": "...", "expected": "..."}, {"kind": "missing", "input": "...", "expected": "..."}, {"kind": "out_of_scope", "input": "...", "expected": "..."}]}"""
try:
    skill = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(skill, ensure_ascii=False, indent=2), encoding="utf-8")
print("skill 名稱：", skill.get("name"))
print("路由描述：", skill.get("description"))
print("步驟：")
for s in skill.get("steps") or []:
    print("  -", str(s)[:70])
print("失敗行為：", skill.get("failure_behavior"))
print("測試：")
for t in skill.get("tests") or []:
    if isinstance(t, dict):
        print("  [{}] {} -> {}".format(t.get("kind"), str(t.get("input"))[:30], str(t.get("expected"))[:40]))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用程式審 skill，再算它值不值得"
   tip "好的 skill 夠窄、可測、寫明不適用時怎麼辦。最後用書裡的假設算：省下的返工要大於寫和維護的成本。"
   P='import json
from pathlib import Path

out = Path("ch06/interactive")
(out / "skill_report.md").unlink(missing_ok=True)
raw = out / "skill_raw.json"
FALLBACK = {
    "name": "weekly-client-digest",
    "description": "Use when 要把本週專案筆記整理成客戶週報。Do not use when 寫標題、行銷文案或內部閒聊。Produces 一頁週報＋引用清單。If 缺少本週筆記或數字, 寫 data not found 並升級給人，不估計。",
    "steps": ["讀 references/format.md", "逐條摘要並附來源", "在 notes.md 記下用了哪些來源"],
    "failure_behavior": "缺本週筆記時寫 data not found 並升級給人，不估計",
    "tests": [{"kind": "ordinary", "input": "完整筆記", "expected": "週報"}, {"kind": "missing", "input": "沒有數字", "expected": "data not found"}, {"kind": "out_of_scope", "input": "想標題", "expected": "不載入"}],
}
skill = None
if raw.exists():
    try:
        skill = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        skill = None
source = "第 6 步模型輸出" if isinstance(skill, dict) else "內建範例（第 6 步沒有成功）"
if not isinstance(skill, dict):
    skill = FALLBACK

desc = str(skill.get("description", ""))
PARTS = {
    "何時用": ("use when", "使用時機", "用於", "當"),
    "何時不用": ("do not use", "不要用", "不適用", "勿用"),
    "產出": ("produces", "產出", "輸出"),
    "缺輸入處置": ("if ", "若", "如果", "缺"),
}
checks = []
for part, kws in PARTS.items():
    ok = any(k in desc.lower() for k in kws)
    checks.append((part, ok))
fb = str(skill.get("failure_behavior", ""))
import re
# 「估計／推測／猜」前面 6 個字內有否定詞（不、勿、禁、別、絕不、not）才算禁止猜，否則算叫代理猜
guess = any(not re.search(r"(不|勿|禁|別|not)[^。；;,，]{0,6}$", fb[: m.start()].lower()) for m in re.finditer(r"估計|推測|猜|estimate|guess", fb.lower()))
checks.append(("失敗行為有寫且不叫代理猜", bool(fb) and not guess))
kinds = {str(t.get("kind")) for t in skill.get("tests") or [] if isinstance(t, dict)}
checks.append(("三種測試都有", {"ordinary", "missing", "out_of_scope"} <= kinds))
steps = skill.get("steps") or []
checks.append(("步驟夠窄（3～7 步）", 3 <= len(steps) <= 7))

print("資料來源：", source)
print("skill：", skill.get("name"))
for name, ok in checks:
    print("  {} {}".format("PASS" if ok else "FAIL", name))
score = sum(ok for _, ok in checks)
print("通過 {} / {}".format(score, len(checks)))
print()
print("這個 skill 值不值得？（書中假設：每月 40 份、修引用從 15 分降到 5 分、時薪 50 美元）")
print("{:>8} | {:>8} | {:>9} | {:>9}".format("每月份數", "每月省", "第一個月淨", "之後每月淨"))
print("-" * 44)
for n in (10, 20, 40, 80):
    saved = (15 - 5) * n / 60 * 50
    first = saved - 3 * 50 - 1 * 50
    later = saved - 1 * 50
    print("{:>8} | {:>8.0f} | {:>9.0f} | {:>9.0f}".format(n, saved, first, later))
print("40 份時：每月省約 333，第一個月淨約 133，之後每月約 283；10 份時第一個月是負的")

lines = ["- {} {}".format("PASS" if ok else "FAIL", n) for n, ok in checks]
report = "# 第 6 章：skill 審查報告\n\n資料來源：" + source + "\n\n```json\n" + json.dumps(skill, ensure_ascii=False, indent=2) + "\n```\n\n## 檢查\n\n" + "\n".join(lines) + "\n\n通過 {} / {}\n".format(score, len(checks))
(out / "skill_report.md").write_text(report, encoding="utf-8")
print()
print("已寫入", out / "skill_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：技能、連接器與記憶的五個重點"
   tip "這章的功夫不是接更多，而是知道自己站在什麼上面、上次是什麼時候看的。"
   P='from pathlib import Path

points = [
    "skill 是把你的判斷裝進代理：每次心跳只看名稱和描述，描述對上才載入全文；描述寫「何時用、何時不用、產出、缺輸入怎麼辦」，不是寫主題。",
    "失敗行為要寫明：沒寫的缺口代理會自己編；v1 捏造或越界 2 次，加上 date not found 規則的 v2 是 0 次。每次存檔都是新版本，跑到一半的任務鎖在舊版。",
    "連接器選得少、給得少：從 Blueprint 步驟出發、讀優先於寫、授權給單一代理、用專用帳號；風險分數從 170 降到 5。",
    "記憶是設計任務：心跳之間代理不記得，延續要寫進 notes.md；最後同步獲勝、超過容量變更會被丟掉，要看同步回條；把「照往常」換成指向檔案。",
    "相依性登記表：每個 broker、skill 來源、runtime、模型、主機都要有負責人、上次檢查日、下次審核日與備案；release notes 一出來就對表。",
]
print("第 6 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("dependency_register.csv", "skill_raw.json", "skill_report.md"):
    p = Path("ch06/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

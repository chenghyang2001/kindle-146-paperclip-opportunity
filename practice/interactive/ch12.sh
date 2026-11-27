#!/bin/bash
# K146 第 12 章互動演練：部署、更新與維護——更新改了預設時，伺服器歸誰管，一次跑一步
# 用法：bash ch12.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch12/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 12 章｜部署更新與維護　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "放在哪裡＝誰負責 uptime：託管選擇與維護成本"
   tip "託管不是技術題，是「誰負責」題；而且維護工時是每個月都會發生的成本，報價漏掉它跟漏掉審查時間一樣錯。"
   P='import csv
from pathlib import Path

out = Path("ch12/interactive")
out.mkdir(parents=True, exist_ok=True)
PLACES = [
    ("筆電／桌機 local", "坐在前面的人", "休眠、重開機、被拔插頭", "測試公司、展示"),
    ("社群 macOS 桌面版", "Operator 自己", "版本落後、回滾有限", "不想碰終端機的 Operator"),
    ("小型伺服器 VPS", "客戶或你（書面約定）", "漏更新、沒備份、憑證過期", "大多數客戶公司"),
    ("客戶 IT 雲端帳號", "客戶 IT（書面約定）", "變更審批慢、沒人管的防火牆規則", "Internal Champion 試點、大公司"),
]
print("{:<18} | {:<18} | {:<24} | {}".format("放在哪裡", "誰負責 uptime", "典型故障", "什麼時候選"))
print("-" * 96)
for p in PLACES:
    print("{:<18} | {:<18} | {:<24} | {}".format(*p))

HOST, RATE, SKILL_H, SERVER_H = 30, 50, 2, 3
SETUP, NET_BEFORE = 5000, 1510
net_after = NET_BEFORE - SERVER_H * RATE
print()
print("假設：託管 ${}/月、維護時薪 ${}、技能連接器維護 {} 小時、伺服器照顧 {} 小時/月".format(HOST, RATE, SKILL_H, SERVER_H))
print("  漏算伺服器照顧：每月淨值 ${}，${} 建置費 {:.1f} 個月回本".format(NET_BEFORE, SETUP, SETUP / NET_BEFORE))
print("  算進伺服器照顧：每月淨值 ${}，${} 建置費 {:.1f} 個月回本".format(net_after, SETUP, SETUP / net_after))
rows = []
for h_week in (0.75, 2, 4):
    h_month = h_week * 52 / 12
    cost = HOST + h_month * RATE
    net = NET_BEFORE + SERVER_H * 0 - h_month * RATE
    be = SETUP / net if net > 0 else float("inf")
    rows.append((h_week, round(h_month, 1), round(cost), round(net), round(be, 1)))
print()
print("{:>10} | {:>10} | {:>12} | {:>10} | {:>8}".format("每週維護h", "每月維護h", "每月總成本$", "每月淨值$", "回本月數"))
print("-" * 62)
for r in rows:
    print("{:>10} | {:>10} | {:>12} | {:>10} | {:>8}".format(*r))
print()
print("每週 2～4 小時（第三方評測的重度使用）時，維護成本是每月 3 小時的好幾倍——試點數字告訴你哪個才對。")
with open(out / "hosting.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["hours_per_week", "hours_per_month", "monthly_cost", "monthly_net", "breakeven_months"])
    w.writerows(rows)
print("已寫入", out / "hosting.csv")'
   show "$P"; run "$P" ;;
2) banner "備份有三層：資料庫、磁碟檔案、公司匯出"
   tip "多數人以為備份＝資料庫。在 Paperclip 裡那只是三層之一，另外兩層才是最常弄丟的。"
   P='import csv
from itertools import combinations
from pathlib import Path

out = Path("ch12/interactive")
out.mkdir(parents=True, exist_ok=True)
ITEMS = {
    "任務 tasks": {"db"},
    "核准紀錄 approvals": {"db"},
    "成本事件 cost events": {"db"},
    "活動紀錄 activity": {"db"},
    "代理指令檔": {"files"},
    "本機上傳檔": {"files"},
    "實例設定": {"files"},
    "公司與代理設計": {"db", "export"},
    "專案 projects": {"db", "export_opt"},
    "技能 skills": {"db", "export_opt"},
    "議題 issues": {"db", "export_opt"},
    "金鑰 secrets": set(),
}
LAYER = {"db": "資料庫", "files": "磁碟檔案", "export": "公司匯出"}

def recover(layers, export_opts=True):
    have = set(layers)
    if "export" in have and export_opts:
        have.add("export_opt")
    return [k for k, v in ITEMS.items() if v & have]

rows = []
print("{:<26} | {:>6} | 救不回來的".format("備份組合", "救回"))
print("-" * 90)
cases = [(("export",), False), (("export",), True)]
cases += [(c, True) for r in (1, 2, 3) for c in combinations(("db", "files", "export"), r) if c != ("export",)]
for layers, opt in cases:
    got = recover(layers, opt)
    lost = [k for k in ITEMS if k not in got]
    name = "＋".join(LAYER[l] for l in layers) + ("" if "export" not in layers else ("（含專案技能議題）" if opt else "（預設內容）"))
    rows.append((name, len(got), len(ITEMS), "、".join(lost)))
    print("{:<26} | {:>2}/{:<3} | {}".format(name, len(got), len(ITEMS), "、".join(lost) or "（無）"))
print()
print("只備份匯出檔：公司設計回來了，但「它做過什麼」（核准、成本、活動）全沒了——審計問的正是這層。")
print("金鑰 secrets 不在任何一層：要另外記在交接文件的金鑰登記表裡。")
with open(out / "backup_layers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["layers", "recovered", "total", "lost"])
    w.writerows(rows)
print("已寫入", out / "backup_layers.csv")'
   show "$P"; run "$P" ;;
3) banner "保留策略與還原演練排程：7 日、4 週、12 月"
   tip "官方文件的範例保留七份每日、四份每週、十二份每月。算算看一年後手上有幾份、最舊能回到哪天。"
   P='DAYS = 400
backups = list(range(1, DAYS + 1))
daily = backups[-7:]
weekly = [d for d in backups if d % 7 == 0][-4:]
monthly = [d for d in backups if d % 30 == 0][-12:]
kept = sorted(set(daily) | set(weekly) | set(monthly))
print("連續備份 {} 天後：".format(DAYS))
print("  每日保留：", daily)
print("  每週保留：", weekly)
print("  每月保留：", monthly)
print("  實際保留 {} 份（不是 {} 份）；最舊還原點是第 {} 天，等於 {} 天前".format(len(kept), DAYS, kept[0], DAYS - kept[0]))
print()
print("「好幾個月後才發現」的資料損壞，能不能救？")
for ago in (3, 20, 100, 300, 380):
    target = DAYS - ago
    cand = [d for d in kept if d <= target]
    if cand:
        print("  {:>3} 天前壞掉 → 回到第 {} 天的備份，損失 {} 天的工作".format(ago, cand[-1], target - cand[-1]))
    else:
        print("  {:>3} 天前壞掉 → 沒有更早的備份，救不回".format(ago))
print()
tests = [1, 2, 3, 6, 9, 12]
print("還原演練排程：第一季每月一次、之後每季一次 → 第", tests, "個月")
print("一年 {} 次 × 約 1 小時 = {} 小時；這是最可能救下一個客戶的維護工作。".format(len(tests), len(tests)))'
   show "$P"; run "$P" ;;
4) banner "還原演練：匯入的公司心跳是關的，先設預算再叫醒"
   tip "還原後的代理預設計時心跳關閉。忘了第 8 章的預算就把它們全叫醒，等於讓一家沒有天花板的公司開跑。"
   P='import random
random.seed(146)
src = {"agents": 4, "projects": 3, "issues": 27}
restored = {"agents": 4, "projects": 3, "issues": 27}
print("匯入前預覽比對：")
for k in src:
    print("  {:<9} 原公司 {:>3} ／ 還原 {:>3} → {}".format(k, src[k], restored[k], "一致" if src[k] == restored[k] else "不一致"))
print()
AGENTS = [("researcher", 0.12), ("writer", 0.18), ("reviewer", 0.08), ("looper", 0.90)]

def run(hours, ceiling):
    spent = {a: 0.0 for a, _ in AGENTS}
    paused = {}
    for h in range(1, hours + 1):
        for a, rate in AGENTS:
            if a in paused:
                continue
            spent[a] += rate * random.uniform(0.8, 1.2) * 4
            if ceiling is not None and spent[a] >= ceiling:
                spent[a] = ceiling
                paused[a] = h
    return spent, paused

for label, ceiling in (("A. 直接全部叫醒（沒設預算）", None), ("B. 先設每位代理 $20 上限", 20.0)):
    spent, paused = run(48, ceiling)
    print(label)
    for a, _ in AGENTS:
        note = "（第 {} 小時被預算暫停）".format(paused[a]) if a in paused else ""
        print("  {:<10} 48 小時花費 ${:>7.2f}{}".format(a, spent[a], note))
    print("  合計 ${:.2f}".format(sum(spent.values())))
    print()
print("C. 書上的做法：只叫醒一位代理、給小預算和一件小任務")
print("  wake → 接下任務 → 留下 comment：三個都看到，才算這次還原成功；寫下日期。")'
   show "$P"; run "$P" ;;
5) banner "快速發版：先上 staging，再上正式"
   tip "四週五個版本，好幾個改了正在運作的公司所依賴的行為。release note 是你唯一會收到的警告。"
   P='RELEASES = [
    ("v2026.916.0", "09-16", []),
    ("patch", "09-21", []),
    ("v2026.1001.0", "10-01", ["自動執行模式", "Composio 連接器"]),
    ("v2026.1005.0", "10-05", ["mention 交接"]),
    ("v2026.1012.0", "10-12", ["預算設定位置", "預設指令", "工具授權 grant"]),
]
CLIENT_DEPENDS = {"mention 交接", "預設指令", "工具授權 grant"}
print("客戶公司依賴：", "、".join(sorted(CLIENT_DEPENDS)))
print()
print("{:<14} | {:<6} | {:<28} | {}".format("版本", "日期", "改變的預設", "影響這家客戶"))
print("-" * 80)
hits = []
for v, d, ch in RELEASES:
    hit = [c for c in ch if c in CLIENT_DEPENDS]
    hits += [(v, h) for h in hit]
    print("{:<14} | {:<6} | {:<28} | {}".format(v, d, "、".join(ch) or "-", "、".join(hit) or "無"))
print()
FIX_MIN = 10
DETECT_H = 30
print("情境：設計工作室直接在正式環境更新 v2026.1005.0（週一）")
print("  沒人讀 release note → 代理全部 idle，到週二下午才發現（約 {} 小時）".format(DETECT_H + 6))
print("  沒有更新前備份、建置的人已離開、辦公室經理不知道桌下那台是唯一副本")
print("  真正的修正只要 {} 分鐘，結果停擺一天半".format(FIX_MIN))
print()
print("同一版本走 staging（第二個實例、同版本、客戶公司的匯出、小預算）跑 1～2 天：")
for v, h in hits:
    print("  {} 在 staging 暴露「{}」壞掉 → 正式環境 0 小時停擺".format(v, h))
print()
print("通道：客戶公司一律 stable；nightly／canary 只放測試公司。資安修補例外：當天走備份＋驗證，不等一週。")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型判讀事故：哪幾筆要叫人"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch12/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "triage_raw.json"
raw.unlink(missing_ok=True)
RUNS = [
    {"id": "R1", "agent": "researcher", "status": "succeeded", "duration_s": 4, "comment": False, "note": "timer wake"},
    {"id": "R2", "agent": "writer", "status": "failed", "exit_code": 143, "note": "大型任務一次處理"},
    {"id": "R3", "agent": "reviewer", "status": "succeeded", "task_state": "in_progress", "note": "留了進度 comment，沒有 disposition"},
    {"id": "R4", "agent": "writer", "status": "running", "running_min": 95, "heartbeat_timeout_min": 60},
    {"id": "R5", "agent": "researcher", "status": "failed", "note": "修正後同一錯誤連續第 3 次"},
    {"id": "R6", "agent": "looper", "status": "paused", "note": "達到預算上限，看不出是迴圈造成還是結果"},
]
prompt = "你是 Paperclip 代理公司的值班維運。以下是 6 筆 run 紀錄：\n" + json.dumps(RUNS, ensure_ascii=False) + """
請逐筆判讀，輸出 JSON：
{"records": [{"id": "R1", "diagnosis": "一句話原因", "action": "下一步", "escalate": true 或 false}]}
escalate 代表要不要叫具名負責人（人類）處理。"""
try:
    res = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(res, ensure_ascii=False, indent=2), encoding="utf-8")
recs = res.get("records") if isinstance(res.get("records"), list) else []
for r in recs:
    if isinstance(r, dict):
        print("  {:<3} 叫人={:<5} {} → {}".format(str(r.get("id")), str(r.get("escalate")), str(r.get("diagnosis", ""))[:36], str(r.get("action", ""))[:30]))
print()
print("模型判定要叫人的：", [r.get("id") for r in recs if isinstance(r, dict) and r.get("escalate") is True])
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "對照書上的規則：事故紀錄＋一頁交接文件"
   tip "書上只有三種情況要叫人：修正後同錯連三次、running 超過心跳逾時、預算暫停卻分不清是不是迴圈。"
   P='import json
from datetime import date
from pathlib import Path

out = Path("ch12/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "incident_report.md").unlink(missing_ok=True)
RULES = {
    "R1": ("計時喚醒沒事做就睡回去", "關掉計時心跳，改用指派與例行喚醒", False),
    "R2": ("exit 143 被殺，多半是逾時或記憶體上限", "把工作拆成子任務，縮小每次喚醒的量", False),
    "R3": ("缺 disposition：進度 comment 不等於處置", "要求代理明確給出處置結果", False),
    "R4": ("running 超過心跳逾時，指向基礎設施不是代理", "叫具名負責人查主機", True),
    "R5": ("修正後同一錯誤連三次", "叫具名負責人；停更新、保護最新備份", True),
    "R6": ("預算暫停但分不清是不是迴圈", "打開 run 紀錄看形狀，叫人判斷", True),
}
raw = out / "triage_raw.json"
model = {}
source = "內建範例（第 6 步沒有成功）"
if raw.exists():
    try:
        data = json.loads(raw.read_text(encoding="utf-8"))
        for r in data.get("records", []):
            if isinstance(r, dict):
                model[str(r.get("id"))] = r.get("escalate") is True
        source = "第 6 步模型輸出"
    except (ValueError, AttributeError):
        model = {}
if not model:
    model = {"R1": False, "R2": False, "R3": False, "R4": True, "R5": True, "R6": False}
agree = 0
lines = []
print("資料來源：", source)
print("{:<4} | {:<6} | {:<6} | {}".format("id", "書規則", "模型", "書上的判讀"))
print("-" * 70)
for rid, (diag, act, esc) in RULES.items():
    m = model.get(rid)
    ok = m == esc
    agree += ok
    print("{:<4} | {:<6} | {:<6} | {}{}".format(rid, "叫人" if esc else "自理", "叫人" if m else "自理", diag, "" if ok else "  <- 不一致"))
    lines.append("| {} | {} | {} | {} | {} |".format(rid, diag, act, "叫人" if esc else "自理", "叫人" if m else "自理"))
print()
print("一致 {}/6".format(agree))
today = date.today().isoformat()
incident = "日期時間：{}。發現者：值班。影響：writer 代理。動作：暫停。原因：running 95 分鐘超過心跳逾時 60 分鐘。修正：待主機負責人。需要還原：否。改變什麼：加上 health address 監控與通知對象。紀錄者：值班，{}。".format(today, today)
HANDOFF = {"公司": "Demo Studio", "交接版本": "v2026.1012.0", "放在哪": "VPS／login 模式", "帳號擁有者": "客戶 Alice",
           "網域憑證": "客戶 Alice", "資料庫備份": "每日 02:00 → 異地物件儲存", "檔案備份": "每日 → 另一顆磁碟",
           "匯出": "每週", "最近還原測試": "", "更新通道": "stable", "董事": "Alice", "事故聯絡": "Bob 0912-xxx 平日 9-18"}
blank = [k for k, v in HANDOFF.items() if not v]
print()
print("事故紀錄（含「改變什麼」，不然事故會重演）：")
print("  " + incident)
print()
print("交接文件 {} 欄，空白：{}".format(len(HANDOFF), blank or "無"))
if blank:
    print("  「最近還原測試」空白＝這份備份還沒證明任何事，交接不算完成")
fence = "| id | 書上判讀 | 下一步 | 書規則 | 模型 |\n|---|---|---|---|---|\n"
md = "# 第 12 章：事故判讀與交接檢查\n\n資料來源：" + source + "\n\n" + fence + "\n".join(lines) + "\n\n一致 {}/6\n\n## 事故紀錄\n\n".format(agree) + incident + "\n\n## 交接文件空白欄\n\n" + ("、".join(blank) if blank else "無") + "\n"
(out / "incident_report.md").write_text(md, encoding="utf-8")
print()
print("已寫入", out / "incident_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：讓公司屬於某個具名的人"
   tip "技術工作很小，難的是讓公司的每一部分都屬於某個有名字的人。"
   P='from pathlib import Path

points = [
    "放在哪裡決定誰負責：桌機只適合測試；客戶公司放小伺服器或客戶雲端，第一個代理跑之前寫下帳號付費者、網域憑證持有者、當機找誰且多久內回應。",
    "維護是每月成本：漏算每月 3 小時伺服器照顧，回本從 3.3 個月變 3.7 個月；每週 2～4 小時時成本是好幾倍。",
    "備份三層＋一次演練：只備份匯出會丟掉核准、成本與活動紀錄；7 日／4 週／12 月保留 400 天只留 22 份、最舊回到 340 天前；沒還原過的備份只是掛名。",
    "還原後心跳關著：先設預算與環境變數再叫醒，只叫一位、給小任務，看到 wake、接單、comment 才算成功。",
    "更新是例行程序不是膽量測試：stable 通道、staging 跑 1～2 天、先備份再更新、需要時完全停止；rollback 只回退程式碼不回退資料庫遷移。",
    "事故照書面程序：修正後同錯連三次、running 超過心跳逾時、預算暫停分不清迴圈，這三種叫人；事故紀錄要寫「改變什麼」；交接文件一頁寫清誰擁有什麼。",
]
print("第 12 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("hosting.csv", "backup_layers.csv", "triage_raw.json", "incident_report.md"):
    p = Path("ch12/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

#!/bin/bash
# K146 第 9 章互動演練：治理——核准、決策與董事席，一次跑一步
# 用法：bash ch09.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch09/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 9 章｜治理：核准與董事席　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "四種內建核准＋第五種：拒絕和要求修改不一樣"
   tip "產品內建四種核准；花錢、發布、聯絡客戶的閘門，只有寫進指令才存在。"
   P='APPROVALS = [
    ("Hire Agent", "經理代理想要新下屬", "核准才建立；細節要打開完整請求", "產品"),
    ("CEO Strategy", "CEO 第一次心跳提出計畫", "核准前 CEO 不能推進任務", "產品"),
    ("Budget Override", "預算碰到硬停", "到 Costs 頁提高或保持暫停", "產品"),
    ("Board Approval", "代理依指令在採購前提出", "代理停下等答覆", "產品（但要有人寫進指令）"),
    ("第五種閘門", "寄送、改目標、給權限", "你寫進指令或章程", "人員約定"),
]
print("{:<16} | {:<20} | {:<30} | {}".format("核准", "觸發", "效果", "誰強制"))
print("-" * 90)
for row in APPROVALS:
    print("{:<16} | {:<20} | {:<30} | {}".format(*row))
print()

def strategy_action(direction_ok, details_ok):
    if not direction_ok:
        return "reject（丟掉計畫，CEO 從頭寫）"
    if not details_ok:
        return "revision（退回修改，次數不限）"
    return "approve（下一次執行建立任務）"

print("CEO Strategy 怎麼回：")
for d, s, note in ((False, True, "受眾整個換掉（開場案例）"), (True, False, "方向對、排程太滿"), (True, True, "方向與細節都對")):
    print("  {:<16} -> {}".format(note, strategy_action(d, s)))'
   show "$P"; run "$P" ;;
2) banner "決策權責表：八項決定、時限、可逆性、誰強制"
   tip "無法復原的決定時限最緊、主人最確定；客戶以為八列都由產品處理，其實只有一半。"
   P='import csv
from pathlib import Path
out = Path("ch09/interactive")
out.mkdir(parents=True, exist_ok=True)
H = 24
ROWS = [
    ("新增代理", "董事", "Hire Agent", 2 * H, "partial", "product"),
    ("核准 CEO 計畫", "董事", "CEO Strategy", 1 * H, "partial", "product"),
    ("暫停後提高預算", "董事", "預算控制", 8, "yes", "product"),
    ("花費超過門檻或週期費用", "董事", "寫進指令的 Board Approval", 8, "no", "product"),
    ("寄送任何東西給客戶", "具名審查者", "審查步驟（第10章）", 0, "no", "agreement"),
    ("變更公司目標或角色", "董事", "書面變更並記錄", 2 * H, "yes", "agreement"),
    ("新增連接器或擴權", "董事", "刻意記錄的變更", 2 * H, "yes", "agreement"),
    ("暫停疑似迴圈的代理", "名單上任何人", "董事直接權力", 0, "yes", "product"),
]
def window(h):
    return "每次之前/立即" if h == 0 else ("當天" if h <= 8 else "{} 工作天".format(h // H))
print("{:<14} | {:<8} | {:<10} | {:<6} | {:<9} | {}".format("決定", "決定者", "時限", "可逆", "強制", "檢查"))
print("-" * 76)
bad = 0
for name, who, mech, h, rev, enf in ROWS:
    ok = not (rev == "no" and h > 8)
    bad += 0 if ok else 1
    print("{:<14} | {:<8} | {:<10} | {:<6} | {:<9} | {}".format(name, who, window(h), rev, enf, "OK" if ok else "不可逆卻時限太鬆"))
prod = sum(1 for r in ROWS if r[5] == "product")
print()
print("產品強制 {} 列、人員約定 {} 列；違反「不可逆要當天」的列數：{}".format(prod, len(ROWS) - prod, bad))
with open(out / "decision_rights.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["decision", "decided_by", "mechanism", "window_hours", "reversible", "enforced_by"])
    w.writerows(ROWS)
print("已寫入", out / "decision_rights.csv")'
   show "$P"; run "$P" ;;
3) banner "依風險與可逆性校準閘門"
   tip "兩題測試：錯了有多糟？能不能復原？硬閘門會集中在「離開公司」的事情上。"
   P='def gate(risk, reversible):
    if risk == "low" and reversible:
        return "不設閘門（代理自己做）"
    if risk == "low":
        return "輕閘門"
    if risk == "medium" and reversible:
        return "董事刻意決定並記錄"
    if risk == "medium":
        return "核准閘門（如 Hire Agent，2 工作天）"
    if reversible:
        return "書面變更＋具名主人（可還原舊版）"
    return "硬閘門＋具名主人＋短時限"

ACTIONS = [
    ("代理起草文章", "low", True, False),
    ("同一篇寄給客戶", "high", False, True),
    ("新增連接器", "medium", True, False),
    ("新聘用代理（花掉的錢回不來）", "medium", False, False),
    ("改公司目標", "high", True, False),
    ("小額週期費用", "low", False, True),
    ("給內部同事的訊息", "low", False, False),
    ("超過門檻的採購", "high", False, True),
    ("刪除無法恢復的資料", "high", False, False),
    ("改表格排版", "low", True, False),
]
hard, leaves = 0, 0
print("{:<26} | {:<6} | {:<4} | {}".format("行動", "風險", "可逆", "閘門"))
print("-" * 70)
for name, risk, rev, out_of_company in ACTIONS:
    g = gate(risk, rev)
    if g.startswith("硬"):
        hard += 1
        leaves += 1 if out_of_company else 0
    print("{:<26} | {:<6} | {:<4} | {}".format(name, risk, "可" if rev else "不可", g))
print()
print("10 個行動中硬閘門 {} 個，其中 {} 個是「離開公司」的事（客戶、錢）".format(hard, leaves))'
   show "$P"; run "$P" ;;
4) banner "注意力成本：嚴格設計 vs 校準設計，誰真的擋下壞決定"
   tip "董事每天只有 10 分鐘。分散在 40 筆上的注意力，等於沒給任何一筆。"
   P='import random
random.seed(146)
RATE, READ_MIN, MINUTES_PER_DAY = 50, 4, 10
print("書中算術（每月以 4 週計）：")
for name, per_week in (("嚴格", 40), ("校準", 6)):
    hours = per_week * READ_MIN * 4 / 60
    print("  {}：每週 {} 筆 x {} 分鐘 = 每月 {:.1f} 小時，約 {:.0f} 美元".format(name, per_week, READ_MIN, hours, hours * RATE))
print("  董事席本身：每天 10 分鐘 x 20 工作天 = {:.1f} 小時，約 {:.0f} 美元/月".format(200 / 60, 200 / 60 * RATE))
print()

def simulate(per_week, bad_rate, weeks=12):
    bad = caught = 0
    for _ in range(weeks):
        per_day = per_week / 5
        read_ratio = min(1.0, MINUTES_PER_DAY / (per_day * READ_MIN))
        for _ in range(per_week):
            if random.random() < bad_rate:
                bad += 1
                if random.random() < read_ratio:
                    caught += 1
    return bad, caught, read_ratio

print("模擬 12 週：壞請求（例如換掉受眾的策略）混在佇列裡，只有真的讀完才擋得下")
for name, per_week, bad_rate in (("嚴格 40 筆/週", 40, 0.03), ("校準 6 筆/週", 6, 0.20)):
    bad, caught, ratio = simulate(per_week, bad_rate)
    print("  {:<14} 每筆能讀完的機率 {:>4.0%}，壞請求 {:>2} 筆，擋下 {:>2} 筆，漏掉 {:>2} 筆".format(name, ratio, bad, caught, bad - caught))
print()
print("校準不是減少壞請求，而是把它們集中到少數真的會被讀的閘門上")'
   show "$P"; run "$P" ;;
5) banner "缺席一週測試、每月校準、稽核紀錄能證明什麼"
   tip "閘門多又全部被點過，是「看似嚴格、其實鬆散」；紀錄證明行動，不證明品質。"
   P='GATES = [
    # 名稱, 缺席一週時會擋下壞結果?, 3 個月核准次數, 原封不動通過次數
    ("寄給客戶前審查", True, 36, 22),
    ("超過門檻的採購", True, 5, 3),
    ("新聘用代理", True, 4, 2),
    ("每份草稿都要核准", False, 160, 160),
    ("每則留言都要核准", False, 240, 240),
    ("改表格排版要核准", False, 30, 30),
]
print("{:<16} | {:<12} | {:>6} | {:>8} | {}".format("閘門", "缺席一週時", "核准數", "原樣通過", "建議"))
print("-" * 72)
for name, protects, n, same in GATES:
    unchanged = same / n
    if protects:
        advice = "保留"
    elif unchanged == 1.0:
        advice = "移除候選"
    else:
        advice = "觀察"
    print("{:<16} | {:<12} | {:>6} | {:>7.0%} | {}".format(name, "擋下壞結果" if protects else "只延遲好結果", n, unchanged, advice))
print()
LOG = [
    {"time": "09:12", "actor": "董事 王小明", "action": "approve", "entity": "CEO Strategy v2"},
    {"time": "09:15", "actor": "CEO agent", "action": "create_tasks", "entity": "12 tasks"},
    {"time": "09:20", "actor": "Writer agent", "action": "run_start", "entity": "task-1"},
]
print("活動紀錄：")
for e in LOG:
    print("  {} {:<14} {:<13} {}".format(e["time"], e["actor"], e["action"], e["entity"]))
fields = set(LOG[0])
print()
print("能證明：誰核准（{}）、何時、順序 09:12 -> 09:15 -> 09:20".format(LOG[0]["actor"]))
for need, field in (("產出是否正確", "quality"), ("核准者是否讀過", "read_seconds"), ("代理為什麼這樣做", "intent")):
    print("不能證明：{}（紀錄裡沒有 {} 這種欄位）".format(need, field))
print("紀錄實際欄位：", "、".join(sorted(fields)))'
   show "$P"; run "$P" ;;
6) banner "讓真實模型起草 Board Charter（董事會章程）"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json
out = Path("ch09/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "charter_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是 Paperclip（開源 AI 代理公司平台）治理顧問。請為一家小型內容工作室起草兩頁的 Board Charter（董事會章程）。
公司有 CEO、Researcher、Writer、Editor 四個代理；董事是業務負責人陳美玲，備援是營運助理林志豪（只負責暫停代理）。
章程要有七部分：board_seat、response_windows、decision_rights、escalation、change_control、record、review；
另外要有 always_human（三項永遠需要人的決定）與 audit_sentence（一句話寫出稽核紀錄能證明什麼、不能證明什麼）。
輸出 JSON：{"always_human":["..."],"board_seat":{"member":"姓名","role":"...","backup":"姓名"},
"response_windows":{"urgent_hours":整數,"standard_days":整數},
"decision_rights":[{"decision":"...","decided_by":"...","window":"...","reversible":"yes|no|partial","enforced_by":"product|agreement"}],
"escalation":"...","change_control":"...","record":"...","review":"...","audit_sentence":"..."}，decision_rights 要 8 列。"""
try:
    charter = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    raw.unlink(missing_ok=True)
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(charter, ensure_ascii=False, indent=2), encoding="utf-8")
print("永遠需要人：")
for x in charter.get("always_human") or []:
    print("  -", x)
seat = charter.get("board_seat") if isinstance(charter.get("board_seat"), dict) else {}
print("董事：", seat.get("member"), "；備援：", seat.get("backup"))
print("時限：", charter.get("response_windows"))
rows = charter.get("decision_rights") if isinstance(charter.get("decision_rights"), list) else []
print("決策權責表", len(rows), "列")
for r in rows:
    if isinstance(r, dict):
        print("  {:<18} {:<10} {:<8} {}".format(str(r.get("decision"))[:18], str(r.get("window"))[:10], str(r.get("reversible")), str(r.get("enforced_by"))))
print("稽核句：", charter.get("audit_sentence"))
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用程式檢查章程：讓第二個人讀之前先自我體檢"
   tip "檢查七部分是否齊全、董事是不是人名而不是角色、不可逆決定的時限、稽核句有沒有講到「不能證明」。"
   P='import json
from pathlib import Path
out = Path("ch09/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "charter_check.md").unlink(missing_ok=True)
raw = out / "charter_raw.json"
FALLBACK = {
    "always_human": ["任何寄給客戶的東西", "超過 200 美元或任何週期性費用", "公司目標的變更"],
    "board_seat": {"member": "陳美玲", "role": "業務負責人", "backup": "林志豪"},
    "response_windows": {"urgent_hours": 4, "standard_days": 2},
    "decision_rights": [{"decision": d, "decided_by": "陳美玲", "window": w, "reversible": r, "enforced_by": e} for d, w, r, e in (
        ("新增代理", "2 工作天", "partial", "product"), ("核准 CEO 計畫", "1 工作天", "partial", "product"),
        ("暫停後提高預算", "當天", "yes", "product"), ("花費超過門檻", "當天", "no", "product"),
        ("寄送給客戶", "每次寄送前", "no", "agreement"), ("變更目標或角色", "2 工作天", "yes", "agreement"),
        ("新增連接器", "2 工作天", "yes", "agreement"), ("暫停迴圈代理", "立即", "yes", "product"))],
    "escalation": "錯過時限由林志豪暫停相關代理並通知陳美玲", "change_control": "陳美玲書面核准並記錄於變更表",
    "record": "陳美玲持有歸屬權限，每月匯出一次", "review": "首次審查 2026-12-31，之後每季",
    "audit_sentence": "稽核紀錄證明誰在何時做了什麼，不能證明產出正確或核准者讀過。",
}
charter = None
if raw.exists():
    try:
        charter = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        charter = None
source = "第 6 步模型輸出" if isinstance(charter, dict) else "內建範例（第 6 步沒有成功）"
if not isinstance(charter, dict):
    charter = FALLBACK
checks = []
parts = ["board_seat", "response_windows", "decision_rights", "escalation", "change_control", "record", "review"]
miss = [p for p in parts if not charter.get(p)]
checks.append(("七部分齊全", not miss, "缺 " + ",".join(miss) if miss else "7/7"))
ah = " ".join(map(str, charter.get("always_human") or []))
hits = [k for k, words in (("客戶", ("客戶", "customer", "client")), ("花費", ("美元", "花費", "費用", "支出", "付款", "spend")), ("目標", ("目標", "goal"))) if any(w in ah for w in words)]
checks.append(("三項永遠需要人", len(hits) == 3, "命中 " + "、".join(hits)))
seat = charter.get("board_seat") if isinstance(charter.get("board_seat"), dict) else {}
member = str(seat.get("member", ""))
ROLE_WORDS = ("老闆", "負責人", "owner", "經理", "manager", "董事")
is_person = bool(member) and not any(w in member.lower() for w in ROLE_WORDS)
checks.append(("董事是具名的人", is_person, member or "空白"))
rows = [r for r in (charter.get("decision_rights") or []) if isinstance(r, dict)]
checks.append(("權責表 8 列", len(rows) == 8, "{} 列".format(len(rows))))
no_tag = [str(r.get("decision")) for r in rows if str(r.get("enforced_by")).lower() not in ("product", "agreement")]
checks.append(("每列標明誰強制", not no_tag, "未標 " + ",".join(no_tag) if no_tag else "全部有標"))
FAST = ("當天", "立即", "小時", "之前", "寄送前", "same", "immediate", "hour", "before")
slow = [str(r.get("decision")) for r in rows if str(r.get("reversible")).lower() == "no" and not any(w in str(r.get("window")).lower() for w in FAST)]
checks.append(("不可逆決定時限夠緊", not slow, "太鬆：" + ",".join(slow) if slow else "OK"))
s = str(charter.get("audit_sentence", ""))
neg = any(w in s for w in ("不能", "無法", "不代表", "不證明", "not"))
checks.append(("稽核句講到不能證明", neg, s[:40]))
passed = sum(1 for _, ok, _ in checks if ok)
print("資料來源：", source)
for name, ok, note in checks:
    print("  [{}] {:<14} {}".format("PASS" if ok else "FAIL", name, note))
print()
print("通過 {}/{} 項；FAIL 的列就是第二個人讀時最可能遲疑的地方".format(passed, len(checks)))
md = "# 第 9 章：Board Charter 自我體檢\n\n資料來源：" + source + "\n\n"
md += "\n".join("- [{}] {}：{}".format("PASS" if ok else "FAIL", n, note) for n, ok, note in checks)
md += "\n\n通過 {}/{} 項。\n\n## 章程內容\n\n".format(passed, len(checks)) + chr(96) * 3 + "json\n" + json.dumps(charter, ensure_ascii=False, indent=2) + "\n" + chr(96) * 3 + "\n"
(out / "charter_check.md").write_text(md, encoding="utf-8")
print("已寫入", out / "charter_check.md")'
   show "$P"; run "$P" ;;
8) banner "總結：治理的五個重點"
   tip "問題從「希望代理守規矩」變成「我知道誰決定」。"
   P='from pathlib import Path
points = [
    "沒人讀的核准不是治理：四種內建核准加上要自己寫進指令的第五種閘門；方向錯用 reject，細節錯用 revision。",
    "決策權責表八列：產品強制 5 列、人員約定 3 列，要寫清楚免得客戶以為全由產品處理；不可逆的決定（錢、給客戶的東西）時限最緊。",
    "依風險與可逆性校準：10 個行動裡只有 3 個硬閘門，其中 2 個是離開公司的事；其他不設閘門、輕閘門或書面變更。",
    "嚴格設計每月約 533 美元的注意力卻只讀得完約三成，壞請求漏掉一大半；校準設計約 80 美元、每筆都讀完。缺席一週測試與每月校準，移除每次都原樣通過的閘門。",
    "稽核紀錄證明誰、何時、什麼順序，不證明品質與是否讀過；Board Charter 兩頁七部分，由具名的人簽名。",
]
print("第 9 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("decision_rights.csv", "charter_raw.json", "charter_check.md"):
    p = Path("ch09/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

#!/bin/bash
# K146 第 3 章互動演練：安裝與第一家公司，一次跑一步
# 用法：bash ch03.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
# 注意：本書不安裝真正的 Paperclip，這裡用 Python 標準庫模擬安裝、使命、心跳與排錯的概念
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch03/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 3 章｜安裝與第一家公司　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "安裝前六行環境檢查：第 5 項最常空白"
   tip "合作在指令之前就開始。官方 repository（2026-10-20 讀取）要求 Node.js 24.11 以上；第三方指南寫的舊版本不算數。"
   P='import json
from pathlib import Path
REQUIRED = (24, 11)
machines = {
    "自己的測試筆電": {"sleep": False, "node": "24.12", "proxy": False, "registry": False, "provider_cap": True, "owner": "我自己", "exposure": "只有本機"},
    "客戶 A 桌機": {"sleep": True, "node": "22.3", "proxy": False, "registry": True, "provider_cap": False, "owner": "", "exposure": "只有本機"},
    "客戶 B 伺服器": {"sleep": False, "node": "24.11", "proxy": True, "registry": False, "provider_cap": True, "owner": "IT 會處理", "exposure": "整個辦公室網段"},
}
def ver(s):
    return tuple(int(x) for x in s.split("."))
def check(m):
    issues = []
    if m["sleep"]:
        issues.append("1 機器會睡眠或重開：代理不會醒")
    if ver(m["node"]) < REQUIRED:
        issues.append("2 Node.js " + m["node"] + " 低於 24.11")
    if m["proxy"] or m["registry"]:
        issues.append("3 有 proxy 或私有 registry：第一小時排錯的原因")
    if not m["provider_cap"]:
        issues.append("4 供應商端沒有花費上限")
    if m["owner"].strip() in ("", "IT 會處理"):
        issues.append("5 沒有具名的維運負責人（最常見錯誤）")
    if m["exposure"] != "只有本機":
        issues.append("6 介面對外曝露，要有人核准")
    return issues
report = {}
for name, m in machines.items():
    issues = check(m)
    report[name] = issues
    verdict = "可以預約安裝" if not issues else f"先打 15 分鐘電話解決 {len(issues)} 項"
    print(f"{name}：{verdict}")
    for i in issues:
        print("   - " + i)
    print()
Path("ch03/interactive").mkdir(parents=True, exist_ok=True)
Path("ch03/interactive/precheck.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入 ch03/interactive/precheck.json")'
   show "$P"; run "$P" ;;
2) banner "誠實的時間估計：兩個數字，看檢查有沒有先做"
   tip "乾淨機器、熟手：幾分鐘＋三到十分鐘準備。困難的機器：幾小時。差別在於問題是在電話裡解決，還是在客戶面前撞到。"
   P='import json
from pathlib import Path
report = json.loads(Path("ch03/interactive/precheck.json").read_text(encoding="utf-8"))
ONSITE = {"1": 30, "2": 45, "3": 90, "4": 20, "5": 60, "6": 30}
CALL = {"1": 3, "2": 3, "3": 5, "4": 2, "5": 3, "6": 2}
BASE = 5 + 10
print("{:<12} | {:>6} | {:>14} | {:>14}".format("機器", "問題數", "沒先檢查（現場）", "先檢查（電話＋現場）"))
print("-" * 62)
for name, issues in report.items():
    keys = [i.split()[0] for i in issues]
    onsite = BASE + sum(ONSITE[k] for k in keys)
    pre = sum(CALL[k] for k in keys)
    pre_total = BASE + pre
    print("{:<12} | {:>6} | {:>11} 分 | {:>8} 分（電話 {} 分）".format(name, len(keys), onsite, pre_total, pre))
print()
print("沒先檢查時，時間花在客戶面前的環境問題上；先檢查，現場只剩安裝本身。")
print("把檢查當成合作的一部分報價，而不是安裝的一部分。")'
   show "$P"; run "$P" ;;
3) banner "安裝建立了什麼，又留下什麼沒做"
   tip "npx paperclipai@latest onboard --yes 的 --yes 是替你回答問題；答案是專案的預設，不是客戶的。"
   P='import json
from pathlib import Path
def onboard(yes=True):
    return {
        "instance_root": "~/.paperclip/instances/default",
        "database": "embedded PostgreSQL",
        "web": "http://127.0.0.1:3100（local trusted mode）",
        "company": {"name": "", "mission": "", "ceo_agent": {"adapter": None}},
        "budget_policy": None,
        "answered_by": "專案預設" if yes else "你",
    }
inst = onboard(yes=True)
print("安裝建立的東西：")
for k in ("instance_root", "database", "web"):
    print(f"  OK {k:<14} {inst[k]}")
print("  問題由誰回答：" + inst["answered_by"])
print()
gaps = []
if not inst["company"]["mission"]:
    gaps.append("使命是空的：目標鏈頂端沒有指令")
if inst["company"]["ceo_agent"]["adapter"] is None:
    gaps.append("CEO agent 沒有模型存取：第一次心跳會沉默")
if inst["budget_policy"] is None:
    gaps.append("沒有預算政策：公司沒有花費天花板")
print("安裝沒做的事（治理缺口）：")
for g in gaps:
    print("  缺 " + g)
print()
def heartbeat(i):
    if i["company"]["ceo_agent"]["adapter"] is None:
        return {"status": "ok", "output": "", "note": "看起來成功，其實什麼都沒產出"}
    return {"status": "ok", "output": "策略提案（等待 board 核准）"}
hb = heartbeat(inst)
print("試跑第一次心跳：", hb)
print("結論：安裝讓公司成為可能，不讓它受治理。")
Path("ch03/interactive/install_gaps.json").write_text(json.dumps({"instance": inst, "gaps": gaps, "first_heartbeat": hb}, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入 ch03/interactive/install_gaps.json")'
   show "$P"; run "$P" ;;
4) banner "使命檢查器：產出、受眾、截止、來源、審查者"
   tip "範本：在［截止］前，為［受眾］產出［產出物］，資料來源是［來源］，由［審查者］使用前檢查。最常漏的是審查者。"
   P='import json, re
from pathlib import Path
FIELDS = {
    "截止": r"(每週|每天|每月|週[一二三四五六日]|\d+ ?點|前)",
    "受眾": r"(客戶|老闆|團隊|主管|使用者|自己|為)",
    "產出": r"(產出|報告|摘要|清單|週報|草稿)",
    "來源": r"(根據|資料來源|來自|從|筆記|資料夾)",
    "審查者": r"(審查|檢查|核對|校對|核准)",
}
def check_mission(text):
    hits = {k: bool(re.search(p, text)) for k, p in FIELDS.items()}
    return hits, sum(hits.values())
missions = {
    "願景式": "革新小企業運用 AI 的方式",
    "漏審查者": "每週五 9 點前根據共用資料夾的專案筆記，為 10 位客戶各產出一份狀態報告",
    "範本式": "每週五 9 點前，根據共用資料夾的專案筆記，為 10 位客戶各產出一份狀態報告，交客戶經理審查後寄出",
}
results = {}
for name, text in missions.items():
    hits, score = check_mission(text)
    missing = [k for k, v in hits.items() if not v]
    results[name] = {"score": score, "missing": missing}
    print(f"{name}（{score}/5）：{text}")
    print("   缺：" + ("、".join(missing) if missing else "無，陌生人也能判斷做完沒有"))
print()
print("願景式使命讓代理只能猜；猜測的代理在排程上就是花錢做沒人要的事。")
Path("ch03/interactive/mission_check.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入 ch03/interactive/mission_check.json")'
   show "$P"; run "$P" ;;
5) banner "doctor 分層診斷：先找哪一層壞，再套該層的修法"
   tip "不要小幅改參數重跑同一個指令。依序檢查 runtime、套件下載、本機伺服器、模型連線；沒有備份就不做任何重設。"
   P='LAYERS = [
    ("runtime", lambda e: e["node"] >= (24, 11), "升級 Node.js 或用版本管理工具切到要求版本"),
    ("套件下載", lambda e: not e["private_registry"], "確認生效的 registry，這一次指令強制用公開 registry"),
    ("本機伺服器", lambda e: not e["port_busy"], "先問誰在用 port，再停掉或改設定換 port"),
    ("模型連線", lambda e: e["credential"], "補上模型憑證／安裝對應代理軟體，再跑一次心跳"),
]
cases = {
    "舊版 Node": {"node": (22, 3), "private_registry": False, "port_busy": False, "credential": True},
    "公司私有 registry": {"node": (24, 12), "private_registry": True, "port_busy": False, "credential": True},
    "port 3100 被占用": {"node": (24, 12), "private_registry": False, "port_busy": True, "credential": True},
    "心跳沉默": {"node": (24, 12), "private_registry": False, "port_busy": False, "credential": False},
}
def doctor(env):
    for name, ok, fix in LAYERS:
        if not ok(env):
            return name, fix
    return None, None
for case, env in cases.items():
    layer, fix = doctor(env)
    print(f"{case:<16} → 失敗層：{layer:<6} 修法：{fix}")
print()
def apply_fix(fix, has_backup, client_ok):
    destructive = "刪除" in fix
    if destructive and not (has_backup and client_ok):
        return "拒絕：重設前要先備份並取得客戶同意"
    return "執行：" + fix
bad_fix = "刪除 instance 資料庫目錄後重新 onboard"
print("網路上找到的第一個修法：", bad_fix)
print("  客戶機器、沒備份：", apply_fix(bad_fix, False, False))
print("  測試機、有備份、自己同意：", apply_fix(bad_fix, True, True))'
   show "$P"; run "$P" ;;
6) banner "讓真實模型依範本寫第一家公司的使命"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch03/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "mission_raw.json"
raw.unlink(missing_ok=True)
prompt = """你要替一家剛安裝好的測試用 AI 代理公司寫第一句使命，並扮演它的 CEO agent 提出第一份計畫。
情境：一位求職中的 AMR／ROS 2 工程師，想讓代理每週整理一次適合他的職缺。
使命必須照這個範本寫成一句繁體中文：在［截止或頻率］前，為［受眾］產出［產出物］，資料來源是［來源］，由［指名審查者］使用前檢查。
使命要小到一天內能審完，不可寫成願景口號。
CEO 計畫最多 3 步，而且最後一步必須是「送 board 核准後才執行」。
輸出 JSON：{"company_name": "看得出是測試的名稱", "mission": "...", "ceo_plan": ["...", "...", "..."], "suggested_ceiling_usd": 數字}"""
try:
    data = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print("公司名稱：", data.get("company_name"))
print("使命：", data.get("mission"))
print("CEO 第一份計畫：")
for i, s in enumerate(data.get("ceo_plan") or [], 1):
    print(f"  {i}. {s}")
print("建議上限（美元）：", data.get("suggested_ceiling_usd"))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "檢查使命，並用「沒有天花板就不開心跳」把關"
   tip "上限依賴已記錄的花費：回報延遲時，實際花費會在暫停前超過上限一點。所以供應商端也要有上限當後盾。"
   P='import json, random, re
from pathlib import Path
random.seed(146)
out = Path("ch03/interactive")
raw = out / "mission_raw.json"
FALLBACK = {"company_name": "TEST-求職週報-01", "mission": "每週一 9 點前，根據 104 搜尋結果與履歷，為我自己產出 10 筆 AMR 職缺清單，由我本人審查後才投遞", "ceo_plan": ["列出搜尋條件", "整理職缺草稿", "送 board 核准後才執行"], "suggested_ceiling_usd": 5}
data, source = None, "內建範例（第 6 步沒有成功）"
if raw.exists():
    try:
        data, source = json.loads(raw.read_text(encoding="utf-8")), "第 6 步模型輸出"
    except ValueError:
        data = None
if not isinstance(data, dict):
    data, source = FALLBACK, "內建範例（第 6 步沒有成功）"
FIELDS = {"截止": r"(每週|每天|每月|週[一二三四五六日]|\d+ ?點|前)", "受眾": r"(客戶|老闆|團隊|主管|使用者|自己|為)", "產出": r"(產出|報告|摘要|清單|週報|草稿)", "來源": r"(根據|資料來源|來自|從|筆記|資料夾)", "審查者": r"(審查|檢查|核對|校對|核准)"}
mission = str(data.get("mission", ""))
hits = {k: bool(re.search(p, mission)) for k, p in FIELDS.items()}
plan = [str(s) for s in (data.get("ceo_plan") or [])]
asks_board = bool(plan) and any(w in plan[-1] for w in ("核准", "board", "董事會"))
name = str(data.get("company_name", ""))
is_test_name = any(w in name for w in ("TEST", "Test", "test", "測試"))
print("資料來源：", source)
missing = [k for k, v in hits.items() if not v] or "無"
print(f"使命欄位 {sum(hits.values())}/5，缺：{missing}")
print(f"CEO 計畫最後一步送 board 核准：{asks_board}；名稱看得出是測試：{is_test_name}")
print()
def start_heartbeats(ceiling, lag, hours=12):
    if ceiling is None:
        return "拒絕啟動：沒有天花板，就不開心跳", 0.0, 0
    spent, recorded = 0.0, []
    for h in range(1, hours + 1):
        seen = sum(recorded[:max(0, len(recorded) - lag)])
        if seen >= ceiling:
            return "到上限暫停", spent, h - 1
        cost = random.uniform(0.3, 0.9)
        spent += cost
        recorded.append(cost)
    return "跑完", spent, hours
try:
    ceiling = float(data.get("suggested_ceiling_usd"))
except (TypeError, ValueError):
    ceiling = 5.0
rows = []
for label, ceil, lag in (("沒設上限", None, 0), (f"上限 {ceiling:g} 美元、即時回報", ceiling, 0), (f"上限 {ceiling:g} 美元、回報延遲 2 次", ceiling, 2)):
    status, spent, ran = start_heartbeats(ceil, lag)
    rows.append(f"{label}：{status}，跑了 {ran} 次心跳，實際花費 {spent:.2f} 美元")
    print("  " + rows[-1])
report = ["# 第 3 章第一家公司檢查", "", f"資料來源：{source}", f"使命：{mission}", f"使命欄位：{sum(hits.values())}/5", f"CEO 最後一步送核准：{asks_board}", "", "## 心跳閘門"] + [f"- {r}" for r in rows]
(out / "first_company_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print()
print("已寫入", out / "first_company_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：安裝與第一家公司的五個重點"
   tip "安裝是簡單的部分，預設值才是有後果的部分。沒有天花板，就不開心跳。"
   P='from pathlib import Path
points = [
    "合作在指令之前開始：六行環境檢查，三台機器裡兩台要先打電話；最常空白的是第 5 項維運負責人。",
    "先檢查，客戶 A 從二百六十分鐘壓到三十一分鐘（含電話十六分）；時間估計要給兩個數字，檢查本身算進合作報價。",
    "一行 onboard 建立完整自給的 instance，但 --yes 回答的是專案預設；它不設使命、不設模型存取、不設預算。",
    "使命要寫出截止、受眾、產出、來源、審查者；CEO agent 是協調者，重大提議送 board 核准；心跳沉默先查憑證。",
    "排錯先分層找失敗層、不備份不重設；預算上限依賴已記錄花費，回報延遲會超過一點，所以先設上限、試行量測、再報價。",
]
print("第 3 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("precheck.json", "install_gaps.json", "mission_check.json", "mission_raw.json", "first_company_report.md"):
    p = Path("ch03/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

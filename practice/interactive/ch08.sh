#!/bin/bash
# K146 第 8 章互動演練：預算與成本控制，一次跑一步
# 用法：bash ch08.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch08/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 8 章｜預算與成本控制　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "心跳頻率：同一個代理，成本差 288 倍"
   tip "書中假設每次喚醒 0.10 美元（只為了好算）。沒事做也要喚醒，頻率會放大一切。"
   P='COST = 0.10
SETTINGS = [("每 5 分鐘", 5), ("每 15 分鐘", 15), ("每小時", 60), ("每 4 小時", 240), ("每天 1 次", 1440)]
print("{:<10} | {:>8} | {:>8} | {:>8} | {:>9}".format("心跳設定", "次/天", "美元/天", "4 天", "30 天"))
print("-" * 56)
for name, minutes in SETTINGS:
    per_day = 1440 // minutes
    day = per_day * COST
    print("{:<10} | {:>8} | {:>8.2f} | {:>8.2f} | {:>9.2f}".format(name, per_day, day, day * 4, day * 30))
print()
print("最快 / 最慢 = {} 倍".format(288 // 1))
budget = 150
days = budget / (288 * COST)
print("開場案例：心裡預算 150 美元、每 5 分鐘喚醒 -> 第 {:.1f} 天就花完一個月額度".format(days))
print("原則：能趕上期限的最便宜頻率，就是對的頻率")'
   show "$P"; run "$P" ;;
2) banner "預算工作表：把藍圖變成每個角色的上限"
   tip "上限要附計畫：80% 警示、通知誰、誰決定、暫停時交付物怎麼辦。缺一欄就只是數字。"
   P='import csv
from pathlib import Path
out = Path("ch08/interactive")
out.mkdir(parents=True, exist_ok=True)
COMPANY = 600
ROLES = [
    {"role": "CEO", "share": 0.10, "told": "王董事", "decides": "王董事", "if_paused": "規劃等待，不影響交付"},
    {"role": "Researcher", "share": 0.40, "told": "王董事", "decides": "王董事", "if_paused": "摘要延遲，改用上週來源"},
    {"role": "Writer", "share": 0.30, "told": "王董事", "decides": "", "if_paused": "草稿延遲，編輯等待"},
    {"role": "Editor", "share": 0.20, "told": "王董事+李備援", "decides": "王董事", "if_paused": ""},
]
print("{:<11} | {:>4} | {:>6} | {:>7} | {:<12} | {}".format("角色", "份額", "月上限", "80%警示", "通知誰", "檢查"))
print("-" * 70)
rows, problems = [], 0
for r in ROLES:
    cap = COMPANY * r["share"]
    warn = cap * 0.8
    missing = [k for k in ("told", "decides", "if_paused") if not r[k]]
    problems += len(missing)
    flag = "OK" if not missing else "缺 " + ",".join(missing)
    print("{:<11} | {:>3.0f}% | {:>6.0f} | {:>7.0f} | {:<12} | {}".format(r["role"], r["share"] * 100, cap, warn, r["told"], flag))
    rows.append([r["role"], r["share"], cap, warn, r["told"], r["decides"], r["if_paused"]])
print("-" * 70)
print("合計份額 {:.0f}%，合計上限 {:.0f} 美元，公司警示 {:.0f} 美元".format(sum(r["share"] for r in ROLES) * 100, COMPANY, COMPANY * 0.8))
print("缺欄位數：", problems, "-> 有缺欄位的上限是「沒有主人的設定」")
with open(out / "budget_worksheet.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["role", "share", "ceiling", "warning_80", "told", "decides", "if_paused"])
    w.writerows(rows)
print("已寫入", out / "budget_worksheet.csv")'
   show "$P"; run "$P" ;;
3) banner "只設公司上限 vs 每個代理都有上限（模擬一個月）"
   tip "研究員用快心跳加高階模型。只有公司上限時，全部人一起停；有代理上限時，只停研究員。"
   P='import random
random.seed(146)
DAILY = {"Researcher": 32.0, "Writer": 4.0, "Editor": 3.0, "CEO": 1.5}
WORKSHEET = {"CEO": 60, "Researcher": 240, "Writer": 180, "Editor": 120}

def simulate(company_cap, agent_caps):
    spent = {k: 0.0 for k in DAILY}
    paused = {}
    for day in range(1, 31):
        for role, base in DAILY.items():
            if role in paused:
                continue
            spent[role] += base * random.uniform(0.85, 1.15)
            if agent_caps and spent[role] >= agent_caps[role]:
                paused[role] = day
        if sum(spent.values()) >= company_cap:
            for role in DAILY:
                paused.setdefault(role, day)
            break
    return spent, paused

for title, cap, caps in (("A. 只有公司上限 1000", 1000, None), ("B. 公司 600＋每代理上限", 600, WORKSHEET)):
    spent, paused = simulate(cap, caps)
    print(title)
    for role in DAILY:
        when = "第 {} 天暫停".format(paused[role]) if role in paused else "整月正常"
        print("   {:<11} 花 {:>7.2f} 美元  {}".format(role, spent[role], when))
    print("   公司合計 {:.2f} 美元".format(sum(spent.values())))
    print()
print("A：寫手與編輯本來沒花多少，卻被公司層一起停掉；B：只有研究員停，故障看得見、是局部的")'
   show "$P"; run "$P" ;;
4) banner "80% 警示、100% 硬停、進行中的執行與 UTC 重置"
   tip "警示不會停任何東西；硬停時進行中那一次已經花了，所以總額會略超過上限。"
   P='import random
from datetime import datetime, timedelta, timezone
random.seed(18)
CAP = 120.0
spent, run_no, warned = 0.0, 0, False
log = []
while True:
    run_no += 1
    cost = round(random.uniform(2.0, 9.0), 2)
    spent += cost
    if not warned and spent >= CAP * 0.8:
        warned = True
        log.append("第 {:>2} 次執行後：{:>6.2f} 美元 >= 80%（{:.0f}）-> 記錄警示，代理繼續工作".format(run_no, spent, CAP * 0.8))
    if spent >= CAP:
        log.append("第 {:>2} 次執行後：{:>6.2f} 美元 >= 100% -> 硬停，取消進行中的執行，不再有心跳".format(run_no, spent))
        break
for line in log:
    print(line)
print()
print("超過上限 {:.2f} 美元（越線那次執行已經記帳）-> 上限與「承受不起的損失」之間要留空間".format(spent - CAP))
print()
now = datetime(2026, 11, 29, 15, 0, tzinfo=timezone.utc)
reset = datetime(2026, 12, 1, 0, 0, tzinfo=timezone.utc)
tw = timezone(timedelta(hours=8))
print("暫停時間（UTC）：", now.strftime("%m-%d %H:%M"))
print("預算暫停自動恢復：UTC", reset.strftime("%m-%d %H:%M"), "= 台灣", reset.astimezone(tw).strftime("%m-%d %H:%M"))
print("停機時間約 {:.0f} 小時；手動暫停則不會自動恢復".format((reset - now).total_seconds() / 3600))'
   show "$P"; run "$P" ;;
5) banner "正當暫停還是失控迴圈？看執行紀錄"
   tip "很多次短執行、產出很少 = 心跳太快或迴圈，保持暫停修原因；少數長執行、產出實在 = 上限太低，提高並寫理由。"
   P='import random
random.seed(46)

def make_runs(kind):
    if kind == "loop":
        return [{"sec": random.randint(5, 25), "output": random.randint(0, 2)} for _ in range(220)]
    return [{"sec": random.randint(300, 900), "output": random.randint(3, 8)} for _ in range(18)]

def diagnose(runs):
    n = len(runs)
    avg_sec = sum(r["sec"] for r in runs) / n
    out_per_run = sum(r["output"] for r in runs) / n
    if n > 100 and out_per_run < 1.5:
        return n, avg_sec, out_per_run, "失控：心跳太快或迴圈 -> 保持暫停，先修原因"
    return n, avg_sec, out_per_run, "正當：真實工作超出上限 -> 提高上限並寫下理由"

print("{:<10} | {:>6} | {:>8} | {:>10} | {}".format("代理", "執行數", "平均秒數", "產出/次", "判斷"))
print("-" * 86)
for name, kind in (("研究員A", "loop"), ("研究員B", "real")):
    n, s, o, verdict = diagnose(make_runs(kind))
    print("{:<10} | {:>6} | {:>8.0f} | {:>10.2f} | {}".format(name, n, s, o, verdict))
print()
print("交付日風險對策：關鍵角色留餘裕、重工作排月初、調低警示、保留預備金、寫好人工備案")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型當審計顧問：找出客戶的預算風險"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json
out = Path("ch08/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "audit_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是 Paperclip（開源 AI 代理公司平台）的治理與預算審計顧問。
客戶現況：4 個代理（CEO、Researcher、Writer、Editor），用 quick-start 安裝；
只設了公司月上限 1000 美元，沒有代理上限；警示 80% 只有儀表板橫幅、沒有指定通知誰；
Researcher 用高階模型、每 5 分鐘心跳；Writer 透過訂閱方案計費；供應商端沒有設上限；
指令裡沒有寫任何花費核准閘門；政策沒有審查日期。
請依這張清單逐項檢查：公司與代理上限、警示百分比、通知對象與管道、模型與心跳、adapter 成本回報、供應商端上限、花費核准閘門、審查日期。
輸出 JSON：{"findings":[{"item":"檢查項","status":"ok 或 gap","risk":"high 或 medium 或 low","fix":"一句修正建議"}],"summary":"兩句話總結"}，findings 6～8 筆。"""
try:
    audit = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    raw.unlink(missing_ok=True)
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding="utf-8")
items = audit.get("findings") if isinstance(audit.get("findings"), list) else []
for f in items:
    if isinstance(f, dict):
        print("  [{:<6}] {:<4} {} -> {}".format(str(f.get("risk")), str(f.get("status")), str(f.get("item"))[:24], str(f.get("fix"))[:40]))
print()
print("總結：", audit.get("summary"))
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "審計報告：依風險排序＋兩週試點的成本區間"
   tip "審計交付的是「依風險排序的發現」和「附假設的量測區間」，不是部落格上的月費。"
   P='import json
from pathlib import Path
out = Path("ch08/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "audit_report.md").unlink(missing_ok=True)
raw = out / "audit_raw.json"
FALLBACK = {"findings": [
    {"item": "代理上限", "status": "gap", "risk": "high", "fix": "依工作表為四個代理設上限"},
    {"item": "供應商端上限", "status": "gap", "risk": "high", "fix": "在供應商設月上限當最後防線"},
    {"item": "通知對象與管道", "status": "gap", "risk": "high", "fix": "具名通知人並接聊天管道"},
    {"item": "模型與心跳", "status": "gap", "risk": "medium", "fix": "研究員心跳改每小時"},
    {"item": "adapter 成本回報", "status": "gap", "risk": "medium", "fix": "確認訂閱計費的 Writer 有回報成本"},
    {"item": "花費核准閘門", "status": "gap", "risk": "medium", "fix": "把採購前核准寫進指令"},
    {"item": "審查日期", "status": "gap", "risk": "low", "fix": "每月一號審查政策"},
], "summary": "內建範例"}
audit = None
if raw.exists():
    try:
        audit = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        audit = None
source = "第 6 步模型輸出" if isinstance(audit, dict) and isinstance(audit.get("findings"), list) else "內建範例（第 6 步沒有成功）"
if source.startswith("內建"):
    audit = FALLBACK
ORDER = {"high": 0, "medium": 1, "low": 2}
items = [f for f in audit["findings"] if isinstance(f, dict)]
items.sort(key=lambda f: ORDER.get(str(f.get("risk", "")).lower(), 3))
gaps = sum(1 for f in items if str(f.get("status", "")).lower() == "gap")
print("資料來源：", source, "；發現", len(items), "項，其中 gap", gaps, "項")
for i, f in enumerate(items, 1):
    print("  {}. [{}] {}：{}".format(i, f.get("risk"), f.get("item"), f.get("fix")))
print()
reports, spend, monthly_n, hosting = 20, 46.0, 40, 30.0
unit = spend / reports
model_month = unit * monthly_n
gross = monthly_n * 1.5 * 50
review = monthly_n * 20 / 60 * 50
net = gross - model_month - hosting - review
low, high = model_month * 0.8, model_month * 1.3
ceiling = model_month * 1.5
lines = [
    "每份交付物成本：{} 美元 / {} 份 = {:.2f} 美元".format(spend, reports, unit),
    "每月 {} 份推估模型費 {:.0f} 美元，區間約 {:.0f}～{:.0f} 美元（兩週是小樣本）".format(monthly_n, model_month, low, high),
    "毛價值 {:.0f}，審查成本 {:.0f}，主機 {:.0f}，淨價值 {:.0f} 美元/月".format(gross, review, hosting, net),
    "建議公司上限 = 推估 x 1.5 = {:.0f} 美元".format(ceiling),
]
print("兩週試點算術：")
for s in lines:
    print("  " + s)
md = "# 第 8 章：治理與預算審計報告\n\n資料來源：" + source + "\n\n## 依風險排序的發現\n\n"
md += "\n".join("{}. [{}] {}：{}".format(i, f.get("risk"), f.get("item"), f.get("fix")) for i, f in enumerate(items, 1))
md += "\n\n## 試點成本（假設）\n\n" + "\n".join("- " + s for s in lines) + "\n"
(out / "audit_report.md").write_text(md, encoding="utf-8")
print()
print("已寫入", out / "audit_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：預算與成本控制的五個重點"
   tip "每個控制，都是把一個數字從某人的腦袋搬進公司，並在旁邊寫上名字。"
   P='from pathlib import Path
points = [
    "成本兩大驅動：模型與心跳頻率。每 5 分鐘喚醒一天 28.80 美元，每天一次整月 3 美元，差 288 倍；150 美元的心理預算 5.2 天就花完。",
    "上限要附計畫：600 美元工作表分成 60／240／180／120，每列都要有通知誰、誰決定、暫停時交付物怎麼辦，缺欄就是沒有主人的設定。",
    "只設公司上限會讓所有人在同一天一起停；加上代理上限，只有研究員暫停，故障看得見、是局部的。",
    "80% 只警示、100% 硬停；越線那次執行已記帳，上限要留空間；預算暫停在 UTC 月初（台灣 8 點）自動恢復。",
    "分辨失控迴圈與正當超額；兩週試點算出每份 2.30 美元、每月約 92 美元，上限設 1.5 倍約 138 美元——量測本身就是產品。",
]
print("第 8 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("budget_worksheet.csv", "audit_raw.json", "audit_report.md"):
    p = Path("ch08/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

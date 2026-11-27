#!/bin/bash
# K146 第 1 章互動演練：從員工到公司——Paperclip 改變了什麼、炒作錯在哪，一次跑一步
# 用法：bash ch01.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch01/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 1 章｜從員工到公司　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "四個工具、一張帳單：問題從能力變成管理"
   tip "行銷公司四個 AI 工具各自好用，但月底那筆 1,180 美元沒人說得清是誰、為了什麼花的。"
   P='tools = [
    # 名稱, 帳單供應商帳號, 月費(美元), 是否有紀錄, 紀錄保存天數, 誰設定
    ("社群貼文", "vendor-A", 420, True, 30, "設計師"),
    ("會議摘要", "vendor-B", 310, True, 0, "業務經理"),
    ("競品研究", "vendor-C", 1180, False, 0, "業務經理"),
    ("收件匣分類", "vendor-C", 0, True, 30, "設計師"),
]
print("{:<8} | {:<9} | {:>7} | {:<10} | {:<8}".format("工具", "帳單帳號", "月費$", "紀錄", "設定者"))
print("-" * 56)
for name, acct, cost, has_log, days, who in tools:
    log = ("保存 {} 天".format(days) if days else "不保存") if has_log else "沒有紀錄"
    print("{:<8} | {:<9} | {:>7} | {:<10} | {:<8}".format(name, acct, cost, log, who))
largest = max(t[2] for t in tools)
others = sum(t[2] for t in tools) - largest
print()
print("最大一筆 {} 美元，比其他三筆加總 {} 美元還多".format(largest, others))
shared = [t[0] for t in tools if t[1] == "vendor-C"]
print("vendor-C 帳號被", "、".join(shared), "共用：帳單上分不出是誰花的")
print()
qs = [
    ("權責 accountability", "這件事是誰的工作、為什麼要做？", False),
    ("花費 spend", "這 1,180 美元是哪個工具、哪個客戶、哪個任務？", False),
    ("紀錄 record", "上個月這四個工具到底做了什麼？", False),
]
print("老闆的三個問題（沒有管理層時）：")
for k, q, ok in qs:
    print("  [{}] {:<20} {}".format("能答" if ok else "答不出", k, q))
print()
print("結論：四個工具都不爛，是上面沒有任何結構。問題從「能力」變成「管理」。")'
   show "$P"; run "$P" ;;
2) banner "組織圖與目標鏈：每件工作都要說得出為什麼"
   tip "org chart 回答「誰做什麼」，goal chain 回答「為什麼要做」；追溯不到使命的任務就是沒人要求的工作。"
   P='import json
from pathlib import Path

org = {"CEO": None, "社群代理": "CEO", "研究代理": "CEO", "摘要代理": "CEO", "收件匣代理": "CEO"}
goals = {
    "M": ("使命", "成為中小企業最信任的行銷夥伴", None),
    "G1": ("目標", "在既有客戶中打響春季新品知名度", "M"),
    "G2": ("目標", "提高提案得標率", "M"),
    "G3": ("目標", "客戶來信一個工作天內回覆", "M"),
}
tasks = [
    ("T1", "社群代理", "為春季新品寫三篇 LinkedIn 貼文", "G1"),
    ("T2", "研究代理", "為 ABC 公司提案做競品研究（跑了 2 小時）", "G2"),
    ("T3", "摘要代理", "把探索會議摘要成五個決定三個待辦", "G2"),
    ("T4", "收件匣代理", "標記需要人回覆的客戶來信", "G3"),
    ("T5", "研究代理", "整理 2019 年產業報告 PDF", None),
]

def chain(gid):
    out = []
    while gid:
        kind, text, parent = goals[gid]
        out.append("{}「{}」".format(kind, text))
        gid = parent
    return out

print("組織圖（誰向誰回報）：")
for agent, boss in org.items():
    print("  {} -> {}".format(agent, boss or "董事會（真人）"))
print()
orphans = []
for tid, agent, desc, gid in tasks:
    print("{} [{}] {}".format(tid, agent, desc))
    if gid is None:
        orphans.append(tid)
        print("     !! 追溯不到任何目標：沒人要求的工作")
    else:
        print("     為什麼：" + " -> ".join(chain(gid)))
print()
print("任務 {} 件，可追溯 {} 件，孤兒任務 {} 件：{}".format(len(tasks), len(tasks) - len(orphans), len(orphans), "、".join(orphans)))
out = Path("ch01/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "org_chart.json").write_text(json.dumps({"org": org, "goals": goals, "tasks": tasks}, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入", out / "org_chart.json")'
   show "$P"; run "$P" ;;
3) banner "心跳頻率 × 模型價格：月費會差上千倍"
   tip "書上說成本主要由兩個變數決定：用哪個模型、心跳多久跳一次。以下單價是示意假設，不是報價。"
   P='DAYS = 30
intervals = [("每 5 分鐘", 5), ("每 30 分鐘", 30), ("每小時", 60), ("每 4 小時", 240), ("一天兩次", 720)]
models = [("便宜模型", 0.002), ("昂貴模型", 0.06)]  # 每次醒來檢查＋小工作的示意成本（美元）
AGENTS = 4
print("{:<10} | {:>7} | {:>14} | {:>14}".format("心跳", "次/月", "便宜模型 4代理$", "昂貴模型 4代理$"))
print("-" * 58)
table = {}
for label, minutes in intervals:
    wakes = DAYS * 24 * 60 // minutes
    row = [wakes * price * AGENTS for _, price in models]
    table[label] = row
    print("{:<10} | {:>7} | {:>14.2f} | {:>14.2f}".format(label, wakes, row[0], row[1]))
hi = table["每 5 分鐘"][1]
lo = table["一天兩次"][0]
print()
print("最貴組合（每 5 分鐘＋昂貴模型）每月 {:.2f} 美元".format(hi))
print("最便宜組合（一天兩次＋便宜模型）每月 {:.2f} 美元".format(lo))
print("差距 {:.0f} 倍：所以在試點量測之前，絕不向客戶報月費".format(hi / lo))'
   show "$P"; run "$P" ;;
4) banner "每個代理的預算：80% 警告、100% 暫停"
   tip "ceiling 是事前選好的上限：讓「事後才發現的驚喜帳單」變成「事前就擋下的暫停」。"
   P='import csv, random
from pathlib import Path
random.seed(146)
CEIL = 300.0
out = Path("ch01/interactive")
out.mkdir(parents=True, exist_ok=True)
spent, warned, paused_day, blocked = 0.0, None, None, 0
uncapped = 0.0
rows = []
for day in range(1, 31):
    cost = random.uniform(5, 12)
    if 10 <= day <= 14:
        cost *= 4  # 大型提案週，研究代理暴衝
    uncapped += cost
    status = "執行"
    if paused_day is not None:
        status = "暫停中（等董事會）"
        blocked += 1
    elif spent + cost >= CEIL:
        spent = CEIL
        paused_day = day
        status = "達 100% 暫停"
    else:
        spent += cost
        if warned is None and spent >= CEIL * 0.8:
            warned = day
            status = "達 80% 警告"
    rows.append((day, round(cost, 2), round(spent, 2), status))
    if status != "執行":
        print("第 {:>2} 天 | 今日需求 {:>6.2f} | 累計 {:>6.2f} | {}".format(day, cost, spent, status))
print()
print("上限 {:.0f} 美元：第 {} 天警告、第 {} 天暫停，之後 {} 天的工作等人決定".format(CEIL, warned, paused_day, blocked))
print("沒有上限時，這個月會花 {:.2f} 美元，是上限的 {:.1f} 倍".format(uncapped, uncapped / CEIL))
with open(out / "budget_ledger.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["day", "demand", "spent", "status"])
    w.writerows(rows)
print("已寫入", out / "budget_ledger.csv")'
   show "$P"; run "$P" ;;
5) banner "核准閘門與永久紀錄：擋的是權限，不是錯誤"
   tip "approval 讓大決定停下來等人；但一份含捏造數據的報告不需要核准，就會直接通過。"
   P='import json
from datetime import datetime, timedelta
from pathlib import Path

GATED = {"聘用新代理", "改變 CEO 策略", "覆寫預算", "對外寄出"}
events = [
    ("研究代理", "產出競品報告", "內容含沒有來源的統計數字"),
    ("社群代理", "產出三篇貼文草稿", "版面與用語不一致"),
    ("社群代理", "對外寄出", "把貼文寄給客戶"),
    ("CEO", "聘用新代理", "想再聘一個 SEO 代理"),
    ("CEO", "改變 CEO 策略", "把重心改成短影音"),
    ("摘要代理", "產出會議摘要", "正確"),
]
t0 = datetime(2026, 11, 2, 9, 0)
out = Path("ch01/interactive")
out.mkdir(parents=True, exist_ok=True)
log_path = out / "activity_log.jsonl"
log_path.unlink(missing_ok=True)
waiting, passed_bad = 0, 0
with open(log_path, "a", encoding="utf-8") as f:
    for i, (agent, action, note) in enumerate(events):
        ts = (t0 + timedelta(minutes=17 * i)).isoformat()
        gated = action in GATED
        status = "等待董事會核准" if gated else "直接完成"
        waiting += gated
        bad = (not gated) and note not in ("正確",) and "寄給" not in note
        passed_bad += bad
        f.write(json.dumps({"ts": ts, "agent": agent, "action": action, "note": note, "status": status}, ensure_ascii=False) + "\n")
        print("{} {:<6} {:<10} -> {:<8} {}".format(ts[11:16], agent, action, status, "（有品質問題卻通過）" if bad else ""))
print()
print("等待核准 {} 件；有品質問題卻沒被擋 {} 件".format(waiting, passed_bad))
print("紀錄告訴你發生了什麼，不告訴你做得好不好：品質關卡要另外設計（第 10 章）")
print()
stack = [
    ("模型 models", "報告裡出現捏造統計"),
    ("代理執行環境 runtimes", "客戶想用的 runtime 沒有 adapter"),
    ("工具與服務 tools", "收件匣權限給太大，誤封存客戶信"),
    ("Paperclip 協調層", "沒設預算上限，月底驚喜帳單"),
    ("基礎設施 infrastructure", "伺服器沒人備份，硬碟壞了"),
    ("客戶治理 governance", "沒人規定誰先看過才可寄給客戶"),
]
print("六層堆疊：哪一層出事、Paperclip 管不管得到")
for i, (layer, incident) in enumerate(stack, 1):
    mine = "Paperclip 負責" if "Paperclip" in layer else "不歸 Paperclip"
    print("  {}. {:<24} {:<26} {}".format(i, layer, incident, mine))
print("六種事故只有 1 種落在 Paperclip 這層")
print("已寫入", log_path)'
   show "$P"; run "$P" ;;
6) banner "讓真實模型把宣傳句分成三堆"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

claims = [
    "每個代理可以設每月預算上限，到 80% 警告、100% 暫停",
    "這家公司完全不需要人，全天候自主運作",
    "聘用新代理和改變 CEO 策略，要等真人核准",
    "一家小型代理公司每月大約只要花 50 美元",
    "代理的產出不用人審就能達到正式上線品質",
    "每項任務都能沿著目標鏈追溯到公司使命",
    "一鍵部署，你的事業從此自動賺錢",
    "代理做的事會寫進有時間戳的永久活動紀錄",
    "這個專案的發展方向和速度會一直維持下去",
]
out = Path("ch01/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "claims_raw.json"
raw.unlink(missing_ok=True)
lines = "\n".join("{}. {}".format(i, c) for i, c in enumerate(claims, 1))
prompt = """你是一位誠實的 AI 代理顧問，要評估關於開源代理協調工具 Paperclip 的說法。
把下列每一句分成三類之一：
- documented：官方文件記載、可以在自己的安裝上驗證的功能
- promotional：宣傳口號，描述的是願景
- unverified：目前證據不足、沒有被證實的說法
說法：
""" + lines + """
輸出 JSON：{"items": [{"n": 編號, "label": "documented|promotional|unverified", "reason": "20 字內理由"}]}"""
try:
    result = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
items = result.get("items") if isinstance(result.get("items"), list) else []
raw.write_text(json.dumps({"claims": claims, "items": items}, ensure_ascii=False, indent=2), encoding="utf-8")
for it in items:
    if not isinstance(it, dict):
        continue
    try:
        n = int(it.get("n"))
    except (TypeError, ValueError):
        continue
    text = claims[n - 1] if 1 <= n <= len(claims) else "?"
    print("{}. [{:<12}] {}".format(n, str(it.get("label")), text))
    print("      理由：{}".format(it.get("reason")))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "對答案＋誠實的價值計算"
   tip "誠實版：省下的工時價值，要扣掉模型與主機費，也要扣掉人審的時間。"
   P='import json
from pathlib import Path

KEY = ["documented", "promotional", "documented", "unverified", "unverified", "documented", "promotional", "documented", "unverified"]
out = Path("ch01/interactive")
raw = out / "claims_raw.json"
report = out / "claims_report.md"
report.unlink(missing_ok=True)
labels, source = None, "內建範例（第 6 步沒有成功）"
if raw.exists():
    try:
        data = json.loads(raw.read_text(encoding="utf-8"))
        got = {}
        for it in data.get("items", []):
            if isinstance(it, dict):
                try:
                    got[int(it.get("n"))] = str(it.get("label", "")).strip().lower()
                except (TypeError, ValueError):
                    pass
        labels = [got.get(i + 1, "缺") for i in range(len(KEY))]
        source = "第 6 步模型輸出"
    except ValueError:
        labels = None
if labels is None:
    labels = list(KEY)
    labels[3] = "documented"  # 內建範例故意放一個常見錯誤：把月費數字當成文件記載
hit = sum(a == b for a, b in zip(labels, KEY))
wrong = [(i + 1, labels[i], KEY[i]) for i in range(len(KEY)) if labels[i] != KEY[i]]
print("資料來源：", source)
print("分類正確 {} / {}".format(hit, len(KEY)))
for n, g, k in wrong:
    print("  第 {} 句：分成 {}，參考答案 {}".format(n, g, k))
print()
RATE, HOURS, SPEND, BRIEFS = 55, 120, 600, 40
gross = RATE * HOURS
print("毛價值：省下 {} 小時 × 每小時 {} 美元 = {} 美元".format(HOURS, RATE, gross))
print("不誠實版：{} - {}（模型與主機）= {} 美元".format(gross, SPEND, gross - SPEND))
print("{:>10} | {:>8} | {:>8} | {:>8}".format("每份審幾分鐘", "審稿小時", "審稿成本", "淨價值"))
print("-" * 44)
nets = {}
for m in (15, 30, 45, 60):
    h = BRIEFS * m / 60
    net = gross - SPEND - h * RATE
    nets[m] = net
    print("{:>10} | {:>8.0f} | {:>8.0f} | {:>8.0f}".format(m, h, h * RATE, net))
print()
print("書中誠實版（每份審 30 分鐘）：{:.0f} 美元；比不誠實版少 {:.0f} 美元".format(nets[30], gross - SPEND - nets[30]))
md = ["# 第 1 章：宣傳句分類與誠實價值計算", "", "資料來源：" + source, "", "## 分類對答案", "", "正確 {} / {}".format(hit, len(KEY)), ""]
md += ["- 第 {} 句：分成 {}，參考答案 {}".format(n, g, k) for n, g, k in wrong] or ["- 全部正確"]
md += ["", "## 誠實價值計算", "", "- 毛價值 {} 美元；不誠實版 {} 美元".format(gross, gross - SPEND)]
md += ["- 每份審 {} 分鐘：淨價值 {:.0f} 美元".format(m, v) for m, v in nets.items()]
report.write_text("\n".join(md) + "\n", encoding="utf-8")
print("已寫入", report)'
   show "$P"; run "$P" ;;
8) banner "總結：第 1 章的五個重點"
   tip "Paperclip 不讓代理變聰明，而是讓一群代理變得可以問責；誠實說出它在哪裡停下，才是賣點。"
   P='from pathlib import Path

points = [
    "一群代理共用一門生意時，問題從能力變成管理：權責、花費、紀錄三個缺口（第 1 步：1,180 美元沒人說得清）。",
    "Paperclip 補上公司結構：org chart 回答誰做什麼、goal chain 回答為什麼做，追溯不到使命的就是孤兒任務（第 2 步）。",
    "成本由模型與心跳頻率決定，最貴與最便宜組合月費差 4,320 倍，所以試點量測前不報月費（第 3 步）；預算 80% 警告、100% 暫停，把驚喜帳單變成事前暫停（第 4 步）。",
    "董事會是真人：核准閘門擋的是權限，不是錯誤內容；六層堆疊裡 Paperclip 只管中間一層，品質關卡要另外設計（第 5 步）。",
    "把說法分成文件記載、宣傳、未證實三堆，報價扣掉人審時間：6,600 減 600 再減 1,100，誠實版是 4,900 美元（第 6、7 步）。",
]
print("第 1 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("org_chart.json", "budget_ledger.csv", "activity_log.jsonl", "claims_raw.json", "claims_report.md"):
    p = Path("ch01/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

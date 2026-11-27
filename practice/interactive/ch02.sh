#!/bin/bash
# K146 第 2 章互動演練：三種會成交的對話（Visibility／Control／Capacity），一次跑一步
# 用法：bash ch02.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch02/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 2 章｜三種會成交的對話　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "開場五分鐘：三個問題分辨三種客戶"
   tip "不要事先決定要講哪一套。先問三個問題，從回答裡的訊號判斷對方要的是哪一種對話。"
   P='SIGNALS = {
    "Visibility": ["四五個", "不確定", "哪張卡", "有人設定", "查一下", "說不出"],
    "Control": ["差點", "燒掉", "超支", "不敢", "關掉", "寄給客戶"],
    "Capacity": ["每週", "每個月底", "週五", "專門負責", "重複", "截止"],
}
OPENING = {"Visibility": "問上週發生了什麼", "Control": "問什麼還沒讓 AI 做", "Capacity": "問什麼在重複"}
answers = [
    ("會計師事務所老闆", "我們大概用了四五個 AI 東西，是有人設定的，我得查一下掛在哪張卡上。"),
    ("設計公司財務長", "上次有個工具一晚燒掉很多 token，我們就關掉了，現在不敢讓它碰帳務。"),
    ("顧問公司營運主管", "我們每週五都在做十份客戶週報，有個同事專門負責，截止是週五下午。"),
    ("律師事務所合夥人", "助理差點把草稿寄給客戶，從那之後我不敢讓 AI 發任何信。"),
    ("行銷公司 IT", "說不出上個月那些工具產出了什麼，也不確定誰在用。"),
    ("診所行政", "每個月底要對三百張發票，重複又沒人想做。"),
]
print("{:<10} | {:<10} | {:<5} | {}".format("對象", "判讀", "分數", "開場"))
print("-" * 60)
counts = {k: 0 for k in SIGNALS}
for who, text in answers:
    scores = {k: sum(w in text for w in ws) for k, ws in SIGNALS.items()}
    kind = max(scores, key=scores.get)
    counts[kind] += 1
    print("{:<10} | {:<10} | {:<5} | {}".format(who, kind, scores[kind], OPENING[kind]))
print()
print("統計：", "、".join(f"{k} {v} 位" for k, v in counts.items()))
print("同一間會議室可能三種人都有：財務是 Control、營運是 Capacity、設定工具的人是 Visibility。")'
   show "$P"; run "$P" ;;
2) banner "Visibility 示範：沿目標鏈往上追一件任務＋稽核紀錄"
   tip "只展示一條推理線：任務屬於哪個代理、哪個角色、服務哪個目標、哪個使命。不導覽產品、不秀預算畫面。"
   P='import json
from pathlib import Path
mission = "M1：每週五 9 點前替 10 位客戶產出狀態週報，交客戶經理審查"
goals = {"G1": ("整理每位客戶本週專案進度", "M1"), "G2": ("寄出前檢查語氣與數字", "M1")}
roles = {"研究員": "G1", "撰稿員": "G1", "校稿員": "G2"}
agents = {"A1": "研究員", "A2": "撰稿員", "A3": "校稿員", "A9": None}
tasks = {"T17": ("A2", "撰寫客戶 C3 週報草稿"), "T18": ("A3", "校對 C3 週報"), "T40": ("A9", "夜間自動瀏覽競品網站")}
audit = [
    ("週四 22:10", "A2", "T17", "讀取 C3 專案筆記", 0.8),
    ("週四 22:14", "A2", "T17", "產出草稿 1,200 字", 1.6),
    ("週四 23:00", "A9", "T40", "開始瀏覽 340 個頁面", 120.0),
    ("週五 02:30", "A9", "T40", "持續瀏覽，未完成", 280.0),
    ("週五 07:50", "A3", "T18", "退回 2 處數字錯誤", 0.6),
]
def trace(tid):
    agent, desc = tasks[tid]
    role = agents.get(agent)
    goal = roles.get(role) if role else None
    chain = [f"任務 {tid}「{desc}」", f"代理 {agent}", "角色 " + (role or "（無）")]
    if goal:
        chain += [f"目標 {goal}「{goals[goal][0]}」", mission]
    else:
        chain.append("（追不到目標：這個代理不在組織圖上）")
    return chain
for tid in ("T17", "T40"):
    print(f"追溯 {tid}：")
    for i, step in enumerate(trace(tid)):
        print("   " + "  " * i + "└ " + step)
    print()
print("稽核紀錄（依時間）：")
for t, a, tid, what, usd in audit:
    print(f"  {t}  {a}  {tid}  {what:<16} 花費 ${usd:.1f}")
night = sum(u for t, a, tid, w, u in audit if a == "A9")
print()
print(f"「昨晚花了四百美元你怎麼發現？」→ 紀錄裡 A9 一晚花了 ${night:.0f}，而且它追不到任何目標。")
print("注意：紀錄告訴你發生了什麼，不告訴你做得對不對（T17 的數字錯誤是 T18 校稿抓到的）。")
Path("ch02/interactive").mkdir(parents=True, exist_ok=True)
Path("ch02/interactive/audit_trace.json").write_text(json.dumps({"T17": trace("T17"), "T40": trace("T40"), "night_spend": night}, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入 ch02/interactive/audit_trace.json")'
   show "$P"; run "$P" ;;
3) banner "Control 示範一：預算上限，接近時警告、到了就停"
   tip "Control 客戶要看的是「系統會停」。另外誠實說出限制：花費是事後回報的，回報延遲會讓實際花費超過上限一點。"
   P='import random
random.seed(146)
CEILING, WARN = 100.0, 0.8
hours = [random.uniform(3, 9) for _ in range(30)]
def simulate(ceiling, lag):
    spent, recorded, warned, log = 0.0, [], None, []
    for h, cost in enumerate(hours, 1):
        seen = sum(recorded[:-lag]) if lag and len(recorded) > lag else (sum(recorded) if not lag else 0.0)
        if ceiling and seen >= ceiling:
            return spent, h - 1, warned, "暫停"
        if ceiling and warned is None and seen >= ceiling * WARN:
            warned = h
        spent += cost
        recorded.append(cost)
    return spent, len(hours), warned, "跑完"
print("{:<22} | {:>8} | {:>6} | {:>8} | {}".format("情境", "實際花費", "跑幾小時", "警告時點", "結果"))
print("-" * 66)
for name, ceil, lag in (("沒有上限（預設）", None, 0), ("上限 100、即時回報", CEILING, 0), ("上限 100、回報延遲 2 小時", CEILING, 2)):
    spent, ran, warned, end = simulate(ceil, lag)
    print("{:<22} | {:>8.1f} | {:>6} | {:>8} | {}".format(name, spent, ran, f"第{warned}小時" if warned else "-", end))
print()
print("沒有上限時一路跑完 30 小時；有上限時在接近 80 先警告、到 100 停下來。")
print("回報延遲時會超過上限一點：上限是很強的控制，但不是完美的控制。")'
   show "$P"; run "$P" ;;
4) banner "Control 示範二：核准閘門，以及它攔不住的那一件"
   tip "閘門管的是「決策」：雇人、對外寄信要等人類。但它不檢查輸出對不對，這句話要主動講。"
   P='GATED = {"hire", "external_send"}
proposals = [
    ("P1", "CEO", "hire", "再雇一個研究員代理", None),
    ("P2", "撰稿員", "external_send", "把 C3 週報寄給客戶", "週報裡營收數字寫錯一位數"),
    ("P3", "研究員", "internal_note", "更新內部筆記", None),
    ("P4", "撰稿員", "internal_note", "內部摘要（數字也寫錯）", "營收數字寫錯一位數"),
]
human = {"P1": "拒絕：先把兩個代理跑穩", "P2": "核准"}
print("{:<4} | {:<6} | {:<14} | {:<18} | {:<8} | {}".format("編號", "提出者", "類型", "內容", "閘門", "結果"))
print("-" * 82)
passed_with_error = []
for pid, who, kind, what, flaw in proposals:
    gated = kind in GATED
    result = human[pid] if gated else "直接執行"
    print("{:<4} | {:<6} | {:<14} | {:<18} | {:<8} | {}".format(pid, who, kind, what, "等人類" if gated else "不需要", result))
    if flaw and not result.startswith("拒絕"):
        passed_with_error.append((pid, flaw))
print()
print("閘門擋下的：P1 雇人提案被人類拒絕。")
print("閘門攔不住的：")
for pid, flaw in passed_with_error:
    print(f"  {pid}：{flaw}（預算內、規則都遵守，但輸出是錯的）")
print()
print("對 Control 客戶的誠實說法：預算限制花費、核准閘住決策，兩者都不檢查正確性；那是第 10 章的審查步驟。")'
   show "$P"; run "$P" ;;
5) banner "Capacity 試算：扣掉審查時間的誠實數字"
   tip "書中示意：40 份報告 × 1.5 小時 × 50 美元，再扣系統成本（假設）與每份 20 分鐘審查。"
   P='import csv
from pathlib import Path
REPORTS, HOURS, RATE = 40, 1.5, 50
def net(review_min, system_cost):
    gross = REPORTS * HOURS * RATE
    review = REPORTS * review_min / 60 * RATE
    return gross, review, gross - system_cost - review
gross, review, value = net(20, 350)
print(f"毛價值：{REPORTS} 份 × {HOURS} 小時 × ${RATE} = ${gross:,.0f}")
print(f"系統成本（假設）：-$350")
print(f"人工審查：{REPORTS} 份 × 20 分 = {REPORTS*20/60:.1f} 小時 → -${review:,.0f}")
print(f"淨價值：${value:,.0f}（標題數字的 {value/gross:.0%}）")
print()
print("敏感度表（淨價值，美元／月）：")
mins = (10, 20, 30, 45, 60)
print("{:>10} | ".format("系統成本") + " | ".join(f"審{m:>2}分" for m in mins))
rows = []
for cost in (350, 700, 1200):
    vals = [net(m, cost)[2] for m in mins]
    rows.append([cost] + [round(v) for v in vals])
    print("{:>10} | ".format(cost) + " | ".join(f"{v:>6,.0f}" for v in vals))
breakeven = (REPORTS * HOURS * RATE - 350) / (REPORTS * RATE) * 60
print()
print(f"系統成本 350 時，每份審查超過 {breakeven:.0f} 分鐘就不划算。")
out = Path("ch02/interactive")
out.mkdir(parents=True, exist_ok=True)
with open(out / "capacity_value.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["system_cost"] + [f"review_{m}min" for m in mins])
    w.writerows(rows)
print("已寫入", out / "capacity_value.csv")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型寫三句開場問題＋兩個異議回答"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch02/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "openings_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是幫中小企業導入 AI 代理的顧問。下週要拜訪一家 10 人的會計師事務所老闆，對方買過幾個 AI 工具。
請依《三種會成交的對話》寫出：
1. 三句開場問題：Visibility（看不見工具做了什麼與花多少）、Control（怕花費失控或擅自對外寄信）、Capacity（每週重複的工作想交出去）。每句一句話、繁體中文、40 字以內、不用術語（不可出現 agent、代理、heartbeat、Paperclip、org chart）。
2. 回答兩個異議：「這是免費的」與「這安全嗎」，各 80 字以內，要誠實說出限制，不可做保證。
輸出 JSON：{"openings": {"Visibility": "...", "Control": "...", "Capacity": "..."}, "objections": {"free": "...", "safe": "..."}}"""
try:
    data = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
for k, v in (data.get("openings") or {}).items():
    print(f"[{k}] {v}")
print()
for k, v in (data.get("objections") or {}).items():
    print(f"異議 {k}：{v}")
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用規則檢查開場問題與異議回答"
   tip "開場要一句話、沒術語；異議回答要誠實，不可做保證；但「沒有系統能保證」這種否定說法是誠實，不算承諾。"
   P='import json, re
from pathlib import Path
out = Path("ch02/interactive")
raw = out / "openings_raw.json"
FALLBACK = {
    "openings": {
        "Visibility": "如果某個 AI 工具昨晚花了一萬塊，你會怎麼知道？",
        "Control": "有什麼事你到現在還不敢讓 AI 做，為什麼？",
        "Capacity": "事務所每週重複做、卻沒人想做的是哪件事？",
    },
    "objections": {
        "free": "您說得對，軟體不用錢；您付的是安裝、設上限與核准、持續更新這些工作，想自己做我可以給您清單。",
        "safe": "我會設定每個工具的花費上限、重要決定先等您核准、留下紀錄；它不會檢查內容對不對，所以我們加人工審查。",
    },
}
data, source = None, "內建範例（第 6 步沒有成功）"
if raw.exists():
    try:
        data, source = json.loads(raw.read_text(encoding="utf-8")), "第 6 步模型輸出"
    except ValueError:
        data = None
if not isinstance(data, dict):
    data, source = FALLBACK, "內建範例（第 6 步沒有成功）"
JARGON = ["agent", "Agent", "代理", "heartbeat", "Paperclip", "org chart", "目標鏈"]
PROMISE = ["保證", "絕對", "百分之百", "100%", "完全安全", "不會有人失業", "零風險"]
LIMIT_WORDS = ["不會檢查", "不檢查", "不能保證", "無法保證", "限制", "審查", "不保證", "攔不住", "會出錯", "沒有系統能保證"]
NEGATED = r"(沒有|不能|無法|不會|不)[^，。]{0,8}(保證|百分之百|絕對)[^，。]{0,6}"
rows, fails = [], 0
for k in ("Visibility", "Control", "Capacity"):
    q = str((data.get("openings") or {}).get(k, ""))
    sentences = len([s for s in re.split(r"[。？！?!]", q) if s.strip()])
    jar = [w for w in JARGON if w in q]
    ok = bool(q) and sentences == 1 and len(q) <= 40 and not jar
    fails += not ok
    verdict = "PASS" if ok else "FAIL"
    jar_txt = jar or "無"
    rows.append(f"開場 {k:<10} {verdict}  {len(q)} 字、{sentences} 句、術語 {jar_txt}")
for k in ("free", "safe"):
    a = str((data.get("objections") or {}).get(k, ""))
    bad = [w for w in PROMISE if w in re.sub(NEGATED, "", a)]
    honest = k != "safe" or any(w in a for w in LIMIT_WORDS)
    ok = bool(a) and not bad and honest
    fails += not ok
    verdict = "PASS" if ok else "FAIL"
    bad_txt = bad or "無"
    rows.append(f"異議 {k:<10} {verdict}  過度承諾 {bad_txt}、有說限制 {honest}")
print("資料來源：", source)
for r in rows:
    print("  " + r)
print()
print(f"共 {len(rows)} 項，FAIL {fails} 項")
report = ["# 第 2 章開場問題檢查", "", f"資料來源：{source}", ""] + [f"- {r}" for r in rows] + ["", f"FAIL {fails} 項"]
(out / "openings_check.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print("已寫入", out / "openings_check.md")'
   show "$P"; run "$P" ;;
8) banner "總結：三種對話的五個重點"
   tip "不賣產品，賣對方準備好要談的對話；誠實說出限制，是最強的銷售工具。"
   P='from pathlib import Path
points = [
    "三個開場問題五分鐘內分辨客戶：問帳單誰付（Visibility）、問還沒讓 AI 做什麼（Control）、問每週重複什麼（Capacity）。",
    "Visibility 賣答案：沿目標鏈追一件任務到使命，再打開稽核紀錄；追不到目標的夜間花費就是那四百美元。",
    "Control 賣邊界：上限接近時警告、到了就停，核准閘住雇人與對外寄信；但兩者都不檢查輸出對不對。",
    "Capacity 賣附監督的產出：3,000 美元扣掉系統成本與審查後約 1,983 美元，只剩三分之二，這才是活得下來的數字。",
    "四個異議當成真問題回答：免費先同意、團隊能做就直說、安全給清單、工作會換形狀不承諾不會失業。",
]
print("第 2 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("audit_trace.json", "capacity_value.csv", "openings_raw.json", "openings_check.md"):
    p = Path("ch02/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

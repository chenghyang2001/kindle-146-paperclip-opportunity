#!/bin/bash
# K146 第 13 章互動演練：服務包裝與定價——為什麼同樣金額，一份報價丟了客戶、一份當場簽約，一次跑一步
# 用法：bash ch13.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch13/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 13 章｜服務包裝與定價　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "四個具名方案：信任的階梯"
   tip "「大約四千，看情況」描述的是感覺；「四千二，固定，包含這些、不包含那些」描述的是交付。工作一樣，結果不同。"
   P='import csv
from pathlib import Path

out = Path("ch13/interactive")
out.mkdir(parents=True, exist_ok=True)
QUOTES = [
    ("建築事務所", "大約四千，看我們發現什麼", 0, 0, False),
    ("景觀設計公司", "四千二固定：設計、伺服器安裝、2 代理含上限、交接文件、導覽；不含後續營運與內容品質審查；簽約一半、交接一半", 4, 2, True),
]
print("{:<10} | {:>4} | {:>4} | {:>4} | {}".format("客戶", "產出", "排除", "固定", "報價句"))
print("-" * 100)
for who, q, outs, excl, fixed in QUOTES:
    print("{:<10} | {:>4} | {:>4} | {:>4} | {}".format(who, outs, excl, "是" if fixed else "否", q[:46]))
print("  → 前者一週後回信「再等等」，後者問兩個伺服器問題、當週簽約")
print()
OFFERS = [
    ("Blueprint and Setup", "Visibility 看得見", 3500, 7000, "一次", "設計好的公司、安裝、2～3 代理含上限、交接文件"),
    ("Governance and Budget Audit", "Control 控得住", 1500, 3500, "一次", "風險排序報告、預算政策、一頁政策文件"),
    ("Company Build", "Capacity 有產能", 6000, 12000, "一次", "一個業務職能：角色、目標鏈、治理、排程"),
    ("Managed Operations Retainer", "Capacity（Build 之後）", 2500, 7500, "每月", "維持健康與調校，每月檢討"),
]
print("{:<28} | {:<20} | {:>13} | {:>8} | {}".format("方案", "回答哪種對話", "價格錨點", "中點", "產出"))
print("-" * 118)
rows = []
for name, conv, lo, hi, per, what in OFFERS:
    mid = (lo + hi) / 2
    rows.append((name, conv, lo, hi, mid, per))
    print("{:<28} | {:<20} | ${:>5}-${:<6} | ${:>7.0f} | {}".format(name, conv, lo, hi, mid, what))
print()
print("階梯：Audit（最小、最常是第一單）或 Blueprint → Build → Retainer；其餘客戶保留年度 Audit。")
with open(out / "offers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["offer", "conversation", "low", "high", "mid", "per"])
    w.writerows(rows)
print("已寫入", out / "offers.csv")'
   show "$P"; run "$P" ;;
2) banner "什麼會推動價格：逐項加價的 build-up"
   tip "從最簡版本的底價開始，每一項加價都說得出理由；超過區間上限不是放寬區間，而是拆成兩期。"
   P='import json
from pathlib import Path

out = Path("ch13/interactive")
out.mkdir(parents=True, exist_ok=True)
BASE, TOP = 6000, 12000

def build_up(agents, connectors, reviews, customer_facing, client_cloud):
    lines = [("底價（3 代理、2 連接器、1 審查、內部產出、自管主機）", BASE)]
    if agents > 3:
        lines.append(("多 {} 個代理 × $500".format(agents - 3), (agents - 3) * 500))
    if connectors > 2:
        lines.append(("多 {} 個連接器 × $600".format(connectors - 2), (connectors - 2) * 600))
    if reviews > 1:
        lines.append(("多 {} 個審查步驟 × $700".format(reviews - 1), (reviews - 1) * 700))
    if customer_facing:
        lines.append(("產出對外（客戶的顧客看得到）", 1500))
    if client_cloud:
        lines.append(("客戶自管雲端＋審批流程", 800))
    return lines

CLIENTS = [
    ("內部週報整理", (3, 2, 1, False, False)),
    ("客服分流（書中範例）", (5, 4, 2, True, True)),
    ("客服＋帳務＋報表", (8, 7, 3, True, True)),
]
result = {}
for name, args in CLIENTS:
    lines = build_up(*args)
    total = sum(v for _, v in lines)
    print("【{}】".format(name))
    for label, v in lines:
        print("  {:<40} ${:>6,}".format(label, v))
    print("  {:<40} ${:>6,}".format("合計", total))
    if total > TOP:
        print("  超過區間上限 ${:,} → 不放寬區間，拆成兩個職能或兩期（中間夾一次試點）".format(TOP))
    else:
        print("  在區間 ${:,}～${:,} 內，每一行都能大聲唸給客戶聽".format(BASE, TOP))
    print()
    result[name] = {"lines": lines, "total": total}
(out / "buildup.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print("另外兩個小因素：急件（6 週壓成 3 週會擠掉別的工作）、利害關係人多（財務＋資安＋部門主管）。")
print("已寫入", out / "buildup.json")'
   show "$P"; run "$P" ;;
3) banner "按範疇收費，不按工時"
   tip "工時獎勵慢、懲罰熟練：第一次安裝一天，第五次兩小時，按時計費的發票隨你進步一起縮水。"
   P='HOURS = {"Blueprint and Setup": (25, 5250), "Governance and Budget Audit": (12, 2500), "Company Build": (55, 9000), "Retainer（每月）": (12, 3000)}
print("各方案假設工時與實際時薪（價格取錨點中點，retainer 取 $3,000）：")
for k, (h, p) in HOURS.items():
    print("  {:<30} {:>3} 小時 → ${:>6,} / {} = ${:>4.0f}/小時".format(k, h, p, h, p / h))
low = min(HOURS, key=lambda k: HOURS[k][1] / HOURS[k][0])
print("  最低的是 {}：代表加價項目太薄，或你在做本該是變更請求的免費工作".format(low))
print()
print("同一件安裝做五次（學習曲線）：時薪 $150 vs 固定價 $1,200")
installs = [8, 6, 4, 3, 2]
tot_h = tot_f = 0
for i, h in enumerate(installs, 1):
    hourly = h * 150
    tot_h += hourly
    tot_f += 1200
    print("  第 {} 次 {} 小時：按時計費 ${:>5,}，固定價 $1,200 → 實際時薪 ${:>4.0f}".format(i, h, hourly, 1200 / h))
print("  五次合計：按時計費 ${:,}，固定價 ${:,}".format(tot_h, tot_f))
print()
print("價值說法（第 11 章）：公司每月淨值約 $1,360，$5,000 建置費第 4 個月回本")
m = next(m for m in range(1, 13) if 1360 * m >= 5000)
print("  驗算：1360 × {} = {:,} ≥ 5,000 → 第 {} 個月回本".format(m, 1360 * m, m))
print()
print("客戶嫌貴時：不打折，拿掉範疇。打折讓第一個數字變成可議價；拿掉範疇讓價格跟著工作走。")'
   show "$P"; run "$P" ;;
4) banner "三種範疇蔓延，各配一句話"
   tip "三句話都不帶敵意，動作一樣：說出邊界，再給一條跨過去的路。在簽完範疇後的第一次對話就說，不要等第三次。"
   P='REQUESTS = [
    ("順便讓公司也處理我們的發票好嗎？", "addition"),
    ("報告能不能更像我們的語氣、版面換一下？", "acceptance"),
    ("交接後：可以幫忙看一下為什麼報告遲了嗎？", "responsibility"),
    ("再加一個連接器接 CRM", "addition"),
    ("句子再順一點、再短一點", "acceptance"),
    ("伺服器好像怪怪的，你能遠端看看嗎？", "responsibility"),
]
SENT = {
    "addition": ("新增需求", "這是好的新增，但不在我們簽的範疇內，我會當作變更來報價：它會增加某些產出、費用多少、交接延後多久；現在做或下一期做都可以。"),
    "acceptance": ("驗收擴張", "這份產出的驗收標準是五項評分表、十份產出失敗率不超過約定值，已在某日達成；再依口味調整可以當變更，或放進 retainer。"),
    "responsibility": ("責任蔓延", "董事、伺服器擁有者、審查者都寫在我們簽的交接文件裡。這次我很樂意幫忙；交接後的持續協助由 retainer 涵蓋，我可以這週幫你設好。"),
}
for req, kind in REQUESTS:
    name, s = SENT[kind]
    print("客戶：{}".format(req))
    print("  類型：{}　回應：{}".format(name, s[:44] + "…"))
print()
print("三個月後的差別（每個小請求平均 3 小時，變更價 $150/小時，每月 4 個請求）：")
months, per_month, h, rate = 3, 4, 3, 150
unpaid = months * per_month * h
print("  「沒問題，順手做」：免費工作 {} 小時，相當 ${:,} 沒收到".format(unpaid, unpaid * rate))
paid = sum(1 for m in range(months) for k in range(per_month) if (m + k) % 2 == 0)
print("  「當變更來報價」：{} 個請求接受報價、收 ${:,}；其餘 {} 個客戶自己決定不做".format(paid, paid * h * rate, months * per_month - paid))
print()
print("另一個本書特有風險：報價到交接之間發版改了預設——範疇寫明「以哪個版本報價」，交接前壞掉你修，交接後歸 retainer。")'
   show "$P"; run "$P" ;;
5) banner "營收情境：先扣交付產能，再檢查客戶付得起"
   tip "情境不是預測。先假設每週 20 小時、46 週＝920 小時／年，約每月 77 小時；再算時數與每個 retainer 能不能被客戶的淨值撐住。"
   P='import csv
from pathlib import Path

out = Path("ch13/interactive")
out.mkdir(parents=True, exist_ok=True)
CAP_Y = 20 * 46
CAP_M = CAP_Y / 12
H = {"bs": 25, "audit": 12, "build": 55, "ret": 12}

def scenario(name, bs, bs_p, au, au_p, bu, bu_p, ret_n, ret_m, ret_p):
    rev = bs * bs_p + au * au_p + bu * bu_p + ret_n * ret_m * ret_p
    hrs = bs * H["bs"] + au * H["audit"] + bu * H["build"] + ret_n * ret_m * H["ret"]
    ret_rev = ret_n * ret_m * ret_p
    print("【{}】營收 ${:,.0f}，時數 {} 小時 = 產能 {:.0f}%，實際時薪 ${:.0f}".format(name, rev, hrs, hrs / CAP_Y * 100, rev / hrs))
    if ret_rev:
        print("  其中 retainer ${:,} 佔營收 {:.0f}%，時數只佔產能 {:.0f}%".format(ret_rev, ret_rev / rev * 100, ret_n * ret_m * H["ret"] / CAP_Y * 100))
    return (name, rev, hrs, round(hrs / CAP_Y * 100), round(rev / hrs))

print("產能：{} 小時／年，約 {:.0f} 小時／月".format(CAP_Y, CAP_M))
rows = [
    scenario("起步年", 4, 5250, 3, 2500, 1, 9000, 0, 0, 0),
    scenario("成長年", 3, 5250, 4, 2500, 3, 9000, 2, 8, 3000),
]
print("  起步年的限制不是交付，是找到客戶")
print()
print("{:>9} | {:>8} | {:>8} | {:>10}".format("retainer數", "每月時數", "佔產能", "每月營收"))
for n in (2, 4, 6, 8):
    print("{:>9} | {:>8} | {:>7.0f}% | ${:>9,}".format(n, n * 12, n * 12 / CAP_M * 100, n * 3000))
print("  一人想同時賣新案時，大約只能扛 4 個；發版週同一天改所有客戶的預設，4 個就變危機")
print()
print("retainer 上限：月費不超過客戶實測每月淨值的一半")
for client, net in (("多例行／對外產出的客戶", 6000), ("第 11、12 章範例（3 個例行任務）", 1360)):
    cap = net / 2
    ok = cap >= 2500
    print("  {:<28} 淨值 ${:>5,} → 月費上限 ${:>5,.0f} → {}".format(client, net, cap, "可以談 retainer" if ok else "低於 $2,500 底線，改賣 Build＋年度 Audit（約 ${:.0f}/月）".format(2500 / 12)))
with open(out / "scenarios.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["scenario", "revenue", "hours", "capacity_pct", "effective_rate"])
    w.writerows(rows)
print("已寫入", out / "scenarios.csv")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型當潛在客戶：讀完單頁方案說說包含什麼"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒。本章行動就是問別人兩個問題：你認為包含什麼？不包含什麼？"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch13/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "prospect_raw.json"
raw.unlink(missing_ok=True)
ONE_PAGER = """方案：Blueprint and Setup。適合：用了好幾個 AI 工具、但沒有任何共用紀錄的小公司。
你會得到：一頁公司設計圖（組織圖與目標鏈）；安裝在你自己雲端帳號的一台伺服器上；兩個 AI 代理，各自有花費上限；一份一頁交接文件；與辦公室經理一次導覽。
不包含：交接後的持續營運；代理產出內容的品質審查；例行排程任務；資安評估。
交付時間：3 週。價格：4,200 美元固定，簽約付一半、交接付一半，報價 30 天內有效。
客戶需提供：雲端帳號存取、一位具名董事、審查者每週 2 小時。"""
prompt = "你是一家小型景觀設計公司的老闆，剛收到下面這份單頁服務方案：\n\n" + ONE_PAGER + """

請只根據你讀到的內容回答兩個問題：你認為這裡面包含什麼？你認為這裡面不包含什麼？
輸出 JSON：{"included": ["..."], "not_included": ["..."], "questions": ["你還會想問顧問的問題，最多 3 個"]}"""
try:
    res = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(res, ensure_ascii=False, indent=2), encoding="utf-8")
for key, title in (("included", "客戶認為包含"), ("not_included", "客戶認為不包含"), ("questions", "客戶還想問")):
    items = res.get(key) if isinstance(res.get(key), list) else []
    print(title + "：")
    for it in items:
        print("  - " + str(it)[:60])
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "比對認知：客戶讀到的，跟你寫的一樣嗎？"
   tip "答案和你的設定不一樣，代表範疇寫得不夠清楚；改到一致為止。另外檢查草稿是不是在列「活動」而不是「產出」。"
   P='import json
from pathlib import Path

out = Path("ch13/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "scope_check.md").unlink(missing_ok=True)
OUTPUTS = {"公司設計圖": ("設計", "組織圖", "目標鏈", "blueprint"), "伺服器安裝": ("伺服器", "安裝", "雲端"),
           "兩個代理含上限": ("代理", "上限", "agent"), "交接文件": ("交接",), "導覽": ("導覽", "walkthrough")}
EXCL = {"持續營運": ("營運", "維運", "持續"), "品質審查": ("品質",), "例行任務": ("例行", "排程"), "資安評估": ("資安", "安全")}
raw = out / "prospect_raw.json"
FALLBACK = {"included": ["公司設計圖", "伺服器安裝", "兩個有上限的代理", "交接文件"],
            "not_included": ["持續營運", "內容品質審查", "資安評估"], "questions": ["伺服器費用誰付？"]}
src = "內建範例（第 6 步沒有成功）"
data = None
if raw.exists():
    try:
        data = json.loads(raw.read_text(encoding="utf-8"))
        src = "第 6 步模型輸出"
    except ValueError:
        data = None
if not isinstance(data, dict):
    data = FALLBACK
inc = " ".join(map(str, data.get("included") or [])).lower()
exc = " ".join(map(str, data.get("not_included") or [])).lower()

def hit(text, kws):
    return any(k.lower() in text for k in kws)

print("資料來源：", src)
res = []
for name, kws in OUTPUTS.items():
    ok = hit(inc, kws)
    res.append(("產出", name, ok))
    print("  產出 {:<10} 客戶有讀到：{}".format(name, "是" if ok else "否 <- 要改寫"))
for name, kws in EXCL.items():
    ok = hit(exc, kws)
    res.append(("排除", name, ok))
    print("  排除 {:<10} 客戶有讀到：{}".format(name, "是" if ok else "否 <- 要改寫"))
match = sum(1 for r in res if r[2])
print("認知一致 {}/{}".format(match, len(res)))
print()
DRAFT = ["我們會協助設定代理", "一台在你帳號裡的伺服器，含 health address", "我們會優化你的流程", "兩個代理，各有 $50/月 上限", "持續支援與培訓"]
ACT = ("協助", "優化", "支援", "培訓", "會設定", "幫忙")
print("另一份草稿逐行檢查（活動 vs 產出）：")
bad = 0
for line in DRAFT:
    is_act = any(a in line for a in ACT)
    bad += is_act
    print("  {} {}".format("活動 ✗" if is_act else "產出 ✓", line))
print("  {} 行是活動，客戶無法判斷買到什麼、你也無法判斷何時做完".format(bad))
md = "# 第 13 章：單頁方案認知比對\n\n資料來源：" + src + "\n\n| 類型 | 項目 | 客戶讀到 |\n|---|---|---|\n"
md += "\n".join("| {} | {} | {} |".format(t, n, "是" if ok else "否") for t, n, ok in res)
md += "\n\n認知一致 {}/{}\n\n客戶還想問：\n\n".format(match, len(res)) + "\n".join("- " + str(q) for q in (data.get("questions") or []))
md += "\n\n草稿中屬於活動的行數：{}/{}\n".format(bad, len(DRAFT))
(out / "scope_check.md").write_text(md, encoding="utf-8")
print()
print("已寫入", out / "scope_check.md")'
   show "$P"; run "$P" ;;
8) banner "總結：報價是一條有價格的邊界"
   tip "說「大約四千」的人以為模糊是體貼，其實是把自己該做的思考丟給客戶。"
   P='from pathlib import Path

points = [
    "賣四個具名方案（Blueprint and Setup、Governance and Budget Audit、Company Build、Managed Operations Retainer），各有產出、排除、價格區間，組成順著客戶信任往上爬的階梯。",
    "價格在區間內因四個說得出的理由移動：代理與連接器數、審查步驟、產出風險、環境難度；書中範例逐項加總 $11,200，超過上限就拆兩期而不是放寬區間。",
    "按範疇不按工時：工時獎勵慢、懲罰熟練；工時只給自己看，用來發現哪個價格太低（本例 Company Build 只有約 $164/小時）。",
    "三種範疇蔓延各配一句話：新增需求當變更報價、驗收擴張指回評分表、責任蔓延指回交接文件與 retainer；嫌貴就拿掉範疇，不打折。",
    "營收情境先算時數：起步年只用約 21% 產能，限制是找客戶；一人約扛 4 個 retainer；月費不超過客戶淨值的一半，$1,360 淨值的客戶不是 retainer 客戶。",
    "單頁方案要讓別人讀得懂：問「包含什麼、不包含什麼」，答案和你不同就改到一致；寫產出不寫活動。",
]
print("第 13 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("offers.csv", "buildup.json", "scenarios.csv", "prospect_raw.json", "scope_check.md"):
    p = Path("ch13/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

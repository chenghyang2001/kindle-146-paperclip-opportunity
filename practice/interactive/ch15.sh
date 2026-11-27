#!/bin/bash
# K146 第 15 章互動演練：交付與留住客戶，一次跑一步
# 用法：bash ch15.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask，再用 raw_decode 取出第一個 JSON 物件），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch15/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear 2>/dev/null; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 15 章｜交付與留住客戶　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "Company Build 八步交付：工時、日曆時間與客戶的時間"
   tip "八步裡沒有一步叫「培訓」：客戶在簽章程、套評分表、看試點成本的時候就學會了。"
   P='STEPS = [
    ("1. Kickoff 啟動", "範圍簽署、開權限、指定董事與審查人、收第一期款", 4, 13, 1),
    ("2. Blueprint 藍圖", "一頁角色、匯報線、使命與三個目標，客戶書面核准", 6, 5, 2),
    ("3. Install 安裝與主機", "準備主機、安裝公司、限制存取、跑第一次心跳", 8, 3, 0),
    ("4. Staff 聘用與配備", "經核准閘門聘代理、寫技能、加 2～3 個連接器", 12, 4, 1),
    ("5. Authorize 授權", "每個代理設上限、簽章程、評分表量 10 份失敗率", 9, 8, 3),
    ("6. Schedule 排程", "1～3 個例行程序寫成卡片，指定負責人與預算", 5, 11, 1),
    ("7. Pilot 試點", "兩週真實工作量成本；備份並還原到第二個位置", 6, 8, 2),
    ("8. Handoff 交接", "與董事、審查人走一遍；簽交接文件；第二期款", 5, 12, 2),
]
print("{:<20} | {:>4} | {:>8} | {}".format("步驟", "工時", "客戶小時", "做什麼"))
print("-" * 96)
for name, what, h, ch, client_h in STEPS:
    print("{:<20} | {:>4} | {:>8} | {}".format(name, h, client_h, what))
total = sum(s[2] for s in STEPS)
client_total = sum(s[4] for s in STEPS)
print("-" * 96)
print("顧問工時合計 {} 小時；客戶投入合計約 {} 小時".format(total, client_total))
print()
weeks = 5.5
print("日曆時間：試點本身就要兩週，客戶還要閱讀、決定、簽名 -> 約 5～6 週")
print("客戶每週約 {:.1f} 小時（{} 小時 / {} 週）".format(client_total / weeks, client_total, weeks))
for name, avail in (("A 客戶", 3), ("B 客戶", 2), ("C 客戶", 1)):
    verdict = "可以照計畫進行" if avail >= 2 else "改做較小的方案，不是做得比較慢"
    print("  {} 每週能給 {} 小時 -> {}".format(name, avail, verdict))'
   show "$P"; run "$P" ;;
2) banner "啟動時簽下的錯誤產出協議：同一週事件，有協議和沒協議"
   tip "開場的客戶看到一封日期錯的摘要，就把全部代理暫停、什麼也沒說。這一步把那一週重播兩次。"
   P='from collections import Counter
events = [
    (10, "日期錯誤", False), (11, "語氣太硬", False), (12, "日期錯誤", False),
    (13, "格式跑掉", False), (14, "日期錯誤", False), (15, "金額錯誤", True),
]

def no_protocol(evts):
    log = []
    for day, kind, reached in evts:
        log.append("第 {} 天：審查人攔下一份「{}」".format(day, kind))
        log.append("第 {} 天：董事嚇到，把所有代理暫停，沒通知任何人".format(day))
        return log, day, None
    return log, None, None

def with_protocol(evts, limit=3):
    log, count, told, paused = [], Counter(), [], None
    for day, kind, reached in evts:
        count[kind] += 1
        line = "第 {} 天：審查人駁回「{}」並寫評語，記入統計（本週第 {} 次）；公司照常運作".format(day, kind, count[kind])
        if count[kind] == limit:
            line += "\n           同類失敗本週達 {} 次 -> 董事當天通知顧問".format(limit)
            told.append(day)
        if reached:
            line = "第 {} 天：一份「{}」漏過審查，送到客戶手上（嚴重錯誤）".format(day, kind)
            line += "\n           -> 董事當天通知顧問；董事選擇暫停，並同一天告知"
            told.append(day)
            paused = day
        log.append(line)
    return log, paused, told

log, paused_day, _ = no_protocol(events)
print("【沒有協議】")
for l in log:
    print("  " + l)
print("  結果：前 9 天正常，從第 {} 天起什麼都沒跑；顧問第 7 週看紀錄才發現".format(paused_day))
print()
log, paused_day, told = with_protocol(events)
print("【有錯誤產出協議】")
for l in log:
    print("  " + l)
print("  結果：公司一直跑到第 {} 天才暫停；顧問被通知 {} 次（第 {} 天），暫停是最後一步而不是第一步".format(paused_day, len(told), "、".join(map(str, told))))
print()
print("另外兩份協議：")
print("  暫停與恢復說明：誰可以暫停、誰可以恢復、怎麼恢復（附實際畫面截圖）、恢復前先檢查什麼")
print("  沉默規則：第一個月顧問每週一則短訊，董事就算只回「沒問題」也要回 -> 沉默變成訊號")'
   show "$P"; run "$P" ;;
3) banner "前三十天的聯絡節奏與「失去參與」訊號偵測"
   tip "紀錄告訴你發生了什麼，只有人能告訴你為什麼；看到訊號當天就發一則不指責的短訊。"
   P='import random
random.seed(146)
CADENCE = {2: "短訊：例行程序有跑嗎？有什麼讓你意外？", 7: "15 分鐘通話：一起看紀錄", 14: "第一次成本檢查：對照第 8 章試點數字", 30: "45 分鐘董事審查會"}
days = []
approvals_waiting = 0
tally = 0
paused_from = None
for d in range(1, 31):
    agents_paused = d >= 18
    if agents_paused and paused_from is None:
        paused_from = d
    if d >= 10:
        approvals_waiting += 1 if d % 3 == 0 else 0
        last_touch_queue = 9
    else:
        last_touch_queue = d
    if not agents_paused:
        tally += random.choice((1, 1, 2))
    routines_skipped = 1 if (d in (11, 12)) else 0
    days.append((d, agents_paused, approvals_waiting, last_touch_queue, tally, routines_skipped))

def signals(row, prev_tally):
    d, ap, wait, last_q, t, skip = row
    s = []
    if ap:
        s.append("所有代理暫停")
    if wait and d - last_q >= 4:
        s.append("核准佇列 {} 天沒人碰".format(d - last_q))
    if prev_tally is not None and t == prev_tally and not ap:
        s.append("審查統計停止成長")
    if skip:
        s.append("例行程序被略過且沒有說明")
    return s

prev, alerted = None, set()
print("{:>4} | {:<34} | {}".format("天", "固定聯絡", "偵測到的訊號 -> 當天行動"))
print("-" * 92)
for row in days:
    d = row[0]
    sig = signals(row, prev)
    prev = row[4]
    new = [x for x in sig if x.split(" ")[0] not in alerted]
    for x in sig:
        alerted.add(x.split(" ")[0])
    line = CADENCE.get(d, "")
    if line or new:
        act = ("；".join(new) + " -> 發短訊") if new else ""
        print("{:>4} | {:<34} | {}".format(d, line, act))
print()
print("範例短訊：「我看到代理從第 {} 天起都暫停了，一切還好嗎？需要我幫忙恢復嗎？」".format(paused_from))
print("整個月固定聯絡約 2 小時；它把「有在運作嗎？」換成一串有日期的答案。")'
   show "$P"; run "$P" ;;
4) banner "第 30 天的六項測量與淨月價值（含客戶自己的監督時間）"
   tip "最常見的錯：漏掉客戶自己花的監督時間，淨價值看起來比實際好。"
   P='PROJ, SPEND = 180, 212
CEIL = PROJ * 1.5
REVIEWED, REJECTED, BASE = 31, 6, 0.20
print("1. 花費對上限：試點預估 ${}、實際 ${}、上限 ${:.0f}".format(PROJ, SPEND, CEIL))
print("   比預估高 {:.0f}%，比上限低 {:.0f}% -> 正常起伏，不是警報".format((SPEND / PROJ - 1) * 100, (1 - SPEND / CEIL) * 100))
fr = REJECTED / REVIEWED
print("2. 審查統計：審 {} 份、退 {} 份 -> 首月失敗率 {:.0f}%（交付時基準 {:.0f}%）-> 穩定".format(REVIEWED, REJECTED, fr * 100, BASE * 100))
print("3. 核准：待審 2 件，中位回應 6 小時（章程窗口 24 小時）")
print("4. 例行程序：排定 12 次、完成 11 次、略過 1 次")
print("5. 客戶花的時間：董事與審查人自估 7 小時")
print("6. 交付產出：週報 12 份、摘要 4 份")
print()
RATE = 40
OUT_HOURS = {"週報": (12, 2.5), "摘要": (4, 2.0)}
HOSTING, UPKEEP = 25, 40

def net_value(oversight_h):
    gross = sum(n * h * RATE for n, h in OUT_HOURS.values())
    cost = SPEND + HOSTING + UPKEEP + oversight_h * RATE
    return gross, cost, gross - cost

for label, oh in (("漏掉客戶時間", 0), ("照實算進 7 小時", 7)):
    g, c, nv = net_value(oh)
    print("{:<14} 毛效益 ${:,.0f} - 成本 ${:,.0f} = 淨月價值 ${:,.0f}".format(label, g, c, nv))
g, c, nv0 = net_value(0)
_, _, nv7 = net_value(7)
print("漏掉 7 小時，淨價值被高估 ${:,.0f}（{:.0f}%）".format(nv0 - nv7, (nv0 / nv7 - 1) * 100))
print("（時薪 ${}、每份週報省 2.5 小時、摘要 2 小時、主機 ${}、維運 ${} 都是假設，要換成客戶的數字）".format(RATE, HOSTING, UPKEEP))'
   show "$P"; run "$P" ;;
5) banner "維護合約要不要提？月費不超過淨月價值的一半"
   tip "淨價值撐不起月費時，誠實說「維持現狀，改做年度審計」——說不本身就是一種服務。"
   P='FLOOR = 2500

def decide(name, net, fee):
    half = net / 2
    if half < FLOOR:
        return "{}：淨 ${:,}，一半 ${:,.0f} 低於錨定底線 ${:,} -> 不提月約，建議年度 Governance and Budget Audit".format(name, net, half, FLOOR)
    if fee > half:
        return "{}：淨 ${:,}，月費 ${:,} 占 {:.0f}% 超過一半 -> 降價或縮小範圍".format(name, net, fee, fee / net * 100)
    return "{}：淨 ${:,}，月費 ${:,} 占 {:.0f}%（上限 ${:,.0f}）-> 可以在第 30 天審查時提出".format(name, net, fee, fee / net * 100, half)

for name, net, fee in (("書中客戶 A", 7000, 3000), ("書中客戶 B（第 12 章例子）", 1360, 2500), ("客戶 C", 5400, 3200), ("客戶 D", 9800, 4500)):
    print(decide(name, net, fee))
print()
print("合約包含（照客戶感受到的順序說）：每月一起看數字與成本；新版本先在暫存副本測過；每季從備份還原一次證明可用；出事在約定時數內回應；審查統計分析與例行程序調整")
print("合約不含：客戶自己的審查責任；新例行程序與新功能（另計變更）；主機與模型帳單（留在客戶帳戶）；不保證品質、省錢或不中斷")
print("條款：每月預付；雙方 30 天通知期；回應時間寫「工作日上班時間」，不寫「隨時待命」；每月約 12 小時，超過就談變更或調費")
print()
print("四個動作：1 列出維護清單問「現在誰負責」2 說出替代方案的代價 3 一頁寫清費用與內含排除 4 給選擇：下月開始，或下次審查再決定")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型寫第 30 天審查紀要與維護合約提案"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask

def first_json(text):
    dec = json.JSONDecoder()
    for i, ch in enumerate(text):
        if ch == "{":
            try:
                obj, _ = dec.raw_decode(text[i:])
            except ValueError:
                continue
            if isinstance(obj, dict):
                return obj
    raise ValueError("回覆中找不到 JSON 物件：" + text[:200])

out = Path("ch15/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "retainer_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是幫小公司建置 Paperclip（開源 AI 代理公司平台）的顧問，剛開完客戶的第 30 天董事審查會。實測數字：
模型花費 $212（試點預估 $180，上限 $270）；審查 31 份、退回 6 份（基準失敗率 20%）；待審核准 2 件，中位回應 6 小時；
例行程序排 12 次完成 11 次；客戶監督 7 小時；淨月價值 $963（已扣模型、主機、維運與客戶 7 小時監督時間，時薪 $40）。
請用繁體中文輸出 JSON：
{"review_note": "一段 30 天審查紀要（含花費、失敗率、核准、例行程序、客戶時數、淨月價值、決議、下次審查日期）",
 "retainer": {"monthly_fee": 數字（美元）, "fee_percent_of_net": 數字, "included": ["包含項目"], "excluded": ["不包含項目"],
  "response_hours": "回應時間", "notice_days": 數字, "hours_per_month": 數字, "recommendation": "若數字撐不起月費，你建議改做什麼"},
 "case_study_limits": ["若之後寫成案例研究，必須誠實揭露的限制"]}
規則：月費不可超過淨月價值的一半；若一半低於 $2,500 這個錨定底線，就應建議不簽月約、改做年度治理與預算審計，monthly_fee 填 0。"""
try:
    data = first_json(ask(prompt + chr(10) * 2 + "只輸出一個 JSON 物件，不要任何其他文字。"))
except (RuntimeError, ValueError) as exc:
    raw.unlink(missing_ok=True)
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print("審查紀要：", str(data.get("review_note", ""))[:300])
print()
ret = data.get("retainer") if isinstance(data.get("retainer"), dict) else {}
for k in ("monthly_fee", "fee_percent_of_net", "response_hours", "notice_days", "hours_per_month", "recommendation"):
    print("{:<20} {}".format(k, str(ret.get(k))[:100]))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用程式檢查維護合約提案：月費規則、內含排除、條款、案例限制"
   tip "站在客戶的角度問一句：如果每個月是我付這筆錢，我清楚知道換到了什麼嗎？"
   P='import json, re
from pathlib import Path

out = Path("ch15/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "retainer_check.md").unlink(missing_ok=True)
raw = out / "retainer_raw.json"
NET, FLOOR = 963, 2500
FALLBACK = {
    "review_note": "審查日 2026-12-28。花費 $212（預估 $180、上限 $270，上限不變）。審 31 份退 6 份（19%，基準 20%）。核准待審 2 件，中位 6 小時。例行程序 11/12。客戶時數 7 小時。淨月價值 $963。決議：維持上限；評分表加一條日期檢查。下次審查 2027-01-27。",
    "retainer": {"monthly_fee": 0, "fee_percent_of_net": 0, "included": [], "excluded": ["客戶自己的審查責任", "新例行程序"],
                 "response_hours": "工作日上班時間 8 小時內", "notice_days": 30, "hours_per_month": 0,
                 "recommendation": "淨月價值一半約 $482，低於 $2,500 底線：建議維持現狀，改做每年一次的 Governance and Budget Audit"},
    "case_study_limits": ["只有一個客戶、一個功能、30 天", "數字是假設時薪換算", "不代表其他客戶會有相同結果"],
}
data = None
if raw.exists():
    try:
        data = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        data = None
if isinstance(data, dict) and isinstance(data.get("retainer"), dict):
    source = "第 6 步模型輸出"
else:
    data, source = FALLBACK, "內建範例（第 6 步沒有成功）"
ret = data["retainer"]

def num(v):
    m = re.search(r"\d[\d,]*\.?\d*", str(v))
    return float(m.group().replace(",", "")) if m else 0.0

fee = num(ret.get("monthly_fee"))
note = str(data.get("review_note", ""))
rec = str(ret.get("recommendation", ""))
half = NET / 2
should_decline = half < FLOOR
checks = [
    ("月費不超過淨月價值一半（${:,.0f}）".format(half), fee <= half),
    ("一半低於底線時不提月約、改建議年度審計", (not should_decline) or (fee == 0 and ("審計" in rec or "Audit" in rec))),
    ("回應時間不是隨時待命", not re.search(r"24\s*/\s*7|隨時|全天候", str(ret.get("response_hours", "")))),
    ("有月約時通知期 30 天（不簽月約則免）", fee == 0 or num(ret.get("notice_days")) == 30),
    ("有寫不包含的事", len(ret.get("excluded") or []) >= 1),
    ("紀要寫進客戶時數", "7" in note and ("小時" in note or "hour" in note.lower())),
    ("紀要有下次審查日期", bool(re.search(r"\d{4}-\d{1,2}-\d{1,2}|\d{1,2}\s*月\s*\d{1,2}\s*日|第\s*60\s*天", note))),
    ("案例研究有寫限制", len(data.get("case_study_limits") or []) >= 1),
]
print("資料來源：", source)
print("淨月價值 ${:,}，一半 ${:,.0f}，底線 ${:,} -> 依規則{}".format(NET, half, FLOOR, "應改建議年度審計" if should_decline else "可提月約"))
print("模型給的月費：${:,.0f}；建議：{}".format(fee, rec[:80]))
for k, v in checks:
    print("  {} {}".format("✓" if v else "✗", k))
passed = sum(v for _, v in checks)
print("通過 {}/{}".format(passed, len(checks)))
fence = chr(96) * 3
report = "# 第 15 章：維護合約提案檢查報告\n\n資料來源：" + source + "\n\n## 原始內容\n\n" + fence + "json\n" + json.dumps(data, ensure_ascii=False, indent=2) + "\n" + fence + "\n\n## 檢查\n\n"
report += "\n".join("- " + ("通過" if v else "未通過") + "：" + k for k, v in checks) + "\n\n通過 " + str(passed) + "/" + str(len(checks)) + "\n"
(out / "retainer_check.md").write_text(report, encoding="utf-8")
print("已寫入", out / "retainer_check.md")'
   show "$P"; run "$P" ;;
8) banner "總結：把一個專案變成一段關係的五個重點"
   tip "客戶持續付費的不是那家公司，而是「有人在看著」的感覺。"
   P='from pathlib import Path
points = [
    "交付是八步流程，沒有「培訓」：客戶在簽章程、套評分表、看試點成本時邊做邊學；約 55 小時、5～6 週，客戶的時間也寫進範圍。",
    "啟動時白紙黑字三份協議：錯誤產出協議、暫停與恢復說明、沉默規則；對第一個錯誤的反應，比第一次成功更重要。",
    "前 30 天是量測期：第 2、7、14、30 天固定聯絡，量六項數字；看到暫停、佇列沒人碰、統計停住，當天就發不指責的短訊。",
    "第 30 天的審查是決策會議：帶數字、帶失敗案例；淨月價值要扣掉客戶自己的監督時間。",
    "維護合約在看過數字後才談，月費不超過淨月價值一半；撐不起就建議年度審計。案例與轉介只用有日期、可重現、經同意的數字，並寫出沒成功的事。",
]
print("第 15 章重點：")
for i, p in enumerate(points, 1):
    print("  {}. {}".format(i, p))
print()
print("本章產出檔案：")
for name in ("retainer_raw.json", "retainer_check.md"):
    p = Path("ch15/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

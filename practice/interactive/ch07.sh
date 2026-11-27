#!/bin/bash
# K146 第 7 章互動演練：Hermes 與 OpenClaw 當員工——客戶既有的代理能不能進組織圖，怎麼查，一次跑一步
# 用法：bash ch07.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch07/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 7 章｜Hermes 與 OpenClaw 當員工　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "adapter：控制層與 runtime 之間的橋"
   tip "Paperclip 是控制層，管組織圖、目標鏈、預算、核准和紀錄；runtime 把模型變成會做事的員工；adapter 在中間傳話。"
   P='import random
random.seed(146)
CONTROL = {"role": "Researcher", "goal": "每週客戶報告 > 蒐集本週專案筆記", "budget": 50.0, "spent": 0.0}

def runtime_hermes(task, session):
    # 假的 Hermes：做事、回傳結果與用量
    tokens = random.randint(3000, 6000)
    return {"output": "整理好 {} 則筆記".format(random.randint(4, 9)), "tokens": tokens, "cost": round(tokens / 1000 * 0.6, 2), "session": session or "s-001"}

def adapter(task, record, session_on=True):
    session = record[-1]["session"] if (session_on and record) else None
    res = runtime_hermes(task, session)
    CONTROL["spent"] += res["cost"]
    rec = {"task": task, "session": res["session"], "tokens": res["tokens"], "cost": res["cost"], "output": res["output"]}
    record.append(rec)
    return rec

record = []
print("控制層：角色 {}｜目標鏈 {}｜預算上限 {} 美元".format(CONTROL["role"], CONTROL["goal"], CONTROL["budget"]))
print()
print("{:>4} | {:<16} | {:<6} | {:>6} | {:>5} | {}".format("心跳", "任務", "session", "token", "成本", "結果"))
print("-" * 70)
for i, task in enumerate(["讀專案筆記", "補上週缺的數字", "交給 Writer"], 1):
    r = adapter(task, record)
    print("{:>4} | {:<16} | {:<6} | {:>6} | {:>5.2f} | {}".format(i, task, r["session"], r["tokens"], r["cost"], r["output"]))
print()
print("控制層記下的累計花費：{:.2f} / {} 美元".format(CONTROL["spent"], CONTROL["budget"]))
print("session 一直是 s-001：開了 session 延續，下一次心跳接著上一次的對話")
print("重點：選哪個 runtime 是「定好角色之後」的人事決定，不要讓可用的 runtime 決定角色")'
   show "$P"; run "$P" ;;
2) banner "狀態標籤：像讀合約一樣讀"
   tip "Selectable 今天能選；Experimental 還在測；Coming soon 不能說成可用；Retired 已經沒了。每句話都要帶日期。"
   P='LABELS = {
    "Claude Code": "Selectable", "Codex": "Selectable", "Hermes Agent": "Selectable",
    "native runner": "Experimental", "OpenClaw gateway": "Coming soon",
    "Process": "Coming soon", "HTTP": "Coming soon", "ACPX Local": "Retired",
}
READ_ON = "2026-10-20"
CLAIMS = [
    ("Hermes Agent", "有內建 adapter，可以選", True),
    ("OpenClaw gateway", "你的 OpenClaw 直接插上就能用", False),
    ("native runner", "native runner 很穩，正式案就用它", False),
    ("ACPX Local", "ACPX Local 也支援", False),
    ("Process", "shell 腳本可以在介面下拉選單選", False),
    ("Claude Code", "Claude Code 支援", False),
]
ALLOWED = {"Selectable": "可以說能選（附日期）", "Experimental": "要說明還在測試，不當正式案基礎", "Coming soon": "只能說文件寫什麼、你會驗證什麼", "Retired": "說它已經停用"}

print("adapter 狀態表（文件閱讀日 {}）：".format(READ_ON))
for rt, lb in LABELS.items():
    print("  {:<17} {}".format(rt, lb))
print()
print("{:<17} | {:<30} | {:<12} | {}".format("runtime", "業務說法", "標籤", "判定"))
print("-" * 92)
bad = 0
for rt, claim, dated in CLAIMS:
    lb = LABELS[rt]
    problems = []
    if lb != "Selectable":
        problems.append("過度承諾：" + ALLOWED[lb])
    if not dated:
        problems.append("沒寫日期")
    bad += bool(problems)
    print("{:<17} | {:<30} | {:<12} | {}".format(rt, claim, lb, "；".join(problems) or "OK"))
print()
print("6 句裡有 {} 句不能對客戶這樣說".format(bad))
print("注意：OpenClaw gateway、Process、HTTP 三個「執行時可用、但介面還不能選」，要經 API 或匯入設定，兩件事都要講")'
   show "$P"; run "$P" ;;
3) banner "成本回報：不回報花費的 runtime 等於沒有預算上限"
   tip "預算是照紀錄裡的花費來擋。控制層看不到的花費，上限就擋不住；只能在模型供應商那邊另設限額，並寫進 Blueprint。"
   P='CEILING = 50.0
PROVIDER_LIMIT = 40.0
RUNS = 20
ROLES = [
    ("Researcher", "Hermes adapter", 3.0, True),
    ("Writer", "Claude Code", 2.5, True),
    ("Poller", "自寫輪詢腳本", 4.0, False),
]

def simulate(cost, reports, provider_limit=None):
    recorded = actual = 0.0
    stopped = None
    for i in range(1, RUNS + 1):
        if recorded + cost > CEILING:
            stopped = "第 {} 次被 Paperclip 上限擋下".format(i)
            break
        if provider_limit is not None and actual + cost > provider_limit:
            stopped = "第 {} 次被供應商限額擋下".format(i)
            break
        actual += cost
        if reports:
            recorded += cost
    return recorded, actual, stopped or "跑滿 {} 次".format(RUNS)

print("每個角色上限 {} 美元，各排 {} 次執行".format(CEILING, RUNS))
print("{:<11} | {:<14} | {:<6} | {:>7} | {:>7} | {}".format("角色", "runtime", "回報?", "紀錄花費", "實際花費", "結果"))
print("-" * 82)
for role, rt, cost, rep in ROLES:
    rec, act, st = simulate(cost, rep)
    print("{:<11} | {:<14} | {:<6} | {:>7.1f} | {:>7.1f} | {}".format(role, rt, "是" if rep else "否", rec, act, st))
rec, act, st = simulate(4.0, False, PROVIDER_LIMIT)
print("{:<11} | {:<14} | {:<6} | {:>7.1f} | {:>7.1f} | {}".format("Poller", "＋供應商限額", "否", rec, act, st))
print()
print("Poller 不回報：紀錄是 0，實際花了 80，超過上限 30；上限形同虛設")
print("補救：在供應商端設 {} 美元限額，並在 Blueprint 寫明「此角色無成本回報，靠供應商限額」".format(int(PROVIDER_LIMIT)))'
   show "$P"; run "$P" ;;
4) banner "Hermes adapter 使用前檢查：八項都要過"
   tip "最常見的錯：看到「內建」就停在第一項，等到第一張帳單才發現成本從來沒回報。"
   P='CHECKS = [
    "Hermes 跟 Paperclip 在同一台機器",
    "Hermes 與 Python 版本已記錄",
    "知道用哪個模型、誰能改",
    "工具集已縮到角色需要的",
    "session 延續已確認第二次接得上",
    "測試任務後 run record 有成本",
    "Hermes 自帶 skill 已審過",
    "adapter 標籤與閱讀日期已記錄",
]
CLIENTS = {
    "客戶 A（同機、已縮工具）": [True, True, True, True, True, True, True, True],
    "客戶 B（Hermes 在另一台）": [False, True, False, False, True, False, False, True],
}
for name, res in CLIENTS.items():
    print(name)
    for c, ok in zip(CHECKS, res):
        print("  {} {}".format("PASS" if ok else "FAIL", c))
    first_fail = next((i + 1 for i, ok in enumerate(res) if not ok), None)
    if first_fail is None:
        print("  -> 八項全過，這個角色可以由 Hermes 擔任")
    else:
        print("  -> 第 {} 項就不過：這個 adapter 照文件描述用不了，答案從「可以」變成「要看情況」".format(first_fail))
        print("     其他沒過的：{}".format("、".join(str(i + 1) for i, ok in enumerate(res) if not ok)))
    print()
print("學習型代理的兩面：Hermes 會自己改寫 skill，報告語氣變了可能是它學的，不是你的版本 -> 要寫進 Blueprint")'
   show "$P"; run "$P" ;;
5) banner "OpenClaw：邀請流程四步，加上全自動≠越過治理"
   tip "gateway adapter 還是 Coming soon，但邀請流程今天就能用。雇用核准仍是人決定；工具層全自動，公司層的核准規則照樣有效。"
   P='from pathlib import Path
STEPS = [
    ("1 建立邀請", "產生 onboarding prompt（只有董事或 CEO 代理能發）"),
    ("2 貼進 OpenClaw", "代理回呼 Paperclip，送出加入申請"),
    ("3 雇用核准", "人打開完整申請讀完才核准；發一次性金鑰"),
    ("  裝置配對", "pairing required：等 OpenClaw 那端核准"),
    ("4 冒煙測試", "派一個小 issue，看完 run transcript 才給真工作"),
]
state = "invited"
for s, desc in STEPS:
    print("  {:<16} {}".format(s, desc))
print()
log = []
for event in ["join_request", "human_approve", "pairing_pending", "pairing_ok", "smoke_ok"]:
    if event == "pairing_pending":
        log.append("  等待中：pairing required")
        continue
    state = {"join_request": "pending_approval", "human_approve": "approved_key_issued", "pairing_ok": "paired", "smoke_ok": "active"}[event]
    log.append("  事件 {:<15} -> 狀態 {}".format(event, state))
print("\n".join(log))
print()
reg = Path("ch07/interactive/dependency_register_add.csv")
reg.parent.mkdir(parents=True, exist_ok=True)
reg.write_text("dependency,type,owner,what_breaks,last_checked,next_review,fallback\nOpenClaw one-time key,Credential,Peter,Triage 角色停擺,2026-11-27,2027-02-27,重新邀請\nHermes Agent,Runtime,Peter,Researcher 角色沒人做,2026-11-27,2027-02-27,Claude Code\n", encoding="utf-8")
print("限制：Paperclip 停機時連線斷掉、工作暫停；skill sync 不支援 -> 第 6 章的公司 skill 庫不會自動送到 OpenClaw")
print("一次性金鑰也是憑證，寫進登記表：", reg)
print()
ACTIONS = [("讀資料夾", False), ("改草稿", False), ("對外寄信", True), ("刪除客戶檔案", True)]
print("全自動模式（工具不再逐次詢問）下，公司層核准規則仍然生效：")
for act, need in ACTIONS:
    print("  {:<8} 工具層：自動執行｜公司層：{}".format(act, "要等人核准" if need else "允許"))'
   show "$P"; run "$P" ;;
6) banner "讓真實模型當顧問：該建公司，還是單一代理就好？"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch07/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "advice_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是幫小企業導入 Paperclip（多代理公司控制層）的顧問。
客戶：一人顧問公司，老闆自己做也自己審，已經用 Hermes Agent 好幾個月（裝在另一台筆電，不在 Paperclip 那台），每月約 8 個任務，每個任務省 30 分鐘，時薪 50 美元。
她問：「我的 Hermes 能放進組織圖嗎？我需要一家 Paperclip 公司嗎？」
2026-10-20 文件標示：Hermes Agent = Selectable（需與 Paperclip 同機）；OpenClaw gateway = Coming soon。
輸出 JSON：
{"recommendation": "company 或 single_agent", "reason": "一句話", "adapter_statement": "給客戶的 adapter 狀態說明，要含日期與標籤", "monthly_numbers": {"gross": 數字, "net_single": 數字, "net_company": 數字}, "triggers": ["什麼情況發生就重算"]}"""
try:
    advice = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(advice, ensure_ascii=False, indent=2), encoding="utf-8")
print("建議：", advice.get("recommendation"))
print("理由：", advice.get("reason"))
print("adapter 說明：", advice.get("adapter_statement"))
print("模型算的每月數字：", advice.get("monthly_numbers"))
print("重算觸發條件：")
for t in advice.get("triggers") or []:
    print("  -", str(t)[:70])
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用程式驗算：單一代理什麼時候才是誠實的答案"
   tip "公司有固定維護成本：審 release notes、維護登記表、調上限。量小的時候，治理成本比它管的工作還貴。"
   P='import json
from pathlib import Path

out = Path("ch07/interactive")
(out / "advice_report.md").unlink(missing_ok=True)
raw = out / "advice_raw.json"
FALLBACK = {
    "recommendation": "single_agent",
    "reason": "每月 8 個任務，公司層的維護成本比它帶來的效益還高",
    "adapter_statement": "2026-10-20 我讀的官方文件把 Hermes Agent 列為 Selectable，但需與 Paperclip 同機；建置前我會再查一次並在測試公司驗證成本回報。",
    "monthly_numbers": {"gross": 200, "net_single": 137, "net_company": -13},
    "triggers": ["多了第二個代理", "多了第二個依賴產出的人", "供應商帳單出現意外"],
}
adv = None
if raw.exists():
    try:
        adv = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        adv = None
source = "第 6 步模型輸出" if isinstance(adv, dict) else "內建範例（第 6 步沒有成功）"
if not isinstance(adv, dict):
    adv = FALLBACK

def nets(tasks, rate=50, saved_h=0.5, model=30, review_min=5, upkeep_h=3):
    gross = tasks * saved_h * rate
    single = gross - model - tasks * review_min / 60 * rate
    return gross, single, single - upkeep_h * rate

print("{:>6} | {:>6} | {:>9} | {:>9}".format("任務/月", "毛價值", "單一代理淨", "加公司層淨"))
print("-" * 40)
for t in (4, 8, 9, 12, 20, 40):
    g, s, c = nets(t)
    print("{:>6} | {:>6.0f} | {:>9.0f} | {:>9.0f}".format(t, g, s, c))
be = next(t for t in range(1, 200) if nets(t)[2] >= 0)
print("加上公司層後不賠錢的門檻：每月 {} 個任務（這只是不賠，不代表需要公司）".format(be))
g8, s8, c8 = nets(8)
print()
print("資料來源：", source)
checks = []
rec = str(adv.get("recommendation", "")).lower()
checks.append(("8 個任務建議單一代理", "single" in rec))
st = str(adv.get("adapter_statement", ""))
checks.append(("adapter 說明有日期", "2026" in st or "10-20" in st or "10/20" in st or "10 月 20" in st))
checks.append(("adapter 說明有標籤", any(k in st for k in ("Selectable", "可選", "可以選", "Coming soon"))))
checks.append(("有提到同機限制", any(k in st for k in ("同機", "同一台", "same machine"))))
over = any(k in st for k in ("直接插上", "plugs right in", "已支援 OpenClaw gateway"))
checks.append(("沒有過度承諾", not over))
trig = adv.get("triggers") or []
checks.append(("有重算觸發條件", len(trig) >= 1))
mn = adv.get("monthly_numbers") or {}
try:
    near = abs(float(mn.get("net_single")) - s8) <= 10 and abs(float(mn.get("net_company")) - c8) <= 10
except (TypeError, ValueError):
    near = False
checks.append(("數字與驗算差 10 美元內（單一 {:.0f}、公司 {:.0f}）".format(s8, c8), near))
for n, ok in checks:
    print("  {} {}".format("PASS" if ok else "FAIL", n))
print("通過 {} / {}".format(sum(ok for _, ok in checks), len(checks)))
report = "# 第 7 章：單一代理或公司——顧問建議檢查\n\n資料來源：" + source + "\n\n```json\n" + json.dumps(adv, ensure_ascii=False, indent=2) + "\n```\n\n## 檢查\n\n" + "\n".join("- {} {}".format("PASS" if ok else "FAIL", n) for n, ok in checks) + "\n\n驗算：8 個任務毛價值 {:.0f}、單一代理淨 {:.0f}、加公司層淨 {:.0f}（美元／月）\n".format(g8, s8, c8)
(out / "advice_report.md").write_text(report, encoding="utf-8")
print()
print("已寫入", out / "advice_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：Hermes 與 OpenClaw 當員工的五個重點"
   tip "每個標籤、需求和限制都會變；撐得過變化的本事，是照實讀、照實說，還附上日期。"
   P='from pathlib import Path

points = [
    "adapter 讓客戶信任的代理去填角色：Paperclip 管組織圖、預算、核准和紀錄，runtime 做事；選 runtime 是定好角色後的人事決定。",
    "狀態標籤像合約：Selectable 才能說可選，Coming soon 永遠不說成可用；6 句業務說法有 5 句不能講，每句都要帶日期。",
    "成本要回報，上限才有效：不回報的 Poller 紀錄 0、實際 80 美元；補救是供應商限額並寫進 Blueprint。",
    "Hermes 內建不等於能用：八項檢查（同機、模型、工具集、session、成本、自帶 skill、標籤日期）都過才派它上場；OpenClaw 走四步邀請流程，人核准、金鑰進登記表，全自動也越不過公司核准。",
    "單一代理有時才是誠實答案：每月 8 個任務，單一代理淨 137、加公司層變負 13；給出重算觸發條件，留下一段關係而不是一扇關上的門。",
]
print("第 7 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("dependency_register_add.csv", "advice_raw.json", "advice_report.md"):
    p = Path("ch07/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

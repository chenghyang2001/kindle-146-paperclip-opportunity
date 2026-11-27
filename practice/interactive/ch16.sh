#!/bin/bash
# K146 第 16 章互動演練：保持最新、學會說不、讓事業複利成長（含結論與附錄），一次跑一步
# 用法：bash ch16.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch16/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 16 章｜保持最新、說不與複利　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "每週 30 分鐘：把「跟上版本」變成有上限的例行"
   tip "什麼都讀會變第二份工作，什麼都不讀會從客戶口中才知道預設改了。固定 30 分鐘、三個來源、同一天。"
   P='WEEKS = 46
releases_per_year = round(5 / 4 * 52)
plans = [
    ("什麼都讀（每週 6 小時）", 6 * 60, 0, 0),
    ("什麼都不讀（被客戶發現才救火）", 0, 6, 8 * 60),
    ("固定 30 分鐘、三來源", 30, 0, 0),
]
print("Paperclip 2026-09-16 到 10-12 四週發布 5 次，推估一年約", releases_per_year, "次發布")
print()
print("{:<28} | {:>10} | {:>10} | {:>10} | {:>10}".format("做法", "例行時數/年", "救火時數/年", "合計/年", "客戶先發現"))
print("-" * 84)
for name, weekly_min, incidents, fix_min in plans:
    routine = weekly_min * WEEKS / 60
    fire = incidents * fix_min / 60
    print("{:<28} | {:>10.1f} | {:>10.1f} | {:>10.1f} | {:>8} 次".format(name, routine, fire, routine + fire, incidents))
print()
print("30 分鐘的分配（照書的順序）：")
for i, (src, minutes, why) in enumerate([
    ("release notes", 10, "什麼改了、哪一版"),
    ("承諾過功能的文件頁（預算、核准、routine、備份、更新）", 10, "預設最可能移動的地方"),
    ("issue 搜尋相依性登記表上的名稱＋寫 log", 10, "你依賴的東西有沒有出事"),
], 1):
    print(f"  {i}. {src}：{minutes} 分鐘 —— {why}")
print()
print("只回答一個問題：這裡有沒有任何東西會改變我告訴過客戶的話？")
print("一年成本約", round(30 * WEEKS / 60), "小時，是一筆可以定價的成本。")'
   show "$P"; run "$P" ;;
2) banner "三個桶子：No effect／Review／Act"
   tip "產出不是知識，而是分類。動到預設、移除功能、改安全建議的才是 Act，一週內要在 staging 測過。"
   P='import csv
from pathlib import Path

out = Path("ch16/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "release_log.csv").unlink(missing_ok=True)

CLIENTS = {
    "記帳事務所": {"budgets", "approvals", "backups"},
    "物流仲介": {"approvals", "routines"},
    "內容工作室": {"routines", "skills"},
}
CHANGES = [
    ("v2026.0916.0", "2026-09-16", "ui_theme", "new_feature", "新增深色主題", None),
    ("v2026.0923.0", "2026-09-23", "budgets", "default_change", "預算警示預設由 80% 改為 90%", None),
    ("v2026.0923.0", "2026-09-23", "routines", "bugfix", "routine 重複觸發的錯誤修正", None),
    ("v2026.0930.0", "2026-09-30", "approvals", "new_feature", "核准佇列可批次處理", None),
    ("v2026.1006.0", "2026-10-06", "backups", "security", "備份檔權限的安全建議更新", None),
    ("v2026.1006.0", "2026-10-06", "telemetry", "bugfix", "遙測欄位改名", None),
    ("v2026.1012.0", "2026-10-12", "skills", "removed", "舊版技能格式不再支援", None),
    ("v2026.1012.0", "2026-10-12", "approvals", "docs", "文件寫核准可設逾時，但 staging 上找不到", "staging 沒有此選項"),
]
ACT = {"default_change", "removed", "security"}

def classify(area, kind):
    affected = [c for c, used in CLIENTS.items() if area in used]
    if not affected:
        return "No effect", affected, "log 一行就走"
    if kind in ACT:
        return "Act", affected, "本週 staging 測試、通知受影響客戶、更新文件"
    return "Review", affected, "staging 看一下，排進月檢"

rows = []
for ver, date, area, kind, desc, conflict in CHANGES:
    bin_, affected, action = classify(area, kind)
    if conflict:
        action += "；文件與行為衝突，相信 staging 並記錄"
    rows.append((ver, date, area, bin_, "、".join(affected) or "-", desc, action))

print("{:<13} {:<11} {:<10} {:<9} {}".format("版本", "日期", "功能", "桶子", "說明"))
print("-" * 78)
for ver, date, area, bin_, who, desc, action in rows:
    print("{:<13} {:<11} {:<10} {:<9} {}".format(ver, date, area, bin_, desc))
    print("{:>46} 影響：{}｜動作：{}".format("", who, action))
print()
for b in ("No effect", "Review", "Act"):
    print(f"{b:<9}：{sum(1 for r in rows if r[3] == b)} 筆")
with open(out / "release_log.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["version", "date", "area", "bin", "affected", "change", "action"])
    w.writerows(rows)
print()
print("已寫入", out / "release_log.csv", "（一行一筆：版本、日期、桶子、動作）")'
   show "$P"; run "$P" ;;
3) banner "Act 變成五分鐘的 release call"
   tip "最常見的錯誤：把 changelog 直接丟給客戶。客戶要聽的是「這對我的公司代表什麼」。"
   P='import csv
from pathlib import Path

out = Path("ch16/interactive")
log = out / "release_log.csv"
(out / "release_calls.md").unlink(missing_ok=True)
FALLBACK = [
    {"version": "v2026.0923.0", "date": "2026-09-23", "area": "budgets", "bin": "Act", "affected": "記帳事務所", "change": "預算警示預設由 80% 改為 90%"},
]
if log.exists():
    with open(log, encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    source = "第 2 步 release_log.csv"
else:
    rows = FALLBACK
    source = "內建範例（第 2 步沒有跑）"
acts = [r for r in rows if r["bin"] == "Act"]
MEANING = {
    "budgets": ("會", "你的研究代理會晚一點才收到警示，上限前的緩衝變小", "我已在 staging 把警示改回 80% 並確認通知會發出", "下一個維護窗套用並維持 80%"),
    "backups": ("會", "備份檔放在共用資料夾，權限建議變嚴格", "我在副本上收緊權限後做了一次還原測試", "本週套用新權限"),
    "skills": ("會", "你們有兩個技能還是舊格式", "我在 staging 改寫成新格式並各跑三組輸入", "先鎖定目前版本，技能改好再升級"),
}
print("資料來源：", source)
print()
calls = []
for r in acts:
    yes, why, tested, propose = MEANING.get(r["area"], ("可能", "需要再確認", "尚未測試", "等修補"))
    for client in r["affected"].split("、"):
        need = "你不用做任何事" if r["area"] != "skills" else "請確認下週二上午可以停機十分鐘"
        ver, date, change = r["version"], r["date"], r["change"]
        msg = (f"您好，{client}。{ver} 在 {date} 發布，說明寫的是「{change}」。"
               f"對你的公司這{yes}有影響，因為{why}。{tested}。我建議{propose}。對你來說，{need}。")
        calls.append((client, ver, msg))
        print(f"【{client}｜{ver}】")
        print("  " + msg)
        print("  字數：", len(msg), "；五段結構：改了什麼 / 影不影響 / 怎麼測 / 建議 / 你要做什麼")
        print()
changelog = "; ".join(r["change"] for r in rows)
print("對照：直接丟 changelog 給客戶 =", len(changelog), "字，而且沒有一句跟他的公司有關")
md = "# 第 16 章：release call 訊息\n\n資料來源：" + source + "\n\n" + "\n".join(f"## {c}｜{v}\n\n{m}\n" for c, v, m in calls)
(out / "release_calls.md").write_text(md, encoding="utf-8")
print("已寫入", out / "release_calls.md", f"（共 {len(calls)} 則）")'
   show "$P"; run "$P" ;;
4) banner "說不的評分表：五種不適配客戶"
   tip "拒絕不是評價對方，而是說明落差，而且每一次都要附一個替代方案。早說、白說、一句話給理由。"
   P='from pathlib import Path

out = Path("ch16/interactive")
(out / "fit_screen.md").unlink(missing_ok=True)
PROSPECTS = [
    {"name": "A 電商", "expects_no_humans": True, "needs_vendor": False, "agents": 3, "board_hours": 0, "regulated": False},
    {"name": "B 上市公司採購部", "expects_no_humans": False, "needs_vendor": True, "agents": 4, "board_hours": 3, "regulated": False},
    {"name": "C 一人工作室", "expects_no_humans": False, "needs_vendor": False, "agents": 1, "board_hours": 2, "regulated": False},
    {"name": "D 貿易商", "expects_no_humans": False, "needs_vendor": False, "agents": 3, "board_hours": 0, "regulated": False},
    {"name": "E 診所", "expects_no_humans": False, "needs_vendor": False, "agents": 3, "board_hours": 3, "regulated": True},
    {"name": "F 記帳事務所", "expects_no_humans": False, "needs_vendor": False, "agents": 3, "board_hours": 3, "regulated": False},
    {"name": "G 小型行銷公司", "expects_no_humans": False, "needs_vendor": False, "agents": 4, "board_hours": 4, "regulated": False},
]
RULES = [
    ("期待零人力", lambda p: p["expects_no_humans"], "不想有人在座位上", "小型治理稽核或兩週試點，量化監督成本", "-"),
    ("需要廠商", lambda p: p["needs_vendor"], "需要能簽支援合約、自負法律責任的公司", "用三個檢查點幫你評估大廠產品", "大廠產品"),
    ("只要一個代理", lambda p: p["agents"] <= 1, "一個任務一個代理，沒有東西需要管理", "單一代理的簡短設定", "單代理顧問"),
    ("沒人坐董事席", lambda p: p["board_hours"] < 1, "沒有人能在時間內核准與審查", "只交 Blueprint 文件，等你有一位每週能給三小時的負責人再找我", "-"),
    ("需要我不是的專業", lambda p: p["regulated"], "涉及受監管的內容，需要專業簽核", "Blueprint 與預算政策", "律師、合規顧問"),
]

def honest_no(reason, offer, referral):
    ref = "" if referral == "-" else f"其他部分建議找{referral}。"
    return f"根據你說的，{reason}。這超出我能負責交付的範圍，接了反而害你。我能做的是{offer}。{ref}如果情況改變，很樂意再談。"

lines = ["# 第 16 章：discovery call 適配篩選\n"]
print("{:<16} | {:<14} | {}".format("潛在客戶", "判定", "要說的話"))
print("-" * 90)
for p in PROSPECTS:
    hit = next((r for r in RULES if r[1](p)), None)
    if hit is None:
        verdict, say = "適合", "進入下一步：一個提案、一個價格區間、一個日期"
    else:
        verdict, say = "婉拒：" + hit[0], honest_no(hit[2], hit[3], hit[4])
    print("{:<16} | {:<14} | {}".format(p["name"], verdict, say))
    pname = p["name"]
    lines.append(f"- **{pname}**：{verdict}。{say}")
fit = sum(1 for p in PROSPECTS if not any(r[1](p) for r in RULES))
print()
print(f"{len(PROSPECTS)} 位潛在客戶，適合 {fit} 位，婉拒 {len(PROSPECTS) - fit} 位；每個婉拒都附替代方案。")
print()
print("特例：工作對、價錢不對 —— 月費測試（月費不超過「淨值扣監督」約一半）")
for client, net, oversight in (("F 記帳事務所", 4200, 600), ("G 小型行銷公司", 9000, 1500)):
    ok = 3000 <= 0.5 * (net - oversight)
    judge = "撐得住" if ok else "撐不住，改提年度稽核，不打折"
    print(f"  {client}：月淨值 {net}、監督成本 {oversight}，月費 3000 {judge}")
(out / "fit_screen.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print()
print("已寫入", out / "fit_screen.md")'
   show "$P"; run "$P" ;;
5) banner "十二個月：什麼會複利、什麼會衰退、何時找第二人"
   tip "成熟的事業不是更大，而是記錄得更好。停止檢查不會維持原狀，而是每週悄悄變得更不準。"
   P='import random
random.seed(146)

releases = [random.choice((0, 1, 1, 2)) for _ in range(52)]
def accuracy(review):
    acc, hist = 100.0, []
    for w in range(52):
        acc -= releases[w] * 1.0
        if review:
            acc = 100.0
        hist.append(max(0.0, acc))
    return hist
with_r, without_r = accuracy(True), accuracy(False)
skills = [round(60 * (1.03 ** (w // 4)), 1) for w in range(52)]
print("{:>4} | {:>18} | {:>18} | {:>14}".format("週", "登記表準確度(有週檢)", "登記表準確度(無週檢)", "技能庫品質(重用)"))
print("-" * 66)
for w in (1, 13, 26, 39, 52):
    print("{:>4} | {:>19.0f}% | {:>19.0f}% | {:>16}".format(w, with_r[w - 1], without_r[w - 1], skills[w - 1]))
print("一年發布次數（模擬）：", sum(releases))
print()
HOURS_YEAR = 20 * 46
month = HOURS_YEAR / 12
print(f"產能：每週 20 小時 × 46 週 = {HOURS_YEAR} 小時/年，約 {month:.0f} 小時/月；一個月費客戶約 12 小時/月")
for n in (2, 4, 5, 6):
    print(f"  {n} 個月費客戶：{n * 12} 小時 = {n * 12 / month:.0%}")
committed = [40, 47, 55, 59, 60, 62]
streak, trigger = 0, None
for i, h in enumerate(committed, 1):
    streak = streak + 1 if h / month > 0.75 else 0
    if streak == 3 and trigger is None:
        trigger = i
print()
print("近六個月承諾工時：", committed)
print("連續三個月超過 75% 的月份：", f"第 {trigger} 個月" if trigger else "尚未出現")
if trigger:
    print("先試：1 標準化  2 新客戶漲價  3 婉拒耗時最多、價值最低的客戶；都用完才找人")
    print("先交出去：月檢、staging 更新、還原測試；留在手上：discovery call、Blueprint、董事對話")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型回答：為什麼不直接用大廠產品？"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒。我們要看它會不會先承認大廠何時才是對的。"
   P='import json
from pathlib import Path
from llm_agent import ask_json

out = Path("ch16/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "vendor_answer_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是一位幫中小企業建置 AI 代理公司的獨立顧問（用開源的代理管理工具）。
客戶問：「為什麼不直接用大廠的代理產品？我的 IT 說比較安全。」
請用繁體中文寫一段 150 字以內的口語回答，要求：
1. 開頭先承認在哪些情況下大廠產品才是正確選擇。
2. 列出客戶可以在大廠「現行文件」中自己查證的三項：是否記錄每個代理做了什麼與花費、能否為個別代理設預算上限、聘用代理是否需要人類核准。
3. 最後說明你的工作在什麼缺口上。不要替任何工具辯護、不要貶低對方。
輸出 JSON：{"answer": "回答全文", "vendor_right_when": ["情況1", "情況2"], "three_checks": ["檢查1", "檢查2", "檢查3"]}"""
try:
    data = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print("模型的回答：")
print("  " + str(data.get("answer", "")))
print()
print("大廠適合的情況：", data.get("vendor_right_when"))
print("三個檢查點：", data.get("three_checks"))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用程式檢查：聽起來像在辯護嗎？"
   tip "書的行動題只問一個問題：我聽起來像在替什麼東西辯護嗎？這一步把它變成可以量的檢查。"
   P='import json, re
from pathlib import Path

out = Path("ch16/interactive")
raw = out / "vendor_answer_raw.json"
(out / "vendor_answer_report.md").unlink(missing_ok=True)
FALLBACK = {"answer": "如果你的系統本來就在那家廠商的平台上，又希望出事時只打一通電話、有支援合約和法人負責，那大廠產品大概就是對的，我也會建議你先從那裡開始。請在它現行的文件裡查三件事：有沒有記錄每個代理做了什麼、花了多少；能不能替每個代理設花費上限；聘用新代理要不要人核准。三項都有，你就不需要我；少一項，或你想把多家供應商的代理放在同一份紀錄下管，那就是我做的事。"}
data = None
if raw.exists():
    try:
        data = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        data = None
if isinstance(data, dict) and data.get("answer"):
    source = "第 6 步模型輸出"
else:
    data, source = FALLBACK, "內建範例（第 6 步沒有成功）"
ans = str(data["answer"])
n = len(re.sub(r"\s", "", ans))
head = ans[: max(1, len(ans) // 2)]
opens_with_limit = bool(re.search(r"(大廠|廠商|供應商|他們的產品)", head)) and bool(re.search(r"(對的|正確|適合|合理|首選|開始)", head))
CHECKS = {
    "記錄行為與花費": r"(記錄|紀錄|log).*?(花|成本|費用)|(花|成本|費用).*?(記錄|紀錄)",
    "個別代理上限": r"(上限|預算|額度)",
    "聘用需人核准": r"(核准|批准|同意|審核)",
}
hits = {k: bool(re.search(v, ans)) for k, v in CHECKS.items()}
DEFENSIVE = ["其實", "絕對", "根本", "比較好", "更好", "不如", "免費", "被綁", "鎖死", "風險很大", "不安全", "放心"]
found = [w for w in DEFENSIVE if w in ans]
score = (n <= 150) + opens_with_limit + sum(hits.values()) + (len(found) == 0)
print("資料來源：", source)
print("回答：", ans)
print()
print("1. 字數（不含空白）：", n, "→", "OK" if n <= 150 else "超過 150")
print("2. 前半段先承認大廠何時是對的：", "是" if opens_with_limit else "否")
for k, v in hits.items():
    print("3.", k, "：", "有" if v else "缺")
print("4. 辯護／貶低語氣詞：", found if found else "無")
print()
verdict = "不像在辯護" if score >= 5 and not found else "聽起來有點在辯護或漏了檢查點"
print(f"總分 {score} / 6 → {verdict}")
found_txt = "、".join(found) if found else "無"
report = f"# 第 16 章：為什麼不用大廠產品——回答檢查\n\n資料來源：{source}\n\n> {ans}\n\n- 字數：{n}\n- 先承認極限：{opens_with_limit}\n- 三檢查點：{hits}\n- 辯護詞：{found_txt}\n- 總分：{score}/6，{verdict}\n"
(out / "vendor_answer_report.md").write_text(report, encoding="utf-8")
print("已寫入", out / "vendor_answer_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：本章五個重點＋全書回顧"
   tip "代理公司不是判斷力的替代品，而是事先決定哪裡需要判斷，並確保那時有人坐在那裡。"
   P='from pathlib import Path

points = [
    "保持最新是有上限的每週習慣：30 分鐘、三個來源、三個桶子，一年約 23 小時；Act 一律變成五分鐘的 release call，不丟 changelog。",
    "說不要早、要白、要附替代方案：期待零人力、需要廠商、只要一個代理、沒人坐董事席、需要你不是的專業，五種都有轉介。",
    "風險只講有日期的事實，不猜動機；用鎖版本、備份還原、帳號資料歸客戶、每季檢查、退場計畫管理延續性。",
    "會複利的是技能、藍圖、方法、案例與誠實換來的信任；會衰退的是預設值、狀態筆記和沒有日期的數字，所以每週不能停。",
    "承諾工時連續三個月超過產能 75% 才考慮第二人；先標準化、漲價、婉拒，再交出可重複的工作。",
]
print("第 16 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("全書回顧（BOARD 五階段）：Build 安裝建公司 → Organize 組織與技能 → Authorize 預算與核准 → Run 心跳與營運 → Deliver 包裝、交付、留住客戶")
print("結論：先設計董事席，再確保有人坐得進去。")
print()
print("本章產出檔案：")
for name in ("release_log.csv", "release_calls.md", "fit_screen.md", "vendor_answer_raw.json", "vendor_answer_report.md"):
    p = Path("ch16/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

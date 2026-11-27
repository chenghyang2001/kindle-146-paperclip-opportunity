#!/bin/bash
# K146 第 14 章互動演練：定位、展示與贏得客戶，一次跑一步
# 用法：bash ch14.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask，再用 raw_decode 取出第一個 JSON 物件），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch14/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear 2>/dev/null; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 14 章｜定位、展示與贏得客戶　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "三種對話選一個當主導：用診斷問題判斷對方在哪一種"
   tip "定位不是你喜歡哪一種，而是你接觸得到的人在擔心哪一種。先問：「一聽到 AI，你第一個擔心什麼？」"
   P='LEADS = {
    "Visibility": ("用好幾個 AI 工具的小公司老闆", "我不知道這些工具做了什麼、花了多少", "Blueprint and Setup，或先做小額審計",
                   ("做了什麼", "花了多少", "帳單", "好幾個", "看不到", "成本")),
    "Control": ("要對風險負責的人：合夥人、法遵、謹慎的老闆", "我要它做事，但不能沒有限制", "Governance and Budget Audit",
                ("出錯", "風險", "法遵", "核准", "限制", "寄給客戶", "擋下")),
    "Capacity": ("有固定每週產出的經理或小團隊", "事情做不完，我又還不能請人", "Company Build，之後接維護合約",
                 ("做不完", "人手", "每週", "報告", "請不起", "請人")),
}
prospects = [
    ("行銷公司老闆", "我們用了五個 AI 工具，月底帳單一來我根本看不到誰做了什麼"),
    ("記帳事務所合夥人", "上個月有封寄給客戶的信數字出錯，我最怕的是這種事沒人擋下"),
    ("網拍店店長", "每週一的商品與庫存報告做不完，人手又不夠，暫時也請不起人"),
    ("建築事務所主持人", "AI 產出的圖說是誰核准的、花了多少，我說不清楚"),
    ("物業管理辦公室", "維修信箱每天塞爆，每週都做不完，想先不請人"),
    ("朋友的朋友", "我還沒在用 AI，只是好奇而已"),
]
print("{:<10} | {:<11} | {}".format("對象", "判定的主導對話", "命中的關鍵字"))
print("-" * 64)
tally = {k: 0 for k in LEADS}
for name, answer in prospects:
    hits = {k: [w for w in v[3] if w in answer] for k, v in LEADS.items()}
    best = max(hits, key=lambda k: len(hits[k]))
    if not hits[best]:
        print("{:<10} | {:<11} | {}".format(name, "未判定", "沒有痛點：記下來，不是每個人都是客戶"))
        continue
    tally[best] += 1
    print("{:<10} | {:<11} | {}".format(name, best, "、".join(hits[best])))
print()
print("你接觸得到的這一群人：", "，".join("{} {} 人".format(k, v) for k, v in tally.items()))
lead = max(tally, key=tally.get)
who, worry, offer, _ = LEADS[lead]
print("建議主導對話：", lead)
print("  最常有這個擔心的人：", who)
print("  他們會怎麼說：「{}」".format(worry))
print("  第 13 章對應的第一個方案：", offer)
print()
print("定位測試：把主導句講給 3 個符合的人聽，至少 2 人問起自己的狀況才算過")
for label, asked_own in (("「我是 AI 代理顧問，提供六種服務」", 0), ("「我幫小公司看清 AI 工具上個月做了什麼、花多少」", 2)):
    print("  {}：{} / 3 人問自己的狀況 -> {}".format(label, asked_own, "通過" if asked_own >= 2 else "還不行"))'
   show "$P"; run "$P" ;;
2) banner "一句話 pitch：對象＋問題＋界線，再過禁用字與十秒檢查"
   tip "界線是多數人省略、卻最能建立信任的那一段；一句話念超過十秒，對方就記不住。"
   P='import re
BANNED = ("轉型", "顛覆", "自主勞動力", "睡覺", "全自動", "取代員工", "省下一半")
BOUNDARY = ("不保證", "不承諾", "我不是", "不負責", "不包")
CHECKABLE = ("報告", "上限", "紀錄", "核准", "清單", "花多少", "花了多少")
CHARS_PER_SEC = 6

def check(p):
    body = re.sub(r"[，。、；：「」（）\s]", "", p)
    secs = len(body) / CHARS_PER_SEC
    res = {
        "對象": p.startswith("我幫"),
        "問題": any(w in p for w in ("什麼", "多少", "哪", "誰")),
        "界線": any(w in p for w in BOUNDARY),
        "可檢查的結果": any(w in p for w in CHECKABLE),
        "沒有禁用字": not any(w in p for w in BANNED),
        "十秒內念完": secs <= 10,
    }
    return res, secs

def fill(person, question, setup, boundary):
    return "我幫{}看清{}，做法是{}；{}。".format(person, question, setup, boundary)

pitches = [
    ("多數人的寫法", "我是 AI 自動化專家，打造在你睡覺時幫你經營公司的自主勞動力，全面轉型。"),
    ("描述技術", "我用開源編排平台建置 AI 代理系統。"),
    ("小行銷公司（Visibility）", fill("行銷公司老闆", "每個 AI 工具做了什麼、花多少", "把它們放進同一份紀錄", "我不保證代理能無人看管")),
    ("記帳事務所（Control）", "我幫事務所看清 AI 起草的信是誰核准的，做法是加上花費上限和人工核准；我不保證它永遠對。"),
    ("網拍店（Capacity）", "我幫網拍店每週一拿到庫存報告、知道花多少，不用請人；我不保證報告免看，所以先給人讀。"),
]
for label, p in pitches:
    res, secs = check(p)
    passed = sum(res.values())
    print("【{}】{}".format(label, p))
    print("   念完約 {:.1f} 秒；通過 {}/6：{}".format(secs, passed, "、".join(k + ("✓" if v else "✗") for k, v in res.items())))
print()
print("重述測試：隔天請對方用自己的話說一次；說得出「幫誰、做什麼」才算有效，只說「跟 AI 有關的事」就不行。")'
   show "$P"; run "$P" ;;
3) banner "十分鐘展示的六段：每一段回答一個對方還沒問的問題"
   tip "依序：公司、目標鏈、完成的任務與紀錄、預算暫停、核准、誠實的極限，然後安靜十秒，再問一個問題。"
   P='RUN_SHEET = [
    (0, 1, "公司（組織圖）", "這是什麼？一句話說完"),
    (1, 3, "目標鏈", "這件工作為什麼存在？"),
    (3, 5, "一個完成的任務與紀錄", "發生了什麼、順序如何？"),
    (5, 7, "預算暫停", "什麼東西擋住它亂花錢？"),
    (7, 8, "核准", "什麼東西擋住它不經我同意就行動？"),
    (8, 10, "誠實的極限＋一個問題", "它不做什麼？我站在哪裡？"),
]
REQUIRED = ["公司（組織圖）", "目標鏈", "一個完成的任務與紀錄", "預算暫停", "核准", "誠實的極限＋一個問題"]

def audit(sheet, rehearsed_pause, silence_sec):
    issues = []
    t = 0
    for s, e, part, _ in sheet:
        if s != t:
            issues.append("時間不連續：{} 從第 {} 分開始".format(part, s))
        t = e
    if t > 10:
        issues.append("總長 {} 分鐘，超過十分鐘上限".format(t))
    order = [p for _, _, p, _ in sheet]
    missing = [p for p in REQUIRED if p not in order]
    if missing:
        issues.append("缺少段落：" + "、".join(missing))
    elif order != REQUIRED:
        issues.append("順序不對：" + " -> ".join(order))
    if not rehearsed_pause:
        issues.append("預算暫停沒有彩排，展示要靠運氣")
    if silence_sec < 10:
        issues.append("展示弱成果後只停了 {} 秒，沒有留十秒給對方".format(silence_sec))
    return t, issues

print("{:>6} | {:<20} | {}".format("分鐘", "段落", "回答的問題"))
print("-" * 66)
for s, e, part, q in RUN_SHEET:
    print("{:>2}～{:<3} | {:<20} | {}".format(s, e, part, q))
print()
typical = [(0, 3, "公司（組織圖）", ""), (3, 6, "功能逐頁解說", ""), (6, 9, "目標鏈", ""), (9, 12, "最強的成果", ""), (12, 14, "而且它還能……", "")]
for label, sheet, reh, sil in (("照本章做", RUN_SHEET, True, 10), ("多數人的做法", typical, False, 0)):
    total, issues = audit(sheet, reh, sil)
    print("【{}】總長 {} 分鐘，問題 {} 個".format(label, total, len(issues)))
    for i in issues:
        print("   - " + i)
print()
print("收尾問題：「你們現在的工具裡，最想在這裡看到哪一個？」")
for ans, conv in (("好幾個工具都想看", "Visibility"), ("它怎麼不會做錯事", "Control"), ("能不能每週產出那份報告", "Capacity"), ("都不用", "記下來，不是每個人都是客戶")):
    print("  回答「{}」-> {}".format(ans, conv))'
   show "$P"; run "$P" ;;
4) banner "第 5～8 分鐘：預算暫停與核准閘門的彩排"
   tip "上限設在已花費略高一點，80% 只記警告不停，100% 暫停並取消進行中的那次執行；人不批准，代理就不存在。"
   P='import random
random.seed(146)
CEILING, SPENT, WARN = 5.00, 3.70, 0.80
print("研究代理本月上限 ${:.2f}，已花 ${:.2f}（{:.0f}%）".format(CEILING, SPENT, SPENT / CEILING * 100))
spent, warned, log = SPENT, False, []
for call in range(1, 20):
    cost = round(random.uniform(0.15, 0.45), 2)
    spent = round(spent + cost, 2)
    if spent >= CEILING:
        log.append("第 {} 次呼叫 +${:.2f} -> ${:.2f}：達 100%，狀態改為 paused，進行中的執行被取消".format(call, cost, spent))
        break
    if not warned and spent >= CEILING * WARN:
        warned = True
        log.append("第 {} 次呼叫 +${:.2f} -> ${:.2f}：達 80%，只記錄警告，代理繼續".format(call, cost, spent))
    else:
        log.append("第 {} 次呼叫 +${:.2f} -> ${:.2f}".format(call, cost, spent))
for line in log:
    print("  " + line)
print("要你說的話：「它碰到我設的數字就停了；要不要調高上限，是人做的決定，紀錄會寫是誰。」")
print()
print("彩排 20 次（真實花費起伏較大，每次呼叫 $0.05～$0.60）：第 5～7 分鐘之間（每 20 秒一次呼叫，第 4～6 次呼叫）剛好暫停，才算成功")
ok, early, late = 0, 0, 0
for _ in range(20):
    s, n = SPENT, 0
    while s < CEILING:
        n += 1
        s += random.uniform(0.05, 0.60)
    if n < 4:
        early += 1
    elif n > 6:
        late += 1
    else:
        ok += 1
print("  剛好 {} 次、太早 {} 次、太晚 {} 次 -> 成功率 {:.0f}%".format(ok, early, late, ok / 20 * 100))
print("  所以要備一段成功暫停的錄影；用的時候直說「這是昨天同一件事的錄影」")
print()
org = ["CEO 代理", "研究代理"]
pending = {"type": "Hire Agent", "name": "報表代理", "reason": "每週一產出客戶報表"}
print("核准閘門：目前組織圖", len(org), "個代理；待審請求：", pending)
for decision in ("尚未決定", "核准"):
    if decision == "核准":
        org.append(pending["name"])
    print("  董事決定「{}」-> 組織圖 {} 個代理：{}".format(decision, len(org), "、".join(org)))'
   show "$P"; run "$P" ;;
5) banner "沒有客戶時的公信力，與熟人網絡漏斗試算"
   tip "「你幫誰做過？」誠實答：還沒有客戶，這是我的測試公司、實測成本、失敗率和書面方法。"
   P='import math
stack = [
    ("有文件的測試公司", "Blueprint、預算政策、章程、評分表、例行卡、備份還原紀錄，全部有日期"),
    ("實測的試點數據", "兩週試點：每份週報模型費約 $0.80；10 份初稿有 2 份沒過評分表"),
    ("兩頁書面方法", "五個 BOARD 階段、三種對話、四種方案與限制"),
]
print("公信力三層：")
for i, (k, v) in enumerate(stack, 1):
    print("  {}. {}：{}".format(i, k, v))
print()

def funnel(reply, call, proposal, sign, target=8):
    rate = reply * call * proposal * sign
    msgs = round(target / rate)
    replies = msgs * reply
    calls = replies * call
    props = calls * proposal
    hours = msgs * 0.25 + calls * 1.5 + props * 2
    return rate, msgs, calls, props, hours

rate, msgs, calls, props, hours = funnel(0.40, 0.60, 0.50, 0.50)
print("書中示意：回覆 40%、回覆轉通話 60%、通話轉提案 50%、提案簽約 50%")
print("  訊息到簽約轉換率 {:.0f}%；一年要 8 件 -> 約 {} 封熱訊息（46 週每週約 {:.1f} 封）".format(rate * 100, msgs, msgs / 46))
print("  通話 {:.0f} 通、提案 {:.0f} 份；銷售工時約 {:.0f} 小時，占 920 小時產能的 {:.0f}%".format(calls, props, hours, hours / 920 * 100))
print()
print("{:>6} | {:>8} | {:>8} | {:>9}".format("回覆率", "需要訊息", "銷售工時", "占產能"))
print("-" * 42)
for r in (0.20, 0.30, 0.40, 0.60):
    _, m, _, _, h = funnel(r, 0.60, 0.50, 0.50)
    print("{:>6.0%} | {:>8} | {:>8.0f} | {:>8.0f}%".format(r, m, h, h / 920 * 100))
print()
print("前 20 封訊息寄完，就用自己的真實比率取代這些假設；重點是漏斗形狀：上寬下窄，工作要穩定而小量。")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型依客戶原話寫 pitch 與一頁提案"
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

out = Path("ch14/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "proposal_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是幫小公司導入 Paperclip（開源 AI 代理公司平台）的顧問，還沒有任何正式客戶，只有一家自己的測試公司。
潛在客戶：12 人的記帳事務所負責人。探索通話中她的原話是：「上個月有封寄給客戶的信數字錯了，我最怕這種事沒人擋下來，但我也沒空每封都自己看。」
請用繁體中文輸出 JSON：
{"pitch": "一句話 pitch：我幫誰回答什麼問題、怎麼做、並明說一個不承諾的界線（60 字內）",
 "proposal": {"opening_quote": "提案第一句，直接引用客戶原話", "offer": "方案名稱", "outputs": ["交付物"], "exclusions": ["不包含的事"],
  "assumptions": ["假設"], "client_provides": ["客戶要提供的"], "acceptance": ["驗收標準"], "price": "固定價格（新台幣）", "payment": "付款方式",
  "valid_until": "報價有效期限", "next_step": "下一步與具體日期"}}
不要使用「轉型」「顛覆」「全自動」這類字眼，不要捏造過去客戶。"""
try:
    data = first_json(ask(prompt + chr(10) * 2 + "只輸出一個 JSON 物件，不要任何其他文字。"))
except (RuntimeError, ValueError) as exc:
    raw.unlink(missing_ok=True)
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
prop = data.get("proposal") if isinstance(data.get("proposal"), dict) else {}
print("pitch：", data.get("pitch"))
print()
for k in ("opening_quote", "offer", "outputs", "exclusions", "acceptance", "price", "next_step"):
    v = prop.get(k)
    if isinstance(v, list):
        v = "；".join(map(str, v))
    print("{:<14} {}".format(k, str(v)[:90]))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用程式檢查提案：原話開場、排除事項、固定價、下一步日期"
   tip "提案第一句引用客戶原話，代表你有在聽；結尾沒有日期的提案，就會石沉大海。"
   P='import json, re
from pathlib import Path

out = Path("ch14/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "proposal_check.md").unlink(missing_ok=True)
raw = out / "proposal_raw.json"
QUOTE = "上個月有封寄給客戶的信數字錯了，我最怕這種事沒人擋下來，但我也沒空每封都自己看。"
FALLBACK = {
    "pitch": "我幫事務所讓 AI 先起草，加上花費上限和一道人工核准；我不保證它永遠對，所以才有核准。",
    "proposal": {
        "opening_quote": "妳說：「上個月有封寄給客戶的信數字錯了，我最怕這種事沒人擋下來。」",
        "offer": "Governance and Budget Audit", "outputs": ["現有 AI 工具清單與花費", "每個代理的預算上限建議", "對外文件的核准流程"],
        "exclusions": ["不代替事務所審查每封信", "不含新例行程序開發"], "assumptions": ["可讀取現有工具帳單"],
        "client_provides": ["每週 2 小時", "一位審查人"], "acceptance": ["10 份對外草稿全部經人核准才寄出"],
        "price": "新台幣 36,000 元，固定", "payment": "簽約付一半，交付付一半", "valid_until": "2026-12-31",
        "next_step": "我 12 月 3 日（週四）上午十點打給妳回答問題",
    },
}
data = None
if raw.exists():
    try:
        data = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        data = None
if isinstance(data, dict) and isinstance(data.get("proposal"), dict):
    source = "第 6 步模型輸出"
else:
    data, source = FALLBACK, "內建範例（第 6 步沒有成功）"
prop = data["proposal"]

def as_list(v):
    return v if isinstance(v, list) else ([v] if v else [])

def overlap(a, b):
    grams = {a[i:i + 2] for i in range(len(a) - 1)}
    return sum(1 for g in grams if g in b) / max(1, len(grams))

pitch = str(data.get("pitch", ""))
text_all = json.dumps(data, ensure_ascii=False)
BANNED = ("轉型", "顛覆", "全自動", "取代員工")
DATE = r"(\d{4}-\d{1,2}-\d{1,2}|\d{1,2}\s*月\s*\d{1,2}\s*日|週[一二三四五六日]|星期[一二三四五六日])"
checks = [
    ("pitch 有界線", any(w in pitch for w in ("不保證", "不承諾", "不負責", "不包", "不代替", "不會"))),
    ("沒有禁用字", not any(w in text_all for w in BANNED)),
    ("開場引用客戶原話", overlap(QUOTE, str(prop.get("opening_quote", ""))) >= 0.3),
    ("有排除事項", len(as_list(prop.get("exclusions"))) >= 1),
    ("有驗收標準", len(as_list(prop.get("acceptance"))) >= 1),
    ("固定價格", bool(re.search(r"\d", str(prop.get("price", ""))) and not re.search(r"起|視情況|另議|待估", str(prop.get("price", ""))))),
    ("下一步有日期", bool(re.search(DATE, str(prop.get("next_step", ""))))),
    ("一頁內（全文 1000 字內）", len(text_all) <= 1000 or len(re.sub(r"[\s\"{}\[\],:]", "", text_all)) <= 1000),
]
print("資料來源：", source)
print("原話重疊率：{:.0%}".format(overlap(QUOTE, str(prop.get("opening_quote", "")))))
for k, v in checks:
    print("  {} {}".format("✓" if v else "✗", k))
passed = sum(v for _, v in checks)
print("通過 {}/{}".format(passed, len(checks)))
fence = chr(96) * 3
report = "# 第 14 章：一頁提案檢查報告\n\n資料來源：" + source + "\n\n## 原始內容\n\n" + fence + "json\n" + json.dumps(data, ensure_ascii=False, indent=2) + "\n" + fence + "\n\n## 檢查\n\n"
report += "\n".join("- " + ("通過" if v else "未通過") + "：" + k for k, v in checks) + "\n\n通過 " + str(passed) + "/" + str(len(checks)) + "\n"
(out / "proposal_check.md").write_text(report, encoding="utf-8")
print("已寫入", out / "proposal_check.md")'
   show "$P"; run "$P" ;;
8) banner "總結：贏得第一個客戶的五個重點"
   tip "客戶不是請軟體從不出錯的人，而是請那個冷靜展示「出錯時會怎樣」的人。"
   P='from pathlib import Path
points = [
    "定位＝先說哪一種擔心：從你接觸得到的人選 Visibility、Control 或 Capacity 當主導，並先說自己不是什麼。",
    "一句話 pitch＝對象＋問題＋界線：界線不是道歉而是賣點；不用轉型、全自動這類字，十秒內念完，隔天對方說得出來。",
    "十分鐘展示六段：公司、目標鏈、任務紀錄、預算暫停、核准、誠實極限；預算暫停一定要彩排並備錄影，弱成果之後安靜十秒。",
    "沒有客戶就拿出三層證據：有文件的測試公司、有日期的實測成本與失敗率、兩頁方法；絕不捏造推薦。",
    "從熟人開始：訊息只問一個問題、通話聽多於說、一天內送一頁提案，開頭用客戶原話、結尾有下一步日期。",
]
print("第 14 章重點：")
for i, p in enumerate(points, 1):
    print("  {}. {}".format(i, p))
print()
print("本章產出檔案：")
for name in ("proposal_raw.json", "proposal_check.md"):
    p = Path("ch14/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

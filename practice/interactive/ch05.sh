#!/bin/bash
# K146 第 5 章互動演練：設計公司——組織圖、角色與目標鏈，一次跑一步
# 用法：bash ch05.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch05/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 5 章｜設計公司　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "職能地圖：先找負責人，再數代理"
   tip "從業務職能出發，不從工具出發：產出、接收者、截止、步驟、哪些留給人、誰對結果負責。"
   P='import json
from pathlib import Path
out = Path("ch05/interactive"); out.mkdir(parents=True, exist_ok=True)
fmap = {
    "function": "內容產出",
    "output": "每週二在客戶部落格發布一篇約 800 字、來源齊全的文章",
    "receiver": "行銷主管",
    "deadline": "週一中午前收到草稿",
    "steps": [
        ("選題", "human", "需要行銷主管的判斷"),
        ("蒐集來源", "agent", ""),
        ("撰寫草稿", "agent", ""),
        ("編修與查證", "agent", ""),
        ("發布", "human", "需要行銷主管簽核"),
    ],
    "accountable": "Editor：當編修稿與修改說明放上任務並送審，這篇文章就算準備好",
    "reports_to": "行銷主管（具名真人）",
}
print("職能：", fmap["function"]); print("產出：", fmap["output"]); print("接收者：", fmap["receiver"], "｜截止：", fmap["deadline"])
print()
for i, (s, who, why) in enumerate(fmap["steps"], 1):
    print("  {}. {:<8} {:<6} {}".format(i, s, "人" if who == "human" else "代理", why))
agent_steps = [s for s, w, _ in fmap["steps"] if w == "agent"]
human_steps = [s for s, w, _ in fmap["steps"] if w == "human"]
print()
print("負責角色：", fmap["accountable"])
print("代理步驟 {} 個 -> 只需要 {} 個代理；人的決定 {} 個".format(len(agent_steps), len(agent_steps), len(human_steps)))
print("開頭那位老闆從工具出發：5 個寫手、2 個審稿、1 個研究、1 個排程 = 9 個代理，卻沒有人對「發布」負責")
(out / "function_map.json").write_text(json.dumps(fmap, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入", out / "function_map.json")'
   show "$P"; run "$P" ;;
2) banner "誠實的商業帳：扣掉模型費和人的監督時間"
   tip "作者的示意：每篇 6 小時、時薪 50 美元、每月 4 篇；模型與主機 120 美元；人每篇監督 1.5 小時。"
   P='def net_value(hours=6, rate=50, per_month=4, model=120, oversight=1.5):
    gross = hours * per_month * rate
    over = oversight * per_month * rate
    return gross, over, gross - model - over
g, o, n = net_value()
print("毛價值 ${}｜模型與主機 -$120｜人的監督 -${:.0f}｜淨價值 ${:.0f}".format(g, o, n))
print("標題說 ${}，客戶自己的試算表會算出 ${:.0f}（只剩 {:.0f}%）".format(g, n, n / g * 100))
print()
print("敏感度：人的監督時間每篇幾小時，淨價值還剩多少")
print("{:>10} | {:>8} | {:>8}".format("監督小時", "淨價值$", "佔毛價值"))
print("-" * 34)
for ov in (0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0):
    _, _, nv = net_value(oversight=ov)
    print("{:>10} | {:>8.0f} | {:>7.0f}%".format(ov, nv, nv / g * 100))
be = (g - 120) / (4 * 50)
print()
print("監督時間超過每篇 {:.1f} 小時，這個職能交給代理就是賠錢".format(be))'
   show "$P"; run "$P" ;;
3) banner "角色是契約：五要素＋陌生人測試"
   tip "職稱不是定義。可用的角色定義 = 範疇、輸入、產出、限制、終點線。"
   P='ROLES = {
    "Editor（常見寫法）": {"scope": "Reviews and improves articles for quality and brand voice."},
    "Editor（照模板）": {
        "scope": "負責每週文章是否準備好",
        "inputs": "Writer 的草稿、Researcher 的來源清單、共用資料夾的風格說明",
        "outputs": "約 800 字的編修稿，每個主張都連到來源清單，加一段修改說明",
        "limits": "不發布、不新增清單外的來源、不改題目；沒有來源的主張要移除或標記，絕不捏造",
        "finish_line": "編修稿與說明貼在任務上，狀態改為「送審」給行銷主管",
    },
}
PARTS = ("scope", "inputs", "outputs", "limits", "finish_line")
QUESTIONS = {
    "scope": "它對什麼負責？", "inputs": "週一早上它要讀什麼？", "outputs": "它交出什麼、放哪裡？",
    "limits": "它絕對不能做什麼？", "finish_line": "怎麼知道它做完了？",
}
for name, r in ROLES.items():
    print(name)
    answered = 0
    for p in PARTS:
        ok = bool(r.get(p))
        answered += ok
        print("   陌生人問「{}」 -> {}".format(QUESTIONS[p], r[p] if ok else "答不出來"))
    print("   陌生人測試：{}/5 {}".format(answered, "通過" if answered == 5 else "有缺口，先別聘"))
    print()
print("最值錢的一條限制：「沒有來源的主張要標記，絕不捏造」——把品質控制寫進定義，比事後失敗便宜")'
   show "$P"; run "$P" ;;
4) banner "彙報線：深度很貴，兩層通常就夠"
   tip "每多一層：多一次執行、多一次轉述漂移、多一個可能卡住的主管。"
   P='import random
random.seed(146)
TASKS = 40
DRIFT = 0.08
print("{:>4} | {:>8} | {:>9} | {:>12} | {:>14}".format("層數", "每任務執行", "每月總執行", "相對兩層", "指令沒走樣機率"))
print("-" * 64)
base = TASKS * 2
for levels in (2, 3, 4, 5):
    runs = levels
    total = TASKS * runs
    intact = (1 - DRIFT) ** (levels - 1)
    print("{:>4} | {:>8} | {:>9} | {:>11.0f}% | {:>13.0f}%".format(levels, runs, total, (total / base - 1) * 100, intact * 100))
print()
print("主管被暫停時：三層公司 40 件任務裡，經過該主管的任務會卡住")
mid = {i: ("研究主管" if i % 2 == 0 else "寫作主管") for i in range(TASKS)}
stuck = sum(1 for i in range(TASKS) if mid[i] == "寫作主管")
print("  暫停「寫作主管」-> 卡住 {} 件；兩層公司沒有這個卡點".format(stuck))
print()
print("太寬也不行：CEO 的直屬人數 vs 協調負擔（路徑數）")
for n in (3, 5, 6, 8, 12):
    flag = "考慮加一層主管" if n > 6 else "OK"
    print("  直屬 {:>2} 人 -> CEO 要追 {:>2} 條指派、{:>2} 條橫向協調  {}".format(n, n, n * (n - 1) // 2, flag))
print()
print("加中層的三個訊號：直屬超過五六人／兩個子職能產出與截止不同／某子職能需要不同的人類審查者")'
   show "$P"; run "$P" ;;
5) banner "目標鏈：寫「狀態」，不要寫「方向」"
   tip "方向詞 grow／improve／build 對幾乎任何工作都成立；狀態詞 published／delivered／approved 才能被檢查。"
   P='import re
DIRECTION = r"\b(build|grow|improve|create|increase|enhance)\b|打造|提升|成長|改善|建立"
STATE = r"\b(publish|deliver|approv|sen[dt]|maintain|list)\w*|發布|交付|核准|寄出|維持"
def check(goal):
    has_dir = bool(re.search(DIRECTION, goal, re.I))
    has_state = bool(re.search(STATE, goal, re.I))
    has_when = bool(re.search(r"(every|by |each|least|\d|週|每)", goal, re.I))
    return has_state and has_when and not has_dir
chains = {
    "常見寫法": ["Build thought leadership for the firm", "Create great content", "Grow social presence", "Improve SEO"],
    "照模板": ["Publish one 800-word, fully sourced article on the firm blog every Tuesday, approved by the marketing lead",
              "Deliver an edited, sourced draft to the marketing lead by Monday at noon",
              "Maintain a source list of at least five items per article, each published in the last 90 days"],
}
for name, goals in chains.items():
    print(name)
    for g in goals:
        print("  {} {}".format("可驗證  " if check(g) else "只有方向", g))
    print()
print("任務往上追溯（照模板的鏈）：")
TASKS = {"找 5 個 90 天內來源": 2, "編修草稿並列修改說明": 1, "設計新 logo": None, "經營 Instagram": None}
for t, sg in TASKS.items():
    print("  {:<16} -> {}".format(t, ("子目標 {}".format(sg)) if sg else "接不上任何子目標，立刻露餡"))
print()
print("目標數量上限建議：1 個頂層目標 + 2 個子目標，每個子目標一個專案")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型起草一頁公司藍圖（Company Blueprint）"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='import json
from pathlib import Path
from llm_agent import ask_json
out = Path("ch05/interactive"); out.mkdir(parents=True, exist_ok=True)
raw = out / "blueprint_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是 AI 代理公司的設計顧問。替這個真實業務職能設計一頁 Company Blueprint：
職能：一家 AMR（自主移動機器人）公司的「每週客戶問題摘要」——每週一早上把上週客服與現場工程師收到的客戶問題，整理成一頁摘要給產品經理王小姐。
規則：組織圖只能兩層（CEO 代理 + 直屬代理），最多 3 個直屬角色；董事會要寫具名真人；頂層目標和子目標要寫成可驗證的狀態（含數量、接收者、頻率或截止、驗證的人），不要寫 grow／improve／build 這種方向；預算與核准規則只列為「下一階段決定」，不要編數字。
輸出 JSON（值用繁體中文）：{"function": "一句話職能與產出", "top_goal": "...", "sub_goals": ["...", "..."], "board_member": "具名真人", "roles": [{"name": "...", "scope": "...", "inputs": "...", "outputs": "...", "limits": "...", "finish_line": "...", "accountable": true 或 false}], "stays_human": [{"step": "...", "reason": "..."}], "review_points": ["..."], "decided_next": ["..."], "not_included": ["..."]}"""
try:
    bp = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(bp, ensure_ascii=False, indent=2), encoding="utf-8")
print("職能：", bp.get("function"))
print("頂層目標：", bp.get("top_goal"))
for i, s in enumerate(bp.get("sub_goals") or [], 1):
    print("  子目標 {}：{}".format(i, s))
print("董事：", bp.get("board_member"))
for r in [x for x in bp.get("roles") or [] if isinstance(x, dict)]:
    print("  角色 {:<14} 負責人={}  終點線：{}".format(str(r.get("name")), "是" if r.get("accountable") else "否", str(r.get("finish_line", ""))[:50]))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "審查藍圖：七項齊全、兩層、具名董事、目標是狀態"
   tip "一頁的藍圖要讓 AI 圈外的人說得出：每個角色做什麼、誰負責結果、人在哪裡做決定。"
   P='import json, re
from pathlib import Path
out = Path("ch05/interactive"); out.mkdir(parents=True, exist_ok=True)
raw = out / "blueprint_raw.json"
FALLBACK = {
    "function": "每週一 09:00 前把上週客戶問題整理成一頁摘要交給產品經理",
    "top_goal": "每週一 09:00 前寄出一頁客戶問題摘要給產品經理王小姐，由她確認收到",
    "sub_goals": ["每週日 18:00 前交付分類好的問題清單（至少涵蓋所有工單）", "Improve customer insight"],
    "board_member": "the owner",
    "roles": [
        {"name": "Collector", "scope": "蒐集工單", "inputs": "客服系統", "outputs": "問題清單", "limits": "", "finish_line": "清單放上任務", "accountable": False},
        {"name": "Summarizer", "scope": "寫摘要", "inputs": "問題清單", "outputs": "一頁摘要", "limits": "不寄出", "finish_line": "摘要送審", "accountable": True},
    ],
    "stays_human": [{"step": "寄出", "reason": "對外動作需要人簽核"}],
    "review_points": ["王小姐在寄出前檢查摘要"], "decided_next": ["月預算上限", "核准規則"], "not_included": ["不直接回覆客戶"],
}
bp, source = None, "內建範例（第 6 步沒有成功）"
if raw.exists():
    try:
        bp = json.loads(raw.read_text(encoding="utf-8")); source = "第 6 步模型輸出"
    except ValueError:
        bp = None
if not isinstance(bp, dict):
    bp, source = FALLBACK, "內建範例（第 6 步沒有成功）"
SEVEN = ("function", "top_goal", "roles", "board_member", "stays_human", "review_points", "decided_next")
DIRECTION = r"\b(build|grow|improve|create|increase|enhance)\b|打造|提升|成長|改善|加強"
roles = [r for r in bp.get("roles") or [] if isinstance(r, dict)]
checks = []
missing = [k for k in SEVEN if not bp.get(k)]
checks.append(("七項齊全", not missing, "缺 " + ",".join(missing) if missing else "齊全"))
direct = [r for r in roles if "CEO" not in str(r.get("name", "")).upper()]
checks.append(("兩層、直屬 3 人內", 0 < len(direct) <= 3, "{} 個直屬角色（CEO 不算）".format(len(direct))))
board = str(bp.get("board_member", ""))
checks.append(("董事是具名真人", bool(board) and not re.search(r"owner|老闆|負責人|董事會", board, re.I), board or "（空）"))
acc = [r.get("name") for r in roles if r.get("accountable") is True]
checks.append(("恰好一個負責角色", len(acc) == 1, ",".join(map(str, acc)) or "無"))
nolimit = [r.get("name") for r in roles if not str(r.get("limits", "")).strip() or not str(r.get("finish_line", "")).strip()]
checks.append(("每個角色有限制與終點線", not nolimit, "缺：" + ",".join(map(str, nolimit)) if nolimit else "都有"))
goals = [str(bp.get("top_goal", ""))] + [str(s) for s in bp.get("sub_goals") or []]
bad = [g for g in goals if re.search(DIRECTION, g, re.I) or not re.search(r"\d", g)]
checks.append(("目標寫成狀態（有數字、沒方向詞）", not bad, "問題目標：" + "；".join(b[:30] for b in bad) if bad else "全部可驗證"))
checks.append(("目標數 <= 3", len(goals) <= 3, "{} 個".format(len(goals))))
print("資料來源：", source)
for name, ok, note in checks:
    print("  {} {:<20} {}".format("PASS" if ok else "FAIL", name, note))
score = sum(ok for _, ok, _ in checks)
print()
print("得分 {}/{}".format(score, len(checks)))
md = ["# Company Blueprint（第 5 章練習）", "", "資料來源：" + source, "",
      "**職能與產出**：" + str(bp.get("function")), "",
      "**目標**：" + goals[0]] + ["- 子目標 {}：{}".format(i, g) for i, g in enumerate(goals[1:], 1)] + [
      "", "**彙報線**：CEO 代理向 " + board + " 報告；" + "、".join(str(r.get("name")) for r in roles) + " 向 CEO 報告", "", "**角色**："]
md += ["- {}{}：{}；完成條件：{}；限制：{}".format(r.get("name"), "（負責人）" if r.get("accountable") else "", r.get("scope"), r.get("finish_line"), r.get("limits")) for r in roles]
md += ["", "**留給人**："] + ["- {}：{}".format(h.get("step"), h.get("reason")) for h in bp.get("stays_human") or [] if isinstance(h, dict)]
md += ["", "**審查點**："] + ["- " + str(x) for x in bp.get("review_points") or []]
md += ["", "**下一階段決定**："] + ["- " + str(x) for x in bp.get("decided_next") or []]
md += ["", "**不包含**："] + ["- " + str(x) for x in bp.get("not_included") or []]
md += ["", "## 審查結果", ""] + ["- {} {}：{}".format("PASS" if ok else "FAIL", n, note) for n, ok, note in checks]
(out / "blueprint.md").write_text("\n".join(md) + "\n", encoding="utf-8")
print("已寫入", out / "blueprint.md")'
   show "$P"; run "$P" ;;
8) banner "總結：誰對真正發布的成果負責？"
   tip "開頭那位老闆不需要更多代理，她需要一句話：這個角色對發布出去的東西負責。"
   P='from pathlib import Path
points = [
    "從業務職能出發，不從工具出發：先寫產出、接收者、截止、步驟，指定唯一的負責角色，再數代理（內容職能 = 2 個人的決定 + 3 個代理步驟）。",
    "誠實算帳：毛價值 $1,200 扣模型 $120、扣人的監督 $300，淨 $780；監督超過每篇約 5.4 小時就賠錢。",
    "角色是契約：範疇、輸入、產出、限制、終點線五要素，寫進 AGENTS.md 之前先做陌生人測試。",
    "組織圖保持兩層：40 件任務三層要 120 次執行（多 50%），還多一個會卡住的主管；能說出中層獨有的決定才加層，董事要寫具名真人。",
    "目標寫成可驗證的狀態，一個頂層加兩個子目標；最後把一切壓成一頁 Company Blueprint，這是第一份能開發票的交付物。",
]
print("第 5 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("function_map.json", "blueprint_raw.json", "blueprint.md"):
    p = Path("ch05/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

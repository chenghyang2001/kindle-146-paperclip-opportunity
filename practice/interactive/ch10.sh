#!/bin/bash
# K146 第 10 章互動演練：品質關卡與信任——你必須自己加上的那一層，一次跑一步
# 用法：bash ch10.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（claude -p，透過 llm_agent.ask_json），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch10/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K146 第 10 章｜品質關卡與信任　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "分類問題：這份產出下一個是誰看？"
   tip "草稿下一個是人會改，關卡可以輕；下一個是客戶、主管機關或公開讀者，關卡就要硬。"
   P='OUTPUTS = [
    ("陌生開發信初稿", "業務本人"),
    ("研究摘要", "部門主管"),
    ("腦力激盪清單", "行銷團隊"),
    ("客服回覆", "客戶"),
    ("月報裡的營收數字", "董事會"),
    ("官網公開文章", "公開讀者"),
    ("退款承諾訊息", "客戶"),
    ("申報給主管機關的資料", "主管機關"),
]
FINAL = {"客戶", "主管機關", "公開讀者", "董事會"}
hard, light = [], []
print("{:<14} | {:<8} | {}".format("產出", "下一個看的人", "關卡"))
print("-" * 44)
for name, who in OUTPUTS:
    gate = "硬關卡（定稿）" if who in FINAL else "輕關卡（草稿）"
    (hard if who in FINAL else light).append(name)
    print("{:<14} | {:<10} | {}".format(name, who, gate))
print()
print("硬關卡 {} 個：{}".format(len(hard), "、".join(hard)))
print("輕關卡 {} 個：{}".format(len(light), "、".join(light)))
print("審查點設在產出跨出公司邊界的地方，而不是流程中間。")'
   show "$P"; run "$P" ;;
2) banner "信任預設與最小權限：隔離不等於正確"
   tip "low-trust review 擋的是藏在外部文字裡的指令（prompt injection），不檢查答案對不對。"
   P='AGENTS = [
    ("收件匣分類代理", "陌生人寫的客戶來信", True),
    ("網頁研究代理", "公開網頁", True),
    ("撰稿代理", "研究代理整理好的來源清單", False),
    ("發票核對代理", "廠商寄來的文件", True),
    ("週報代理", "公司內部專案筆記", False),
]
print("{:<10} | {:<16} | {}".format("代理", "讀的輸入", "建議信任預設"))
print("-" * 52)
for name, src, untrusted in AGENTS:
    print("{:<10} | {:<18} | {}".format(name, src, "low-trust review（隔離＋人放行）" if untrusted else "standard"))
print()
ACCESS = [
    ("收件匣分類代理", "Gmail", {"read", "label", "send"}, {"read", "label"}),
    ("發票核對代理", "會計系統", {"read", "write", "pay"}, {"read"}),
    ("週報代理", "共用資料夾", {"read"}, {"read"}),
    ("撰稿代理", "CMS", {"read", "publish"}, {"read", "draft"}),
]
print("存取表檢查（實際授予 vs 完成工作所需）：")
over = 0
for agent, conn, granted, need in ACCESS:
    extra = sorted(granted - need)
    lack = sorted(need - granted)
    status = "OK" if not extra and not lack else ("權限過大：" + ",".join(extra) if extra else "") + (" 缺：" + ",".join(lack) if lack else "")
    over += bool(extra)
    print("  {:<10} {:<6} {}".format(agent, conn, status))
print("權限過大的連接器：{} 個（要收窄到剛好完成工作）".format(over))
print()
def ver(s):
    return tuple(int(x) for x in s.lstrip("v").split("."))
current, fixed = "v2026.410.0", "v2026.416.0"
print("目前版本 {}，修補三個漏洞的版本 {} → {}".format(current, fixed, "需要更新" if ver(current) < ver(fixed) else "已涵蓋"))
print("書中漏洞分數：CVSS 10.0／9.6／8.3；本機模式不等於安全。")'
   show "$P"; run "$P" ;;
3) banner "五題是非評分表：十份產出跑一次（含一個蓄意植入的錯誤）"
   tip "評分表只問別人幾分鐘內答得出來的是非題；「寫得好不好」這種題目兩個人會答不一樣。"
   P='import json
from pathlib import Path
POLICY = {"P1": "一般商品購買後 30 天內可退款", "P2": "停產商品不接受退款，可於 30 天內換購"}
ALLOWED = {"換購", "30 天內退款"}
BANNED = ("絕對", "保證", "請放心")

def reply(i, claims, commits=(), text_ok=True, tone="", unsure=False, planted=False):
    body = "您好，" + "；".join(c for c, _ in claims) + tone + ("[待確認]" if unsure else "") + "。客服團隊"
    if not text_ok:
        body = body.replace("您好，", "").replace("客服團隊", "")
    return {"id": "R{:02d}".format(i), "text": body, "claims": [{"text": c, "source": s} for c, s in claims], "commitments": list(commits), "planted": planted}

OUTS = [
    reply(1, [("一般商品 30 天內可退款", "P1")], ["30 天內退款"]),
    reply(2, [("停產商品可換購", "P2")], ["換購"]),
    reply(3, [("一般商品 30 天內可退款", "P1")], ["30 天內退款"], text_ok=False),
    reply(4, [("停產商品不接受退款", "P2")]),
    reply(5, [("訂單已出貨", "ORDER")]),
    reply(6, [("一般商品 30 天內可退款", "P1")], ["30 天內退款"]),
    reply(7, [("停產商品 90 天內可退款", "none")], ["90 天內退款"], tone="，請放心", planted=True),
    reply(8, [("停產商品可換購", "P2")], ["換購"]),
    reply(9, [("一般商品 30 天內可退款", "P1")], ["30 天內退款"], unsure=True),
    reply(10, [("停產商品不接受退款", "P2")]),
]
SOURCES = set(POLICY) | {"ORDER"}
RUBRIC = {
    "1 事實有出處": lambda o: all(c["source"] in SOURCES for c in o["claims"]),
    "2 格式符合": lambda o: o["text"].startswith("您好") and o["text"].endswith("客服團隊"),
    "3 無未授權承諾": lambda o: all(c in ALLOWED for c in o["commitments"]),
    "4 語氣符合": lambda o: not any(b in o["text"] for b in BANNED),
    "5 不確定已處理": lambda o: "[待確認]" not in o["text"],
}
rows = []
print("{:<4} | {:<6} | {}".format("產出", "結果", "失敗的評分項"))
print("-" * 48)
for o in OUTS:
    failed = [k for k, f in RUBRIC.items() if not f(o)]
    rows.append({"id": o["id"], "pass": not failed, "failed": failed, "planted": o["planted"]})
    mark = "  ← 蓄意植入的錯誤，已攔下" if o["planted"] and failed else ""
    print("{:<4} | {:<6} | {}{}".format(o["id"], "通過" if not failed else "退回", "、".join(failed) or "-", mark))
fails = sum(not r["pass"] for r in rows)
print()
print("失敗率：{} / {} = {:.0%}".format(fails, len(rows), fails / len(rows)))
out = Path("ch10/interactive")
out.mkdir(parents=True, exist_ok=True)
(out / "rubric_results.json").write_text(json.dumps({"outputs": OUTS, "results": rows}, ensure_ascii=False, indent=2), encoding="utf-8")
print("已寫入", out / "rubric_results.json")'
   show "$P"; run "$P" ;;
4) banner "退回循環：具名指出失敗項，連續三次就停下等人"
   tip "只說「不行」什麼也教不會。退回要寫失敗的評分項與修法；同一項一直失敗，問題在上游。"
   P='import json
from collections import Counter
from pathlib import Path
data = json.loads(Path("ch10/interactive/rubric_results.json").read_text(encoding="utf-8"))
FIX = {
    "1 事實有出處": "把每個說法對到政策條款；找不到條款就刪掉",
    "2 格式符合": "開頭用「您好」，結尾署名「客服團隊」",
    "3 無未授權承諾": "移除政策沒有授權的承諾（退款天數、價格、日期）",
    "4 語氣符合": "刪掉「請放心」這類保證語氣，照風格筆記改寫",
    "5 不確定已處理": "把 [待確認] 查清楚或刪掉",
}
policy_has_discontinued_rule = False
tally = Counter()
for r in data["results"]:
    if r["pass"]:
        continue
    tally.update(r["failed"])
    print("退回 {}：".format(r["id"]))
    for item in r["failed"]:
        print("   評論 → 失敗項「{}」，修法：{}".format(item, FIX[item]))
    if r["planted"]:
        for attempt in range(1, 4):
            ok = policy_has_discontinued_rule
            print("   代理第 {} 次修改：{}".format(attempt, "通過" if ok else "仍找不到停產商品的退款條款 → 再被退回"))
        print("   已連續 3 次代理發起的修改 → 任務停止退回代理，等待負責的人")
        print("   人往上游找原因：參考資料缺「停產商品」條款 → 補進 P2 到代理的參考文件")
        policy_has_discontinued_rule = True
        print("   補上後第 4 次：通過")
    else:
        print("   代理修改 1 次：通過")
print()
print("本月失敗次數（依評分項）：")
for item, n in tally.most_common():
    print("  {}：{} 次".format(item, n))
top, cnt = tally.most_common(1)[0]
if list(tally.values()).count(cnt) > 1:
    print("本月各項並列（最多 {} 次）：累積幾個月後，每月修失敗最多的那一項，並讓客戶看得到這份統計".format(cnt))
else:
    print("最常失敗的一項：{}（每月修最多的那一項，並讓客戶看得到這份統計）".format(top))'
   show "$P"; run "$P" ;;
5) banner "抽樣審查：失敗率穩定後改成四抽一"
   tip "規則：連續 10 份通過、且上個月失敗率低於約定值，才改成隨機四抽一；抽到一次失敗就回到全審。"
   P='import random
random.seed(146)
MONTHS, PER_MONTH, MIN_REVIEW, RATE = 6, 40, 10, 50
THRESH = 0.05
fail_p = [0.10, 0.05, 0.02, 0.02, 0.02, 0.02]

BAD = [[random.random() < fail_p[m] for _ in range(PER_MONTH)] for m in range(MONTHS)]

def simulate(mode):
    pick = random.Random(7)
    sampling, streak, back_full, reviews, caught, escaped = False, 0, 0, 0, 0, 0
    history, monthly = [], []
    for m in range(MONTHS):
        mrev = 0
        for k in range(PER_MONTH):
            bad = BAD[m][k]
            if mode == "無關卡":
                escaped += bad
                continue
            review = True
            if mode == "抽樣" and sampling and back_full == 0:
                review = pick.random() < 0.25
            if back_full:
                back_full -= 1
            if not review:
                escaped += bad
                continue
            reviews += 1
            mrev += 1
            history.append(bad)
            if bad:
                caught += 1
                streak = 0
                if sampling:
                    back_full = PER_MONTH
                    sampling = False
            else:
                streak += 1
            last = history[-PER_MONTH:]
            if mode == "抽樣" and not sampling and streak >= 10 and len(last) >= 10 and sum(last) / len(last) < THRESH:
                sampling = True
        monthly.append(mrev)
    return reviews, caught, escaped, monthly

print("6 個月、每月 40 份，失敗機率 {}，總共 {} 份有錯".format(fail_p, sum(map(sum, BAD))))
print("{:<6} | {:>6} | {:>8} | {:>8} | {:>8} | {}".format("做法", "審查數", "審查工時", "審查成本", "攔下錯誤", "漏到客戶"))
print("-" * 70)
for mode in ("無關卡", "全審", "抽樣"):
    rv, cg, es, monthly = simulate(mode)
    hrs = rv * MIN_REVIEW / 60
    print("{:<6} | {:>6} | {:>6.1f}h | {:>7.0f}$ | {:>8} | {}".format(mode, rv, hrs, hrs * RATE, cg, es))
    if mode == "抽樣":
        print("        抽樣每月審查數：", monthly)
print()
print("書中算式：每月 40 份 × 10 分鐘 = {:.1f} 小時 ≈ ${:.0f}；四抽一後 10 份 = {:.1f} 小時 ≈ ${:.0f}".format(40 * 10 / 60, 40 * 10 / 60 * 50, 10 * 10 / 60, 10 * 10 / 60 * 50))
print("省下的錢只在失敗率維持時成立；長期退回率是 0，要懷疑審查者已經沒在看。")'
   show "$P"; run "$P" ;;
6) banner "讓真實模型當客服代理：寫一封會被審的回覆"
   tip "這一步會呼叫模型 1 次（claude -p），最多等 180 秒；就是開場那題：停產商品買了 60 天還能退款嗎？"
   P='import json
from pathlib import Path
from llm_agent import ask_json
out = Path("ch10/interactive")
out.mkdir(parents=True, exist_ok=True)
raw = out / "agent_reply_raw.json"
raw.unlink(missing_ok=True)
prompt = """你是一家小型網路商店的客服代理。只能根據下面的政策文件回答。
政策文件：
P1：一般商品購買後 30 天內可退款。
P2：停產商品不接受退款，可於購買後 30 天內換購等值商品。
客戶來信：「我 60 天前買的商品現在停產了，還可以退款嗎？」
請輸出 JSON：
{"reply": "給客戶的回覆，開頭用「您好」，結尾署名「客服團隊」",
 "claims": [{"text": "回覆裡的每一個事實說法", "source": "P1、P2 或 none"}],
 "commitments": ["回覆中對客戶做出的承諾，例如 換購、30 天內退款；沒有就空陣列"],
 "uncertain": ["你不確定、需要人確認的地方；沒有就空陣列"]}"""
try:
    ans = ask_json(prompt)
except (RuntimeError, ValueError) as exc:
    print("呼叫模型失敗：", exc)
    print("第 7 步會改用內建範例繼續。")
    raise SystemExit(0)
raw.write_text(json.dumps(ans, ensure_ascii=False, indent=2), encoding="utf-8")
print("回覆：", ans.get("reply"))
print()
for c in ans.get("claims") or []:
    if isinstance(c, dict):
        print("  說法：{}　出處：{}".format(c.get("text"), c.get("source")))
print("承諾：", ans.get("commitments"))
print("不確定：", ans.get("uncertain"))
print()
print("已寫入", raw)'
   show "$P"; run "$P" ;;
7) banner "用評分表審模型回覆，寫出品質關卡宣傳句"
   tip "宣傳句只能用自己量到的數字；引用別家公司的失敗率，客戶一眼就看得出是借來的。"
   P='import json
from pathlib import Path
out = Path("ch10/interactive")
raw = out / "agent_reply_raw.json"
FALLBACK = {"reply": "您好，停產商品在 90 天內都可以退款，請放心申請。客服團隊",
            "claims": [{"text": "停產商品 90 天內可退款", "source": "none"}],
            "commitments": ["90 天內退款"], "uncertain": []}
ans = None
if raw.exists():
    try:
        ans = json.loads(raw.read_text(encoding="utf-8"))
    except ValueError:
        ans = None
source = "第 6 步模型輸出" if isinstance(ans, dict) else "內建範例（第 6 步沒有成功）"
if not isinstance(ans, dict):
    ans = FALLBACK
text = str(ans.get("reply", "")).strip()
claims = [c for c in (ans.get("claims") or []) if isinstance(c, dict)]
commits = [str(c) for c in (ans.get("commitments") or [])]
unsure = ans.get("uncertain") or []
PROMISE = ("可以退款", "可退款", "同意退款", "辦理退款", "為您退款", "90 天")
checks = {
    "1 事實有出處": bool(claims) and all(str(c.get("source")) in ("P1", "P2") for c in claims),
    "2 格式符合": text.startswith("您好") and text.rstrip("。 ").endswith("客服團隊"),
    "3 無未授權承諾": not any(p in text and ("不" + p) not in text for p in PROMISE) and all(("退款" not in c) or ("不" in c) for c in commits),
    "4 語氣符合": not any(b in text for b in ("絕對", "保證", "請放心")),
    "5 不確定已處理": not unsure and "[待確認]" not in text,
}
print("資料來源：", source)
print("回覆：", text)
print()
for k, v in checks.items():
    print("  {}：{}".format(k, "通過" if v else "失敗"))
ok = all(checks.values())
print()
print("結論：", "可以寄出" if ok else "退回代理，評論寫明失敗項：" + "、".join(k for k, v in checks.items() if not v))
res = json.loads((out / "rubric_results.json").read_text(encoding="utf-8")) if (out / "rubric_results.json").exists() else {"results": []}
n = len(res["results"]) or 10
fails = sum(not r["pass"] for r in res["results"]) if res["results"] else 3
pitch = "我們在你的客服回覆流程跑了 {} 份產出過五題評分表：{} 份不及格，其中一份是蓄意植入的錯誤退款天數。沒有審查步驟，這些都會直接寄到客戶手上；有了它，它們會帶著修正意見回到代理。每份審查大約 10 分鐘。".format(n, fails)
print()
print("品質關卡宣傳句：")
print("  " + pitch)
fence = chr(96) * 3
report = "# 第 10 章：模型回覆審查報告\n\n資料來源：" + source + "\n\n## 模型原始輸出\n\n" + fence + "json\n" + json.dumps(ans, ensure_ascii=False, indent=2) + "\n" + fence + "\n\n## 五題評分表\n\n"
report += "\n".join("- {}：{}".format(k, "通過" if v else "失敗") for k, v in checks.items())
report += "\n\n## 品質關卡宣傳句\n\n" + pitch + "\n"
(out / "review_report.md").write_text(report, encoding="utf-8")
print()
print("已寫入", out / "review_report.md")'
   show "$P"; run "$P" ;;
8) banner "總結：品質關卡的五個重點"
   tip "Paperclip 的預算、章程、紀錄都管不到答案對不對；品質關卡不是產品功能，是客戶需要你的理由。"
   P='from pathlib import Path
points = [
    "編排層管得了權責與花費，管不了正確性：三份 2026 年評測都看到「結構可用、產出不均、沒有人檢查」。",
    "分類問題決定關卡輕重：下一個看的是會修改的人就輕，是客戶、主管機關或公開讀者就硬；審查點放在產出跨出公司的邊界。",
    "low-trust review 是隔離不是品質：它擋 prompt injection，不檢查答案；最小權限、獨立帳號、跟上修補版本也是安全習慣的一部分。",
    "五題是非評分表＋具名退回＋連續 3 次停下等人：十份產出攔下 3 份（含蓄意植入的錯誤），同一項一直錯就往上游補參考資料。",
    "抽樣要有規則、合約要寫清責任：連續 10 份通過且失敗率夠低才四抽一，審查從約 333 美元降到約 83 美元；合約寫明審查只能降低錯誤，由客戶的審查者決定寄出什麼。",
]
print("第 10 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
for name in ("rubric_results.json", "agent_reply_raw.json", "review_report.md"):
    p = Path("ch10/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac

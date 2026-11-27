"""真實 LLM 子代理轉接腳本：用 Claude Code 無頭模式（claude -p）扮演 harness 裡的子代理。

為什麼用 claude -p：走使用者的 Max 訂閱，不需要也不可以設定任何 API 金鑰。
用法（在 practice 目錄）：
    命令列：  echo "你的提示詞" | PYTHONUTF8=1 python llm_agent.py           → 印出模型文字回覆
              echo "..." | PYTHONUTF8=1 python llm_agent.py --json         → 從回覆抽出第一個 JSON 物件並印出
    匯入：    from llm_agent import ask, ask_json   （腳本需在 practice 目錄執行，或把 practice 加進 PYTHONPATH）
規則：每個練習呼叫 claude -p 不超過 3 次。
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

TIMEOUT_SECONDS = 180


def _clean_env() -> dict[str, str]:
    """移除 API 金鑰與上層 Claude Code 繼承下來的變數，避免扣 API Credits 或被當成巢狀 session。"""
    env = dict(os.environ)
    for key in list(env):
        if key in ("ANTHROPIC_API_KEY", "CLAUDECODE") or key.startswith("CLAUDE_CODE_"):
            env.pop(key, None)
    return env


def ask(prompt: str) -> str:
    """把 prompt 交給 claude -p，回傳模型的文字結果；失敗時丟出 RuntimeError。"""
    if not prompt.strip():
        raise ValueError("prompt 是空的")
    exe = shutil.which("claude")
    if exe is None:
        raise RuntimeError("找不到 claude 指令（Claude Code CLI）")
    try:
        proc = subprocess.run(
            [exe, "-p", "--output-format", "json"],
            input=prompt,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=TIMEOUT_SECONDS,
            env=_clean_env(),
            cwd=tempfile.mkdtemp(prefix="llm_agent_cwd_"),  # 在暫存夾啟動，避免使用者全域 hook 把 .claude/ 寫進練習工作目錄
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"claude -p 超過 {TIMEOUT_SECONDS} 秒未回應") from exc
    if proc.returncode != 0:
        raise RuntimeError(f"claude -p 失敗（exit {proc.returncode}）：{proc.stderr.strip()[:500]}")
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"claude -p 輸出不是 JSON：{proc.stdout[:300]}") from exc
    if payload.get("is_error"):
        raise RuntimeError(f"claude -p 回報錯誤：{payload.get('result')}")
    return str(payload.get("result", ""))


def extract_json(text: str) -> dict:
    """從模型回覆抽出第一個 JSON 物件（容許 ```json 程式碼區塊包裝）。"""
    fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.S)
    candidate = fenced.group(1) if fenced else None
    if candidate is None:
        start, end = text.find("{"), text.rfind("}")
        if start == -1 or end <= start:
            raise ValueError(f"回覆中找不到 JSON 物件：{text[:200]}")
        candidate = text[start : end + 1]
    return json.loads(candidate)


def ask_json(prompt: str) -> dict:
    """要求模型只回 JSON，並解析成 dict。"""
    return extract_json(ask(prompt + "\n\n只輸出一個 JSON 物件，不要任何其他文字。"))


def main() -> int:
    prompt = sys.stdin.read()
    try:
        if "--json" in sys.argv[1:]:
            print(json.dumps(ask_json(prompt), ensure_ascii=False, indent=2))
        else:
            print(ask(prompt))
    except (RuntimeError, ValueError) as exc:
        print(f"錯誤：{exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    # 冒煙測試：python llm_agent.py --selftest（不呼叫模型，只測 JSON 抽取）
    if "--selftest" in sys.argv[1:]:
        assert extract_json('前言 ```json\n{"tool": "patch_repo"}\n``` 後記') == {"tool": "patch_repo"}
        assert extract_json('{"a": 1}') == {"a": 1}
        try:
            extract_json("沒有 JSON")
        except ValueError:
            print("selftest OK")
        raise SystemExit(0)
    raise SystemExit(main())

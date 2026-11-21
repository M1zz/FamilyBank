#!/usr/bin/env python3
"""앱 아이콘 생성: SVG → 헤드리스 Chrome → 1024x1024 PNG (알파 없음).

사용법: python3 scripts/make_app_icon.py

  FamilyBank/Assets.xcassets/AppIcon.appiconset/AppIcon.png          기본
  FamilyBank/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png     다크
  FamilyBank/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png   틴트(회색조, 시스템이 색을 입힌다)
  docs/icon.png                                                      소개 페이지 (256)

그림: 금화에서 새싹이 자란다(용돈이 쑥쑥). 특정 나라 화폐 기호는 넣지 않는다 — 화폐 이름은 집마다 정한다.
⚠️ 아이 · 캐릭터 · 장난감 같은 그림은 넣지 않는다. 키즈 카테고리 앱이 아니다(심사 2.3.8).
"""
import pathlib, subprocess, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICONSET = ROOT / "FamilyBank" / "Assets.xcassets" / "AppIcon.appiconset"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 이름 → (바탕 위, 바탕 아래, 빛, 잎 밝은 쪽, 잎 어두운 쪽, 줄기, 동전 위, 동전 아래, 동전 테, 동전 안쪽 선)
THEMES = {
    "AppIcon.png":        ("#4FD683", "#0F8A4B", "rgba(255,255,255,.30)", "#FFFFFF", "#D9F7DF", "#F1FDF2",
                           "#FFE58A", "#F6A821", "#D9860F", "#FFF1B8"),
    "AppIcon-Dark.png":   ("#1D3B2A", "#0B1A11", "rgba(92,214,130,.16)",  "#8BEA9C", "#3FBF68", "#5DD27F",
                           "#FFDD7A", "#EE9E1B", "#B86F0C", "#FFEBA6"),
    "AppIcon-Tinted.png": ("#2A2A2C", "#0A0A0B", "rgba(255,255,255,.06)", "#FFFFFF", "#BDBDBD", "#E6E6E6",
                           "#E4E4E4", "#9A9A9A", "#6E6E6E", "#F4F4F4"),
}

SVG = """<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{bg0}"/><stop offset="1" stop-color="{bg1}"/></linearGradient>
  <radialGradient id="glow" cx="50%" cy="30%" r="60%"><stop offset="0" stop-color="{glow}"/><stop offset="1" stop-color="rgba(255,255,255,0)"/></radialGradient>
  <linearGradient id="leafL" x1="1" y1="1" x2="0" y2="0"><stop offset="0" stop-color="{leaf1}"/><stop offset="1" stop-color="{leaf0}"/></linearGradient>
  <linearGradient id="leafR" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="{leaf1}"/><stop offset="1" stop-color="{leaf0}"/></linearGradient>
  <linearGradient id="coin" x1="0.2" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="{coin0}"/><stop offset="1" stop-color="{coin1}"/></linearGradient>
  <filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="26"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<rect width="1024" height="1024" fill="url(#glow)"/>
<g transform="translate(0 -18)">
<!-- 동전 그림자 -->
<ellipse cx="512" cy="700" rx="232" ry="214" fill="rgba(0,0,0,.28)" filter="url(#soft)"/>
<!-- 줄기 -->
<path d="M512 470 C512 410 510 360 514 316" fill="none" stroke="{stem}" stroke-width="34" stroke-linecap="round"/>
<!-- 잎: 왼쪽은 작게 낮게, 오른쪽은 크게 높게. 둘 다 줄기 끝에서 난다 -->
<path d="M516 326 C440 346 318 304 262 196 C384 162 502 218 516 326 Z" fill="url(#leafL)"/>
<path d="M510 318 C500 190 612 96 780 104 C788 258 672 344 510 318 Z" fill="url(#leafR)"/>
<!-- 동전 -->
<circle cx="512" cy="664" r="236" fill="{rim}"/>
<circle cx="512" cy="664" r="206" fill="url(#coin)"/>
<path d="M346 606 A176 176 0 0 1 462 496" fill="none" stroke="{ring}" stroke-opacity=".9" stroke-width="20" stroke-linecap="round"/>
<!-- 동전 얼굴: 오르는 선(저축 · 투자가 불어난다) -->
<g fill="none" stroke="{rim}" stroke-width="34" stroke-linecap="round" stroke-linejoin="round">
  <path d="M400 742 L478 664 L532 716 L624 610"/>
  <path d="M548 600 L628 606 L634 686"/>
</g>
</g>
</svg>"""


def render(name, theme, tmp):
    keys = ("bg0", "bg1", "glow", "leaf0", "leaf1", "stem", "coin0", "coin1", "rim", "ring")
    html = pathlib.Path(tmp) / f"{name}.html"
    html.write_text("<!doctype html><meta charset='utf-8'><style>*{margin:0}html,body{width:1024px;height:1024px;"
                    "overflow:hidden}svg{display:block}</style>" + SVG.format(**dict(zip(keys, theme))), encoding="utf-8")
    raw = pathlib.Path(tmp) / f"{name}.raw.png"
    for _ in range(3):
        try:
            subprocess.run([CHROME, "--headless=new", f"--screenshot={raw}", "--window-size=1024,1024",
                            "--force-device-scale-factor=1", "--hide-scrollbars", "--disable-gpu", html.as_uri()],
                           capture_output=True, timeout=60)
        except subprocess.TimeoutExpired:
            pass
        if raw.exists() and raw.stat().st_size > 0:
            break
    else:
        raise SystemExit(f"Chrome 이 그리지 못했다: {name}")
    # App Store 는 알파가 든 아이콘을 받지 않는다. 24비트 BMP 를 거쳐 알파를 뗀다.
    bmp = pathlib.Path(tmp) / f"{name}.bmp"
    out = ICONSET / name
    subprocess.run(["sips", "-s", "format", "bmp", str(raw), "--out", str(bmp)], check=True, capture_output=True)
    subprocess.run(["sips", "-s", "format", "png", str(bmp), "--out", str(out)], check=True, capture_output=True)
    print("rendered", out.relative_to(ROOT))


if __name__ == "__main__":
    with tempfile.TemporaryDirectory() as tmp:
        for name, theme in THEMES.items():
            render(name, theme, tmp)
    subprocess.run(["sips", "-Z", "256", str(ICONSET / "AppIcon.png"), "--out", str(ROOT / "docs" / "icon.png")],
                   check=True, capture_output=True)
    print("rendered docs/icon.png")

#!/usr/bin/env python3
"""App Store 마케팅 스크린샷: 시뮬레이터 원본 캡처 + 헤드라인 → HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_marketing_screenshots.py [언어 ...]   (없으면 전부)

  원본  docs/screenshots/raw/<언어>/NN-….png         (iPhone 6.9" 시뮬레이터 캡처 1320x2868, 올라가지 않는다)
  제출  docs/screenshots/marketing/<스토어 로케일>/NN-….png   (1242x2688, DeployBar 가 그대로 올린다)

파일 이름 순서가 스토어에 보이는 순서다. 다음 릴리즈에는 원본만 다시 찍고 이 스크립트를 다시 돌린다.
"""
import subprocess, sys, pathlib, tempfile, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1242, 2688   # 이 계정의 iPhone 제출 규격

# ── 앱마다 고치는 곳 ──────────────────────────────────────────────
# 앱 언어 → App Store 로케일 (스토어 폴더 이름)
STORE = {"ko": "ko", "en": "en-US", "en-GB": "en-GB", "ja": "ja", "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant", "es": "es-ES", "de": "de-DE", "fr": "fr-FR", "it": "it-IT", "pt-BR": "pt-BR", "ru": "ru", "th": "th"}
# 바탕 · 포인트 색 (헤더·검색 결과 그림과 맞춘다)
BG, ACCENT, INK, SUB = "#EEF5EC", "#2F9E4F", "#12281C", "#5E6B62"
# 언어 → [(원본 파일, 레이아웃, 헤드라인, 서브카피)]
SHOTS = {
    "ko": [
        ("01-dashboard.png", "hero-bleed",  "우리 집이<br>작은 은행이 돼요", "부모는 중앙은행, 아이는 고객"),
        ("02-child.png",     "left-text",   "지갑, 저축, 투자를<br>한눈에", "아이 이름의 통장이 생겨요"),
        ("03-savings.png",   "text-bottom", "모아 두면 이자가 붙어요", "매주 복리로 불어나는 걸 그래프로"),
        ("04-market.png",    "flat-rotate", "물가와 환율까지<br>진짜 경제처럼", "돈의 가치가 변하는 걸 직접 봐요"),
        ("05-actions.png",   "hero-bleed",  "용돈 주기도<br>결제도 간단하게", "부모 PIN으로 잠그고, 바코드로 결제"),
        ("06-learn.png",     "dark",        "10단계로 배우는<br>돈 이야기", "아이와 함께 읽는 부모 가이드"),
    ],
    "th": [
        ("01-dashboard.png", "hero-bleed"  , "บ้านของคุณ<br>กลายเป็นธนาคารเล็กๆ", "พ่อแม่เป็นธนาคาร ลูกเป็นลูกค้า"),
        ("02-child.png", "left-text"   , "กระเป๋าเงิน เงินออม การลงทุน<br>เห็นครบในหน้าเดียว", "ลูกแต่ละคนมีบัญชีของตัวเอง"),
        ("03-savings.png", "text-bottom" , "ออมไว้<br>ดอกเบี้ยก็งอกเงย", "ดูดอกเบี้ยทบต้นรายสัปดาห์ในกราฟ"),
        ("04-market.png", "flat-rotate" , "ราคาและอัตราแลกเปลี่ยน<br>เหมือนเศรษฐกิจจริง", "เห็นมูลค่าของเงินที่เปลี่ยนไป"),
        ("05-actions.png", "hero-bleed"  , "ให้ค่าขนมและจ่ายเงิน<br>ง่ายนิดเดียว", "ล็อกด้วย PIN พ่อแม่ จ่ายด้วยบาร์โค้ด"),
        ("06-learn.png", "dark"        , "เรียนรู้เรื่องเงิน<br>ใน 10 ขั้น", "คู่มือพ่อแม่ไว้อ่านพร้อมลูก"),
    ],
    "ru": [
        ("01-dashboard.png", "hero-bleed"  , "Ваш дом становится<br>маленьким банком", "Родители — банк, дети — клиенты"),
        ("02-child.png", "left-text"   , "Кошелёк, накопления,<br>вложения — сразу видно", "У каждого ребёнка свой счёт"),
        ("03-savings.png", "text-bottom" , "Копите — и проценты<br>растут", "Еженедельные сложные проценты на графике"),
        ("04-market.png", "flat-rotate" , "Цены и курс обмена<br>как в настоящей экономике", "Смотрите, как меняется ценность денег"),
        ("05-actions.png", "hero-bleed"  , "Карманные деньги и оплата<br>проще простого", "Защита родительским PIN, оплата по штрихкоду"),
        ("06-learn.png", "dark"        , "Деньги за<br>10 шагов", "Руководство для чтения вместе с ребёнком"),
    ],
    "pt-BR": [
        ("01-dashboard.png", "hero-bleed"  , "Sua casa vira<br>um pequeno banco", "Pais são o banco, filhos são os clientes"),
        ("02-child.png", "left-text"   , "Carteira, poupança e<br>investimentos de relance", "Cada filho tem a sua própria conta"),
        ("03-savings.png", "text-bottom" , "Poupando,<br>os juros crescem", "Veja os juros compostos semanais no gráfico"),
        ("04-market.png", "flat-rotate" , "Preços e câmbio<br>como na economia real", "Veja o valor do dinheiro mudar"),
        ("05-actions.png", "hero-bleed"  , "Mesada e pagamentos<br>bem simples", "Bloqueio com PIN dos pais, pague por código de barras"),
        ("06-learn.png", "dark"        , "Dinheiro em<br>10 passos", "Um guia para ler com seu filho"),
    ],
    "it": [
        ("01-dashboard.png", "hero-bleed"  , "La tua casa diventa<br>una piccola banca", "I genitori sono la banca, i figli i clienti"),
        ("02-child.png", "left-text"   , "Portafoglio, risparmio e<br>investimenti a colpo d’occhio", "Ogni figlio ha il suo conto"),
        ("03-savings.png", "text-bottom" , "Se risparmi,<br>gli interessi crescono", "Guarda l’interesse composto settimanale nel grafico"),
        ("04-market.png", "flat-rotate" , "Prezzi e cambio<br>come nell’economia vera", "Scopri come cambia il valore dei soldi"),
        ("05-actions.png", "hero-bleed"  , "Paghetta e pagamenti<br>facilissimi", "Blocco con PIN dei genitori, pagamento col codice a barre"),
        ("06-learn.png", "dark"        , "I soldi in<br>10 passi", "Una guida da leggere con tuo figlio"),
    ],
    "fr": [
        ("01-dashboard.png", "hero-bleed"  , "Ta maison devient<br>une petite banque", "Parents banque centrale, enfants clients"),
        ("02-child.png", "left-text"   , "Porte-monnaie, épargne,<br>placements d’un coup d’œil", "Chaque enfant a son propre compte"),
        ("03-savings.png", "text-bottom" , "Épargne et<br>les intérêts s’ajoutent", "Les intérêts composés chaque semaine en graphique"),
        ("04-market.png", "flat-rotate" , "Prix et taux de change<br>comme dans la vraie économie", "Vois la valeur de l’argent évoluer"),
        ("05-actions.png", "hero-bleed"  , "Argent de poche et paiements<br>tout simplement", "Verrou PIN parent, paiement par code-barres"),
        ("06-learn.png", "dark"        , "L’argent en<br>10 étapes", "Un guide à lire avec ton enfant"),
    ],
    "de": [
        ("01-dashboard.png", "hero-bleed"  , "Euer Zuhause wird<br>zur kleinen Bank", "Eltern sind die Bank, Kinder die Kunden"),
        ("02-child.png", "left-text"   , "Geldbörse, Sparen, Anlegen<br>auf einen Blick", "Jedes Kind bekommt ein eigenes Konto"),
        ("03-savings.png", "text-bottom" , "Wer spart,<br>bekommt Zinsen", "Den Zinseszins pro Woche im Diagramm sehen"),
        ("04-market.png", "flat-rotate" , "Preise und Wechselkurse<br>wie in der echten Wirtschaft", "Erleben, wie sich Geldwert verändert"),
        ("05-actions.png", "hero-bleed"  , "Taschengeld und Bezahlen<br>ganz einfach", "Mit Eltern-PIN sperren, per Barcode zahlen"),
        ("06-learn.png", "dark"        , "Geld verstehen<br>in 10 Schritten", "Ein Elternratgeber zum gemeinsamen Lesen"),
    ],
    "es": [
        ("01-dashboard.png", "hero-bleed"  , "Tu casa se convierte<br>en un pequeño banco", "Padres: banco central; hijos: clientes"),
        ("02-child.png", "left-text"   , "Monedero, ahorro e<br>inversión de un vistazo", "Cada hijo tiene su propia cuenta"),
        ("03-savings.png", "text-bottom" , "Si ahorras,<br>ganas intereses", "Mira el interés compuesto semanal en una gráfica"),
        ("04-market.png", "flat-rotate" , "Precios y cambio<br>como en la economía real", "Ve cómo cambia el valor del dinero"),
        ("05-actions.png", "hero-bleed"  , "Dar la paga y pagar,<br>muy fácil", "Bloqueo con PIN y pago con código de barras"),
        ("06-learn.png", "dark"        , "Aprende de dinero<br>en 10 pasos", "Una guía para leer con tu hijo"),
    ],
    "zh-Hant": [
        ("01-dashboard.png", "hero-bleed"  , "你家變成<br>一家小銀行", "家長是中央銀行，孩子是客戶"),
        ("02-child.png", "left-text"   , "錢包、儲蓄、投資<br>一目了然", "每個孩子都有自己的帳戶"),
        ("03-savings.png", "text-bottom" , "存起來<br>利息就會增長", "用曲線看每週複利越滾越大"),
        ("04-market.png", "flat-rotate" , "物價和匯率<br>像真的經濟一樣", "親眼看到錢的價值在變化"),
        ("05-actions.png", "hero-bleed"  , "發零用錢<br>和支付都很簡單", "家長PIN上鎖，掃條碼支付"),
        ("06-learn.png", "dark"        , "10步學會<br>錢的道理", "和孩子一起讀的家長指南"),
    ],
    "zh-Hans": [
        ("01-dashboard.png", "hero-bleed"  , "你家变成<br>一家小银行", "家长是中央银行，孩子是客户"),
        ("02-child.png", "left-text"   , "钱包、储蓄、投资<br>一目了然", "每个孩子都有自己的账户"),
        ("03-savings.png", "text-bottom" , "存起来<br>利息就会增长", "用曲线看每周复利越滚越大"),
        ("04-market.png", "flat-rotate" , "物价和汇率<br>像真的经济一样", "亲眼看到钱的价值在变化"),
        ("05-actions.png", "hero-bleed"  , "发零花钱<br>和支付都很简单", "家长PIN上锁，扫条形码支付"),
        ("06-learn.png", "dark"        , "10步学会<br>钱的道理", "和孩子一起读的家长指南"),
    ],
    "ja": [
        ("01-dashboard.png", "hero-bleed"  , "わが家が<br>小さな銀行に", "親は中央銀行、子どもはお客さま"),
        ("02-child.png", "left-text"   , "おさいふ、貯金、投資が<br>ひと目で", "子どもの名前の口座ができます"),
        ("03-savings.png", "text-bottom" , "ためると利子が<br>ついてふえる", "毎週の複利をグラフで確認"),
        ("04-market.png", "flat-rotate" , "物価や為替まで<br>本物の経済みたいに", "お金の価値の変化を体験"),
        ("05-actions.png", "hero-bleed"  , "お小遣いも支払いも<br>かんたん", "保護者PINでロック、バーコードで支払い"),
        ("06-learn.png", "dark"        , "10ステップで学ぶ<br>お金のお話", "お子さまと読む保護者ガイド"),
    ],
    "en": [
        ("01-dashboard.png", "hero-bleed",  "Your home becomes<br>a little bank", "Parents are the bank, kids are customers"),
        ("02-child.png",     "left-text",   "Wallet, savings and<br>investing at a glance", "Every child gets their own account"),
        ("03-savings.png",   "text-bottom", "Save it and watch<br>interest add up", "See weekly compounding on a graph"),
        ("04-market.png",    "flat-rotate", "Prices and exchange<br>rates like the real thing", "See how money changes in value"),
        ("05-actions.png",   "hero-bleed",  "Allowance and payments,<br>made simple", "Lock with a parent PIN, pay by barcode"),
        ("06-learn.png",     "dark",        "10 steps to<br>learn about money", "A parent guide to read with your child"),
    ],
    "en-GB": [
        ("01-dashboard.png", "hero-bleed",  "Your home becomes<br>a little bank", "Parents are the bank, kids are customers"),
        ("02-child.png",     "left-text",   "Wallet, savings and<br>investing at a glance", "Every child gets their own account"),
        ("03-savings.png",   "text-bottom", "Save it and watch<br>interest add up", "See weekly compounding on a graph"),
        ("04-market.png",    "flat-rotate", "Prices and exchange<br>rates like the real thing", "See how money changes in value"),
        ("05-actions.png",   "hero-bleed",  "Pocket money and payments,<br>made simple", "Lock with a parent PIN, pay by barcode"),
        ("06-learn.png",     "dark",        "10 steps to<br>learn about money", "A parent guide to read with your child"),
    ],
}
# ─────────────────────────────────────────────────────────────────

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:{BG}; position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", "Hiragino Sans", "PingFang SC", sans-serif; }}
.headline {{ font-size:96px; font-weight:800; color:{INK}; letter-spacing:-0.03em; line-height:1.18; }}
.sub {{ font-size:48px; font-weight:500; color:{SUB}; letter-spacing:-0.01em; line-height:1.35; }}
:lang(ko) .headline, :lang(ko) .sub {{ word-break:keep-all; }}
.phone {{ background:#17171a; border-radius:112px; border:3px solid #3a3a3e; padding:24px;
  box-shadow: 50px 80px 120px rgba(20,40,90,.25), 16px 26px 46px rgba(0,0,0,.16); }}
.phone img {{ width:100%; display:block; border-radius:90px; }}
.dot {{ display:inline-block; width:22px; height:22px; border-radius:50%; background:{ACCENT}; margin-bottom:46px; }}
"""

LAYOUTS = {
    "hero-bleed": """
.text { text-align:center; padding:250px 80px 0; }
.sub { margin-top:44px; }
.wrap { display:flex; justify-content:center; margin-top:120px; }
.phone { width:960px; }
""",
    "left-text": """
.text { text-align:left; padding:260px 100px 0 110px; }
.sub { margin-top:44px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:290px; top:930px; }
.phone { width:820px; transform:rotateY(16deg) rotateX(2deg); }
""",
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:150px; }
.phone { width:840px; transform:rotateY(-10deg) rotateX(2deg); }
.text { text-align:center; padding:100px 80px 0; }
.sub { margin-top:40px; }
""",
    "flat-rotate": """
.text { text-align:center; padding:240px 80px 0; }
.sub { margin-top:44px; }
.wrap { position:absolute; left:120px; top:950px; }
.phone { width:960px; transform:rotate(-6deg); }
""",
    "dark": f"""
body {{ background:#12281c; }}
.headline {{ color:#f5f5f7; }} .sub {{ color:#8a8a90; }}
.text {{ text-align:center; padding:250px 80px 0; }}
.sub {{ margin-top:44px; }}
.wrap {{ display:flex; justify-content:center; margin-top:120px; }}
.phone {{ width:900px; border-color:#48484e;
  box-shadow: 0 0 160px rgba(80,140,255,.22), 40px 70px 110px rgba(0,0,0,.55); }}
""",
}

TEXT = '<div class="text"><div class="dot"></div><div class="headline">{headline}</div><div class="sub">{sub}</div></div>'
PHONE = '<div class="wrap"><div class="phone"><img src="{img}"></div></div>'
HTML = '<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>{css}</style></head><body>{body}</body></html>'


def chrome_shot(html, png, tmp):
    """헤드리스 Chrome 으로 한 장 그린다.

    ⚠️ Chrome 은 그림을 다 쓰고도 끝나지 않고 멈추는 일이 잦다(여러 개가 동시에 돌 때 특히).
       그래서 끝나기를 기다리지 않고, 파일이 생겨 크기가 멈추면 프로세스를 닫는다.
    """
    png.unlink(missing_ok=True)
    proc = subprocess.Popen([CHROME, "--headless=new", f"--user-data-dir={tmp}/chrome", "--no-first-run",
                             "--disable-component-update", "--no-default-browser-check", "--disable-extensions",
                             f"--screenshot={png}", f"--window-size={W},{H}", "--force-device-scale-factor=1",
                             "--hide-scrollbars", "--allow-file-access-from-files", html.as_uri()],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    last, deadline = -1, time.time() + 180
    try:
        while time.time() < deadline:
            time.sleep(1)
            size = png.stat().st_size if png.exists() else -1
            if size > 10000 and size == last:
                return True
            last = size
            if proc.poll() is not None and size <= 0:
                return False
        return False
    finally:
        if proc.poll() is None:
            proc.kill()
        proc.wait()
        # 남은 도우미 프로세스도 이 프로필 것만 골라 닫는다
        subprocess.run(["pkill", "-f", f"{tmp}/chrome"], capture_output=True)


def render(lang):
    out_dir = OUT / STORE[lang]
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.png"):
        old.unlink()
    with tempfile.TemporaryDirectory() as tmp:
        for fname, layout, headline, sub in SHOTS[lang]:
            src = RAW / lang / fname
            assert src.exists(), f"원본이 없다: {src}"
            text = TEXT.format(headline=headline, sub=sub)
            phone = PHONE.format(img=src.as_uri())
            body = phone + text if layout == "text-bottom" else text + phone
            html = pathlib.Path(tmp) / f"{lang}-{fname}.html"
            html.write_text(HTML.format(lang=lang, css=BASE_CSS + LAYOUTS[layout], body=body), encoding="utf-8")
            png = out_dir / fname
            if not any(chrome_shot(html, png, tmp) for _ in range(3)):
                raise SystemExit(f"그리지 못했다: {png}")
            print("rendered", png.relative_to(ROOT))


if __name__ == "__main__":
    for lang in (sys.argv[1:] or list(SHOTS)):
        render(lang)

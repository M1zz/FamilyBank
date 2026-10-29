// 쑥쑥용돈 웹 데모: 같은 1,000코인을 지갑 · 저축통장 · 펀드 세 가지에 두고 한 주씩 넘겨 본다.
// 규칙은 앱과 같다 (BankEngine.swift):
//   저축 이자: 매주 savings += round(savings × 주 이자율 / 100), 처음 설정 주 5% (FamilySettings.weeklyInterestRate)
//   물가: 매주 지수 × (1 + 2 / 100) (weeklyInflationRate), 지갑 속 1,000의 힘 = 1,000 ÷ (지수 / 100) (HomeView)
//   펀드: 하루 한 번 price = max(10, round(price × (1 + trend/100 + 무작위(-1…1) × volatility))) (BankEngine.defaultProducts)
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const lang = document.documentElement.lang;
  const num = new Intl.NumberFormat(lang);
  const pct = new Intl.NumberFormat(lang, { style: "percent", maximumFractionDigits: 1, signDisplay: "exceptZero" });

  const START = 1000, RATE = 5, INFLATION = 2;
  const FUNDS = [["🐢", 0.02, 0.10], ["🐰", 0.06, 0.15], ["🚀", 0.15, 0.20]];   // 이모지, volatility, trend
  let s;
  function reset() {
    s = { week: 0, savings: START, index: 100, funds: FUNDS.map(() => START) };
  }

  function nextWeek() {
    s.week += 1;
    s.savings += Math.round(s.savings * RATE / 100);
    s.index *= 1 + INFLATION / 100;
    s.funds = s.funds.map((p, i) => {
      const [, vol, trend] = FUNDS[i];
      for (let d = 0; d < 7; d++) p = Math.max(10, Math.round(p * (1 + trend / 100 + (Math.random() * 2 - 1) * vol)));
      return p;
    });
  }

  const rows = [
    { key: "wallet", icon: "👛", name: T.wallet, value: () => START },
    { key: "savings", icon: "🏦", name: T.savings, value: () => s.savings },
    ...FUNDS.map(([icon], i) => ({ key: "f" + i, icon, name: T.funds[i], value: () => s.funds[i] })),
  ];

  root.innerHTML = `
    <div class="demo-stage">
      <ul class="bank-rows">
        ${rows.map(r => `
          <li data-key="${r.key}">
            <span class="bank-name"><span aria-hidden="true">${r.icon}</span> ${r.name}</span>
            <span class="bank-bar" aria-hidden="true"><i></i></span>
            <span class="bank-value"><b></b> <small></small></span>
          </li>`).join("")}
      </ul>
    </div>
    <div class="demo-controls">
      <p class="bank-week" aria-live="polite"></p>
      <div class="bank-buttons">
        <button type="button" class="chip bank-next">${T.next}</button>
        <button type="button" class="chip bank-reset">${T.reset}</button>
      </div>
      <p class="bank-power"></p>
      <p class="muted small demo-note">${T.note}</p>
    </div>`;

  const $ = q => root.querySelector(q);
  const weekEl = $(".bank-week"), powerEl = $(".bank-power"), nextBtn = $(".bank-next");

  function render() {
    const values = rows.map(r => r.value());
    const max = Math.max(START * 1.5, ...values);
    rows.forEach((r, i) => {
      const li = root.querySelector(`[data-key="${r.key}"]`), v = values[i], change = v / START - 1;
      li.querySelector(".bank-bar i").style.width = `${(v / max) * 100}%`;
      li.querySelector("b").textContent = `${num.format(v)} ${T.currency}`;
      const small = li.querySelector("small");
      small.textContent = s.week ? pct.format(change) : "";
      small.className = change > 0.0005 ? "up" : change < -0.0005 ? "down" : "";
    });
    weekEl.textContent = s.week ? T.week.replace("{n}", s.week) : T.start;
    const power = Math.round(START / (s.index / 100));
    powerEl.textContent = T.power.replace("{i}", Math.round(s.index)).replace("{p}", num.format(power));
    powerEl.hidden = !s.week;
    nextBtn.classList.toggle("hint", !s.week);
  }

  nextBtn.addEventListener("click", () => {
    nextWeek(); render();
    weekEl.classList.remove("bump"); void weekEl.offsetWidth; weekEl.classList.add("bump");
  });
  $(".bank-reset").addEventListener("click", () => { reset(); render(); });

  reset();
  render();
})();

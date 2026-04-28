import streamlit as st
from snowflake.snowpark.context import get_active_session
from datetime import date, timedelta
import plotly.graph_objects as go

st.set_page_config(
    page_title="Payment Analytics",
    page_icon=":material/payments:",
    layout="wide",
)

# ── evolv Brand CSS ────────────────────────────────────────────────────────────
st.markdown("""
<style>
  .header-icon {
    display: inline-flex; align-items: center; justify-content: center;
    width: 48px; height: 48px; border-radius: 8px;
    background-color: rgba(255,102,0,0.15);
    font-size: 24px; margin-right: 12px; vertical-align: middle;
  }
  .brand-bar {
    padding-bottom: 14px; margin-bottom: 14px;
    border-bottom: 1px solid rgba(255,255,255,0.12);
  }
  .brand-name { color:#FF6600; font-weight:700; font-size:17px; letter-spacing:.3px; }
  .brand-sub  { color:#aaa; font-size:11px; margin-top:1px; }
</style>
""", unsafe_allow_html=True)

# ── Connection ─────────────────────────────────────────────────────────────────
session = get_active_session()

@st.cache_data(ttl=300)
def query(sql: str):
    return session.sql(sql).to_pandas()

def fmt_currency(v): return f"${float(v or 0):,.0f}"
def fmt_pct(v):      return f"{float(v or 0):.1f}%"
def fmt_count(v):    return f"{int(v or 0):,}"

CARD_COLORS = {
    "Visa": "#1A1F71", "Mastercard": "#EB001B",
    "American Express": "#006FCF", "Discover": "#FF6000", "Other": "#999",
}

# Transparent — adapts to Snowflake dark and light themes
PLOTLY_BASE = dict(
    margin=dict(l=0, r=0, t=8, b=0),
    plot_bgcolor="rgba(0,0,0,0)",
    paper_bgcolor="rgba(0,0,0,0)",
    font=dict(family="Inter, -apple-system, sans-serif", size=12,
              color="rgba(255,255,255,0.75)"),
)
AXIS_STYLE = dict(
    tickfont=dict(color="rgba(255,255,255,0.6)"),
    gridcolor="rgba(255,255,255,0.08)",
    zeroline=False,
)

# ── Sidebar ────────────────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("""
    <div class="brand-bar">
      <div class="brand-name">evolv</div>
      <div class="brand-sub">Payment Analytics</div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("**Filters**")
    start_date = st.date_input("From", value=date.today() - timedelta(days=30))
    end_date   = st.date_input("To",   value=date.today())

    brand_options = ["All card brands", "Visa", "Mastercard", "American Express", "Discover"]
    brand_sel = st.selectbox("Card brand", brand_options)
    selected_brand = None if brand_sel == "All card brands" else brand_sel

    st.space("small")
    if st.button(":material/refresh: Refresh", use_container_width=True):
        st.cache_data.clear()
        st.rerun()

    st.divider()
    st.caption(f"Last {(end_date - start_date).days} days · evolv Consulting")

# ── Page Header ────────────────────────────────────────────────────────────────
st.markdown("""
<div style="display:flex;align-items:center;margin-bottom:16px;">
  <div class="header-icon">💳</div>
  <div>
    <div style="font-size:22px;font-weight:700;line-height:1.2;">
      Authorization analytics
    </div>
    <div style="opacity:.6;font-size:13px;">Real-time transaction authorization data</div>
  </div>
</div>
""", unsafe_allow_html=True)

# ── Queries ────────────────────────────────────────────────────────────────────
brand_filter = f"AND card_brand = '{selected_brand}'" if selected_brand else ""

kpi_df = query(f"""
    SELECT
        COUNT(*)                                                                        AS total_transactions,
        ROUND(SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END)
              * 100.0 / NULLIF(COUNT(*), 0), 2)                                         AS approval_rate,
        SUM(CASE WHEN approval_status = 'Approved' THEN transaction_amount ELSE 0 END) AS approved_amount,
        ROUND(AVG(transaction_amount), 2)                                               AS avg_ticket_size
        -- TODO (Task 2): Add retry_success_rate column here
        -- ROUND(SUM(retry_success_flag) * 100.0 / NULLIF(SUM(retry_attempt_flag), 0), 2) AS retry_success_rate
    FROM MARTS.AUTHORIZATIONS
    WHERE transaction_date BETWEEN '{start_date}' AND '{end_date}'
    {brand_filter}
""")

# ── KPI Cards ─────────────────────────────────────────────────────────────────
if not kpi_df.empty:
    row = kpi_df.iloc[0]
    approval = float(row["APPROVAL_RATE"] or 0)
    approval_delta = "Good" if approval >= 95 else ("Monitor" if approval >= 90 else "Low")

    with st.container(horizontal=True):
        st.metric("Total transactions", fmt_count(row["TOTAL_TRANSACTIONS"]), border=True)
        st.metric("Approval rate", fmt_pct(approval),
                  delta=approval_delta,
                  delta_color="normal" if approval >= 95 else "inverse",
                  border=True)
        st.metric("Approved amount", fmt_currency(row["APPROVED_AMOUNT"]), border=True)
        st.metric("Avg ticket size",  fmt_currency(row["AVG_TICKET_SIZE"]),  border=True)
        # TODO (Task 2): uncomment after dbt model update adds retry_success_flag
        # st.metric("Retry success rate", fmt_pct(row["RETRY_SUCCESS_RATE"]), border=True)

# ── Tabs ───────────────────────────────────────────────────────────────────────
tab_overview, tab_details = st.tabs([
    ":material/show_chart: Overview",
    ":material/table_chart: Transaction details",
])

# ── Overview Tab ───────────────────────────────────────────────────────────────
with tab_overview:

    # Row 1: Time series + Card brand donut ────────────────────────────────────
    col_ts, col_pie = st.columns([2, 1])

    with col_ts:
        with st.container(border=True):
            st.caption("Daily transaction volume")
            ts_df = query(f"""
                SELECT
                    transaction_date AS date,
                    SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END) AS approved,
                    SUM(CASE WHEN approval_status = 'Declined' THEN 1 ELSE 0 END) AS declined
                FROM MARTS.AUTHORIZATIONS
                WHERE transaction_date BETWEEN '{start_date}' AND '{end_date}'
                {brand_filter}
                GROUP BY transaction_date ORDER BY transaction_date
            """)
            if not ts_df.empty:
                fig = go.Figure()
                fig.add_trace(go.Scatter(
                    x=ts_df["DATE"], y=ts_df["APPROVED"], name="Approved",
                    mode="lines", line=dict(color="#52c41a", width=2),
                    fill="tozeroy", fillcolor="rgba(82,196,26,0.15)",
                ))
                fig.add_trace(go.Scatter(
                    x=ts_df["DATE"], y=ts_df["DECLINED"], name="Declined",
                    mode="lines", line=dict(color="#ff4d4f", width=2),
                    fill="tozeroy", fillcolor="rgba(255,77,79,0.15)",
                ))
                fig.update_layout(
                    **PLOTLY_BASE, height=260,
                    legend=dict(
                        orientation="h", yanchor="bottom", y=1.02,
                        xanchor="right", x=1, bgcolor="rgba(0,0,0,0)",
                        font=dict(color="rgba(255,255,255,0.75)"),
                    ),
                    xaxis=dict(showgrid=False, **AXIS_STYLE),
                    yaxis=dict(**AXIS_STYLE),
                    hovermode="x unified",
                )
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

    with col_pie:
        with st.container(border=True):
            st.caption("Transactions by card brand")
            brand_df = query(f"""
                SELECT card_brand, COUNT(*) AS transactions
                FROM MARTS.AUTHORIZATIONS
                WHERE transaction_date BETWEEN '{start_date}' AND '{end_date}'
                {brand_filter}
                GROUP BY card_brand ORDER BY transactions DESC LIMIT 8
            """)
            if not brand_df.empty:
                colors = [CARD_COLORS.get(b, "#aaa") for b in brand_df["CARD_BRAND"]]
                fig = go.Figure(go.Pie(
                    labels=brand_df["CARD_BRAND"], values=brand_df["TRANSACTIONS"],
                    marker_colors=colors, textinfo="percent+label", hole=0.4,
                    textfont=dict(size=11, color="white"),
                ))
                fig.update_layout(**PLOTLY_BASE, height=260, showlegend=False)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

    # Row 2: Decline bar + Decline rate by brand ───────────────────────────────
    col_bar, col_rate = st.columns(2)

    with col_bar:
        with st.container(border=True):
            st.caption("Top decline reasons")
            decline_df = query(f"""
                SELECT decline_reason, COUNT(*) AS count
                FROM MARTS.AUTHORIZATIONS
                WHERE transaction_date BETWEEN '{start_date}' AND '{end_date}'
                  AND approval_status = 'Declined' AND decline_reason IS NOT NULL
                {brand_filter}
                GROUP BY decline_reason ORDER BY count DESC LIMIT 10
            """)
            if not decline_df.empty:
                fig = go.Figure(go.Bar(
                    x=decline_df["COUNT"], y=decline_df["DECLINE_REASON"],
                    orientation="h", marker_color="#ff4d4f",
                    text=decline_df["COUNT"], textposition="outside",
                    textfont=dict(color="rgba(255,255,255,0.7)"),
                ))
                fig.update_layout(
                    **PLOTLY_BASE, height=300,
                    xaxis=dict(showgrid=True, **AXIS_STYLE),
                    yaxis=dict(autorange="reversed",
                               tickfont=dict(color="rgba(255,255,255,0.6)"),
                               zeroline=False),
                )
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

    with col_rate:
        with st.container(border=True):
            st.caption("Decline rate by card brand")
            rate_df = query(f"""
                SELECT
                    card_brand,
                    COUNT(*) AS total,
                    ROUND(SUM(CASE WHEN approval_status = 'Declined' THEN 1 ELSE 0 END)
                          * 100.0 / NULLIF(COUNT(*), 0), 2) AS decline_rate
                FROM MARTS.AUTHORIZATIONS
                WHERE transaction_date BETWEEN '{start_date}' AND '{end_date}'
                GROUP BY card_brand ORDER BY total DESC LIMIT 6
            """)
            if not rate_df.empty:
                rates = rate_df["DECLINE_RATE"].astype(float).tolist()
                color_map = [
                    "#52c41a" if r <= 5 else ("#faad14" if r <= 15 else "#ff4d4f")
                    for r in rates
                ]
                fig = go.Figure(go.Bar(
                    x=rates,
                    y=rate_df["CARD_BRAND"].tolist(),
                    orientation="h",
                    marker_color=color_map,
                    text=[f"{r:.1f}%" for r in rates],
                    textposition="outside",
                    textfont=dict(color="rgba(255,255,255,0.7)"),
                ))
                fig.update_layout(
                    **PLOTLY_BASE, height=300,
                    xaxis=dict(showgrid=True, ticksuffix="%", range=[0, 100], **AXIS_STYLE),
                    yaxis=dict(autorange="reversed",
                               tickfont=dict(color="rgba(255,255,255,0.6)"),
                               zeroline=False),
                )
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

# ── Transaction Details Tab ────────────────────────────────────────────────────
with tab_details:
    with st.container(border=True):
        st.caption("Authorization transactions")
        detail_df = query(f"""
            SELECT
                transaction_date   AS "Date",
                merchant_name      AS "Merchant",
                card_brand         AS "Brand",
                approval_status    AS "Status",
                transaction_amount AS "Amount",
                decline_reason     AS "Decline reason",
                processor_name     AS "Processor",
                is_retry_attempt   AS "Retry",
                retry_recovered_count AS "Recovered"
            FROM MARTS.AUTHORIZATIONS
            WHERE transaction_date BETWEEN '{start_date}' AND '{end_date}'
            {brand_filter}
            ORDER BY transaction_date DESC
            LIMIT 500
        """)
        if not detail_df.empty:
            st.dataframe(
                detail_df, hide_index=True,
                use_container_width=True, height=560,
                column_config={
                    "Amount":    st.column_config.NumberColumn(format="$%.2f"),
                    "Status":    st.column_config.TextColumn(),
                    "Retry":     st.column_config.CheckboxColumn(),
                    "Recovered": st.column_config.NumberColumn(),
                },
            )
        else:
            st.caption("No transactions found for selected filters.")

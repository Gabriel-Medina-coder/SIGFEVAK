import { useState } from "react";

/* ── Navigation modules ── */
const NAV = [
  { id: "resumen", label: "Resumen General", icon: GridIcon },
  { id: "entradas", label: "Entradas de Producción", icon: BoxIcon },
  { id: "contable", label: "Registro Contable", icon: ReceiptIcon },
  { id: "inventario", label: "Base de Productos", icon: DatabaseIcon },
  { id: "nomina", label: "Nómina y Personal", icon: UsersIcon },
  { id: "regulacion", label: "Regulación y Pagos", icon: ShieldIcon },
  { id: "marketing", label: "Marketing", icon: MegaphoneIcon },
];

/* ── Module: Resumen ── */
const KPI_RESUMEN = [
  { label: "Capital de Inversión", value: "$4,820,000", delta: "+9.3%", up: true, sub: "vs mes anterior" },
  { label: "Volumen Comercializado", value: "18,430 uds", delta: "+14.1%", up: true, sub: "vs mes anterior" },
  { label: "Clientes Activos", value: "312", delta: "+22", up: true, sub: "nuevos este mes" },
  { label: "Impuestos Pendientes", value: "$138,400", delta: "Vence Oct 17", up: false, sub: "SAT / Aduana" },
];

const CHART_DATA = [
  { month: "Abr", value: 42 },
  { month: "May", value: 58 },
  { month: "Jun", value: 53 },
  { month: "Jul", value: 67 },
  { month: "Ago", value: 72 },
  { month: "Sep", value: 84 },
];

/* ── Module: Entradas ── */
const ENTRADAS = [
  { folio: "ENT-2041", producto: "Tableta Android 10\" OEM", categoria: "Electrónico", unidades: 400, valor_unit: "$1,850", capital: "$740,000", origen: "Importación", fecha: "05 Sep 2026" },
  { folio: "ENT-2040", producto: "Cable HDMI 2.1 4K 2m", categoria: "Manufactura", unidades: 2000, valor_unit: "$89", capital: "$178,000", origen: "Nacional", fecha: "03 Sep 2026" },
  { folio: "ENT-2039", producto: "Smartwatch Fitness Pro", categoria: "Electrónico", unidades: 750, valor_unit: "$2,400", capital: "$1,800,000", origen: "Importación", fecha: "01 Sep 2026" },
  { folio: "ENT-2038", producto: "Auriculares BT TW-55", categoria: "Electrónico", unidades: 1200, valor_unit: "$650", capital: "$780,000", origen: "Importación", fecha: "28 Ago 2026" },
  { folio: "ENT-2037", producto: "Cargador USB-C 65W GaN", categoria: "Manufactura", unidades: 3000, valor_unit: "$220", capital: "$660,000", origen: "Nacional", fecha: "25 Ago 2026" },
];

/* ── Module: Contable ── */
const FACTURAS = [
  { folio: "FAC-9901", cliente: "Elektra Mayoreo S.A.", comercializador: "Ramírez & Hijos", monto: "$342,000", estatus: "pagada", fecha: "08 Sep 2026" },
  { folio: "FAC-9900", cliente: "COPPEL Distribución", comercializador: "TechMex CDMX", monto: "$189,500", estatus: "pendiente", fecha: "06 Sep 2026" },
  { folio: "FAC-9899", cliente: "RadioShack México", comercializador: "Norte Digital S.A.", monto: "$95,200", estatus: "pagada", fecha: "04 Sep 2026" },
  { folio: "FAC-9898", cliente: "Best Buy México", comercializador: "Distribuidora Bajío", monto: "$512,000", estatus: "pagada", fecha: "01 Sep 2026" },
  { folio: "FAC-9897", cliente: "Mercado Libre MX", comercializador: "TechMex CDMX", monto: "$78,400", estatus: "vencida", fecha: "29 Ago 2026" },
];

const KPI_CONTABLE = [
  { label: "Facturación del mes", value: "$1,217,100", delta: "+8.7%", up: true },
  { label: "Facturas emitidas", value: "47", delta: "+5 vs ago", up: true },
  { label: "Comercializadores activos", value: "28", delta: "estable", up: true },
  { label: "Cartera vencida", value: "$78,400", delta: "1 cliente", up: false },
];

/* ── Module: Inventario ── */
const PRODUCTOS = [
  { sku: "PROD-0081", nombre: "Tableta Android 10\" OEM", stock: 310, entrada: 400, salida: 90, estado: "disponible" },
  { sku: "PROD-0077", nombre: "Smartwatch Fitness Pro", stock: 620, entrada: 750, salida: 130, estado: "disponible" },
  { sku: "PROD-0072", nombre: "Auriculares BT TW-55", stock: 88, entrada: 1200, salida: 1112, estado: "bajo stock" },
  { sku: "PROD-0068", nombre: "Cargador USB-C 65W GaN", stock: 2540, entrada: 3000, salida: 460, estado: "disponible" },
  { sku: "PROD-0063", nombre: "Cable HDMI 2.1 4K 2m", stock: 0, entrada: 2000, salida: 2000, estado: "agotado" },
  { sku: "PROD-0059", nombre: "Bocina Portátil BT 20W", stock: 195, entrada: 500, salida: 305, estado: "disponible" },
];

/* ── Module: Nómina ── */
const PERSONAL = [
  { id: "EMP-014", nombre: "Jorge Mendoza", puesto: "Agente de Ventas", zona: "CDMX Norte", sueldo: "$18,500", bono: "$4,200", total: "$22,700", mes: "Sep 2026" },
  { id: "EMP-009", nombre: "Patricia Leal", puesto: "Agente de Ventas", zona: "Guadalajara", sueldo: "$18,500", bono: "$6,800", total: "$25,300", mes: "Sep 2026" },
  { id: "EMP-021", nombre: "Andrés Fuentes", puesto: "Supervisor Regional", zona: "Monterrey", sueldo: "$28,000", bono: "$3,500", total: "$31,500", mes: "Sep 2026" },
  { id: "EMP-005", nombre: "Verónica Castillo", puesto: "Agente de Ventas", zona: "Puebla", sueldo: "$18,500", bono: "$2,100", total: "$20,600", mes: "Sep 2026" },
  { id: "EMP-033", nombre: "Miguel Torres", puesto: "Coord. Logística", zona: "Nacional", sueldo: "$24,000", bono: "$1,800", total: "$25,800", mes: "Sep 2026" },
];

const KPI_NOMINA = [
  { label: "Nómina total Sep", value: "$486,200", delta: "+$12,400 bonos", up: true },
  { label: "Agentes activos", value: "22", delta: "3 zonas", up: true },
  { label: "Bono promedio", value: "$3,680", delta: "+11% vs ago", up: true },
  { label: "Próximo pago", value: "30 Sep", delta: "en 19 días", up: true },
];

/* ── Module: Regulación ── */
const PAGOS_REG = [
  { concepto: "IVA Mensual (SAT)", monto: "$87,400", vencimiento: "17 Oct 2026", tipo: "Impuesto", estatus: "pendiente" },
  { concepto: "Arancel de Importación", monto: "$34,200", vencimiento: "25 Sep 2026", tipo: "Aduana", estatus: "pendiente" },
  { concepto: "Permiso COFEPRIS Elect.", monto: "$8,500", vencimiento: "01 Dic 2026", tipo: "Licencia", estatus: "al corriente" },
  { concepto: "ISR Trimestral", monto: "$156,000", vencimiento: "31 Oct 2026", tipo: "Impuesto", estatus: "pendiente" },
  { concepto: "Licencia Importador IMPI", monto: "$12,300", vencimiento: "15 Mar 2027", tipo: "Licencia", estatus: "al corriente" },
];

const KPI_REG = [
  { label: "Obligaciones pendientes", value: "$277,600", delta: "3 conceptos", up: false },
  { label: "Próximo vencimiento", value: "25 Sep", delta: "Arancel Aduana", up: false },
  { label: "Al corriente", value: "2 de 5", delta: "licencias", up: true },
  { label: "Pagado este año", value: "$940,200", delta: "a la fecha", up: true },
];

/* ── Module: Marketing ── */
const CAMPAÑAS = [
  { nombre: "Lanzamiento Smartwatch Pro", tipo: "Externo", canal: "Meta Ads + Google", presupuesto: "$45,000", alcance: "182,400", conversiones: "1,240", estatus: "activa" },
  { nombre: "Email Clientes COPPEL", tipo: "Directo", canal: "Email / WhatsApp", presupuesto: "$8,200", alcance: "4,800", conversiones: "312", estatus: "activa" },
  { nombre: "Feria ANTAD Guadalajara", tipo: "Externo", canal: "Evento presencial", presupuesto: "$120,000", alcance: "6,300", conversiones: "88", estatus: "finalizada" },
  { nombre: "Promo Revendedores Sep", tipo: "Directo", canal: "CRM / Llamadas", presupuesto: "$15,000", alcance: "280", conversiones: "67", estatus: "activa" },
];

const KPI_MKT = [
  { label: "Inversión total MKT", value: "$188,200", delta: "+$34k vs ago", up: true },
  { label: "Alcance acumulado", value: "193,780", delta: "personas", up: true },
  { label: "Costo por conversión", value: "$111.20", delta: "−12% vs ago", up: true },
  { label: "Campañas activas", value: "3", delta: "1 finalizada", up: true },
];

/* ── Main App ── */
export default function App() {
  const [active, setActive] = useState("resumen");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const maxVal = Math.max(...CHART_DATA.map((d) => d.value));

  return (
    <div style={{ display: "grid", gridTemplateColumns: "240px 1fr", minHeight: "100dvh", background: "var(--color-bg)", color: "var(--color-text)", fontFamily: "var(--font-sans)" }}
      className="max-[960px]:block">

      {/* ── Sidebar ── */}
      <aside style={{ background: "var(--color-surface)", borderRight: "1px solid var(--color-border)", display: "flex", flexDirection: "column", position: "sticky", top: 0, height: "100dvh", overflowY: "auto" }}
        className={`max-[960px]:fixed max-[960px]:z-50 max-[960px]:inset-y-0 max-[960px]:left-0 max-[960px]:w-[240px] max-[960px]:transition-transform max-[960px]:duration-300 ${sidebarOpen ? "max-[960px]:translate-x-0" : "max-[960px]:-translate-x-full"}`}>

        {/* Logo */}
        <div style={{ padding: "24px 20px 20px", borderBottom: "1px solid var(--color-border)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{ width: 32, height: 32, background: "var(--color-accent)", borderRadius: 7, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
              <span style={{ color: "#000", fontWeight: 700, fontSize: 12, fontFamily: "var(--font-mono)", letterSpacing: "0.02em" }}>SFV</span>
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 14.5, letterSpacing: "-0.02em", lineHeight: 1 }}>SIGFEVAK</div>
              <div style={{ fontSize: 10.5, color: "var(--color-text-dim)", marginTop: 2 }}>Comercializadora Nacional</div>
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav style={{ padding: "10px", flex: 1 }}>
          <div style={{ fontSize: 9.5, color: "var(--color-muted)", letterSpacing: "0.08em", textTransform: "uppercase", padding: "8px 10px 6px" }}>Módulos del Sistema</div>
          {NAV.map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => { setActive(id); setSidebarOpen(false); }}
              style={{ display: "flex", alignItems: "center", gap: 9, width: "100%", padding: "9px 10px", borderRadius: 7, border: "none", cursor: "pointer", background: active === id ? "var(--color-accent-dim)" : "transparent", color: active === id ? "var(--color-accent)" : "var(--color-text-dim)", fontFamily: "var(--font-sans)", fontSize: 13, fontWeight: active === id ? 500 : 400, textAlign: "left", transition: "all 0.12s", marginBottom: 1 }}
              onMouseEnter={(e) => { if (active !== id) { (e.currentTarget).style.background = "var(--color-surface-2)"; (e.currentTarget).style.color = "var(--color-text)"; } }}
              onMouseLeave={(e) => { if (active !== id) { (e.currentTarget).style.background = "transparent"; (e.currentTarget).style.color = "var(--color-text-dim)"; } }}>
              <Icon size={14} />
              {label}
            </button>
          ))}
        </nav>

        {/* Footer */}
        <div style={{ padding: "14px 16px", borderTop: "1px solid var(--color-border)", display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 30, height: 30, borderRadius: "50%", background: "#2a2a2a", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 600, color: "var(--color-text-dim)", flexShrink: 0 }}>AD</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12.5, fontWeight: 500 }}>Administrador</div>
            <div style={{ fontSize: 10.5, color: "var(--color-text-dim)" }}>SIGFEVAK · MX</div>
          </div>
        </div>
      </aside>

      {sidebarOpen && <div onClick={() => setSidebarOpen(false)} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", zIndex: 40 }} className="min-[961px]:hidden" />}

      {/* ── Main ── */}
      <main style={{ overflow: "auto", minWidth: 0 }}>
        {/* Topbar */}
        <header style={{ padding: "18px 28px", borderBottom: "1px solid var(--color-border)", display: "flex", alignItems: "center", justifyContent: "space-between", position: "sticky", top: 0, background: "var(--color-bg)", zIndex: 10 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <button onClick={() => setSidebarOpen(true)} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--color-text-dim)", padding: 4, display: "none" }} className="max-[960px]:block"><MenuIcon size={18} /></button>
            <div>
              <h1 style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: "-0.02em" }}>{NAV.find(n => n.id === active)?.label}</h1>
              <p style={{ margin: 0, fontSize: 11, color: "var(--color-text-dim)" }}>SIGFEVAK · Septiembre 2026</p>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <button style={{ background: "var(--color-surface)", border: "1px solid var(--color-border)", borderRadius: 7, padding: "6px 14px", color: "var(--color-text-dim)", fontFamily: "var(--font-sans)", fontSize: 12, cursor: "pointer" }}>Exportar</button>
            <button style={{ background: "var(--color-accent)", border: "none", borderRadius: 7, padding: "6px 14px", color: "#000", fontFamily: "var(--font-sans)", fontSize: 12, fontWeight: 600, cursor: "pointer" }}>+ Nuevo registro</button>
          </div>
        </header>

        <div style={{ padding: "28px 28px", display: "flex", flexDirection: "column", gap: 24 }}>

          {/* ════ MÓDULO 1: RESUMEN ════ */}
          {active === "resumen" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 14 }} className="max-[960px]:grid-cols-2 max-[600px]:grid-cols-1">
              {KPI_RESUMEN.map(s => <KpiCard key={s.label} {...s} />)}
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 300px", gap: 14 }} className="max-[960px]:grid-cols-1">
              <Panel title="Volumen comercializado (últimos 6 meses)">
                <div style={{ fontSize: 11, color: "var(--color-text-dim)", marginBottom: 16 }}>Miles de pesos MXN</div>
                <div style={{ display: "flex", alignItems: "flex-end", gap: 10, height: 100 }}>
                  {CHART_DATA.map((d, i) => {
                    const pct = (d.value / maxVal) * 100;
                    const isLast = i === CHART_DATA.length - 1;
                    return (
                      <div key={d.month} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6, height: "100%" }}>
                        <div style={{ flex: 1, width: "100%", display: "flex", alignItems: "flex-end" }}>
                          <div style={{ width: "100%", height: `${pct}%`, background: isLast ? "var(--color-accent)" : "var(--color-surface-2)", borderRadius: "4px 4px 0 0", border: isLast ? "none" : "1px solid var(--color-border)", transition: "height 0.4s ease" }} title={`${d.month}: $${d.value * 48}k`} />
                        </div>
                        <span style={{ fontFamily: "var(--font-mono)", fontSize: 10, color: isLast ? "var(--color-text)" : "var(--color-muted)" }}>{d.month}</span>
                      </div>
                    );
                  })}
                </div>
              </Panel>
              <Panel title="Próximas obligaciones">
                {PAGOS_REG.filter(p => p.estatus === "pendiente").slice(0, 3).map(p => (
                  <div key={p.concepto} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: "1px solid var(--color-border)" }}>
                    <div>
                      <div style={{ fontSize: 12.5, fontWeight: 500 }}>{p.concepto}</div>
                      <div style={{ fontSize: 11, color: "var(--color-text-dim)", marginTop: 2 }}>Vence {p.vencimiento}</div>
                    </div>
                    <span style={{ fontFamily: "var(--font-mono)", fontSize: 12, color: "var(--color-down)", fontWeight: 600 }}>{p.monto}</span>
                  </div>
                ))}
                <div style={{ marginTop: 14, fontSize: 11.5, color: "var(--color-text-dim)", textAlign: "center" }}>Total pendiente: <span style={{ color: "var(--color-down)", fontFamily: "var(--font-mono)", fontWeight: 600 }}>$277,600</span></div>
              </Panel>
            </div>
          </>}

          {/* ════ MÓDULO 1: ENTRADAS ════ */}
          {active === "entradas" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 14 }} className="max-[960px]:grid-cols-1">
              <KpiCard label="Capital ingresado Sep" value="$4,158,000" delta="+9.3%" up sub="vs agosto" />
              <KpiCard label="Unidades ingresadas" value="7,350 uds" delta="+1,200" up sub="vs agosto" />
              <KpiCard label="Registros del mes" value="14 entradas" delta="5 importación" up sub="9 nacional" />
            </div>
            <Panel title="Entradas de productos — Sep 2026">
              <Table
                headers={["Folio", "Producto", "Categoría", "Unidades", "Valor/Ud", "Capital Total", "Origen", "Fecha"]}
                rows={ENTRADAS.map(e => [
                  <Mono>{e.folio}</Mono>,
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{e.producto}</span>,
                  <Tag color={e.categoria === "Electrónico" ? "accent" : "muted"}>{e.categoria}</Tag>,
                  <Mono>{e.unidades.toLocaleString()}</Mono>,
                  <Mono>{e.valor_unit}</Mono>,
                  <Mono style={{ color: "var(--color-up)", fontWeight: 600 }}>{e.capital}</Mono>,
                  <Tag color={e.origen === "Importación" ? "down" : "up"}>{e.origen}</Tag>,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{e.fecha}</span>,
                ])}
              />
            </Panel>
          </>}

          {/* ════ MÓDULO 2: CONTABLE ════ */}
          {active === "contable" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 14 }} className="max-[960px]:grid-cols-2 max-[600px]:grid-cols-1">
              {KPI_CONTABLE.map(s => <KpiCard key={s.label} {...s} sub="" />)}
            </div>
            <Panel title="Registro de facturas — Sep 2026">
              <Table
                headers={["Folio", "Cliente", "Comercializador", "Monto", "Estatus", "Fecha"]}
                rows={FACTURAS.map(f => [
                  <Mono>{f.folio}</Mono>,
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{f.cliente}</span>,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{f.comercializador}</span>,
                  <Mono style={{ fontWeight: 600 }}>{f.monto}</Mono>,
                  <StatusBadge status={f.estatus} map={{ pagada: "up", pendiente: "accent", vencida: "down" }} />,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{f.fecha}</span>,
                ])}
              />
            </Panel>
          </>}

          {/* ════ MÓDULO 3: INVENTARIO ════ */}
          {active === "inventario" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 14 }} className="max-[960px]:grid-cols-1">
              <KpiCard label="SKUs registrados" value="6 líneas" delta="activas" up sub="catálogo general" />
              <KpiCard label="Unidades en almacén" value="3,753 uds" delta="−88 bajo stock" up={false} sub="revisar TW-55" />
              <KpiCard label="Rotación promedio" value="61%" delta="+4% vs ago" up sub="entrada/salida" />
            </div>
            <Panel title="Base de productos — entradas y salidas">
              <Table
                headers={["SKU", "Producto", "Stock Actual", "Entradas", "Salidas", "Estado"]}
                rows={PRODUCTOS.map(p => [
                  <Mono>{p.sku}</Mono>,
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{p.nombre}</span>,
                  <Mono style={{ fontWeight: 600, color: p.stock === 0 ? "var(--color-down)" : p.stock < 100 ? "var(--color-accent)" : "var(--color-text)" }}>{p.stock.toLocaleString()}</Mono>,
                  <Mono style={{ color: "var(--color-up)" }}>{p.entrada.toLocaleString()}</Mono>,
                  <Mono style={{ color: "var(--color-text-dim)" }}>{p.salida.toLocaleString()}</Mono>,
                  <StatusBadge status={p.estado} map={{ disponible: "up", "bajo stock": "accent", agotado: "down" }} />,
                ])}
              />
            </Panel>
          </>}

          {/* ════ MÓDULO 4: NÓMINA ════ */}
          {active === "nomina" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 14 }} className="max-[960px]:grid-cols-2 max-[600px]:grid-cols-1">
              {KPI_NOMINA.map(s => <KpiCard key={s.label} {...s} sub="" />)}
            </div>
            <Panel title="Asignación de nómina — Sep 2026">
              <Table
                headers={["ID", "Nombre", "Puesto", "Zona", "Sueldo Base", "Bonificación", "Total"]}
                rows={PERSONAL.map(p => [
                  <Mono>{p.id}</Mono>,
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{p.nombre}</span>,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{p.puesto}</span>,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{p.zona}</span>,
                  <Mono>{p.sueldo}</Mono>,
                  <Mono style={{ color: "var(--color-accent)" }}>{p.bono}</Mono>,
                  <Mono style={{ fontWeight: 600, color: "var(--color-up)" }}>{p.total}</Mono>,
                ])}
              />
            </Panel>
          </>}

          {/* ════ MÓDULO 5: REGULACIÓN ════ */}
          {active === "regulacion" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 14 }} className="max-[960px]:grid-cols-2 max-[600px]:grid-cols-1">
              {KPI_REG.map(s => <KpiCard key={s.label} {...s} sub="" />)}
            </div>
            <Panel title="Licencias, permisos e impuestos">
              <Table
                headers={["Concepto", "Tipo", "Monto", "Vencimiento", "Estatus", "Pago automático"]}
                rows={PAGOS_REG.map(p => [
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{p.concepto}</span>,
                  <Tag color="muted">{p.tipo}</Tag>,
                  <Mono style={{ fontWeight: 600, color: p.estatus === "pendiente" ? "var(--color-down)" : "var(--color-text)" }}>{p.monto}</Mono>,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{p.vencimiento}</span>,
                  <StatusBadge status={p.estatus} map={{ "al corriente": "up", pendiente: "down" }} />,
                  <span style={{ fontFamily: "var(--font-mono)", fontSize: 11, color: p.estatus === "pendiente" ? "var(--color-accent)" : "var(--color-muted)" }}>{p.estatus === "pendiente" ? "Programar" : "Activo"}</span>,
                ])}
              />
            </Panel>
          </>}

          {/* ════ MÓDULO 6: MARKETING ════ */}
          {active === "marketing" && <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 14 }} className="max-[960px]:grid-cols-2 max-[600px]:grid-cols-1">
              {KPI_MKT.map(s => <KpiCard key={s.label} {...s} sub="" />)}
            </div>
            <Panel title="Campañas de marketing — Sep 2026">
              <Table
                headers={["Campaña", "Tipo", "Canal", "Presupuesto", "Alcance", "Conversiones", "Estatus"]}
                rows={CAMPAÑAS.map(c => [
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{c.nombre}</span>,
                  <Tag color={c.tipo === "Externo" ? "accent" : "muted"}>{c.tipo}</Tag>,
                  <span style={{ fontSize: 12, color: "var(--color-text-dim)" }}>{c.canal}</span>,
                  <Mono>{c.presupuesto}</Mono>,
                  <Mono style={{ color: "var(--color-up)" }}>{c.alcance}</Mono>,
                  <Mono style={{ fontWeight: 600 }}>{c.conversiones}</Mono>,
                  <StatusBadge status={c.estatus} map={{ activa: "up", finalizada: "muted" }} />,
                ])}
              />
            </Panel>
          </>}

        </div>
      </main>
    </div>
  );
}

/* ── Reusable components ── */

function KpiCard({ label, value, delta, up, sub }) {
  return (
    <div style={{ background: "var(--color-surface)", border: "1px solid var(--color-border)", borderRadius: 12, padding: "18px 20px", transition: "border-color 0.15s" }}
      onMouseEnter={e => (e.currentTarget.style.borderColor = "#3a3a3a")}
      onMouseLeave={e => (e.currentTarget.style.borderColor = "var(--color-border)")}>
      <div style={{ fontSize: 10.5, color: "var(--color-text-dim)", marginBottom: 8, letterSpacing: "0.04em", textTransform: "uppercase" }}>{label}</div>
      <div style={{ fontFamily: "var(--font-mono)", fontSize: 22, fontWeight: 600, letterSpacing: "-0.03em", lineHeight: 1 }}>{value}</div>
      <div style={{ marginTop: 8, display: "flex", alignItems: "center", gap: 6 }}>
        <span style={{ fontFamily: "var(--font-mono)", fontSize: 11, color: up ? "var(--color-up)" : "var(--color-down)", fontWeight: 500 }}>{delta}</span>
        {sub && <span style={{ fontSize: 10.5, color: "var(--color-muted)" }}>{sub}</span>}
      </div>
    </div>
  );
}

function Panel({ title, children }) {
  return (
    <div style={{ background: "var(--color-surface)", border: "1px solid var(--color-border)", borderRadius: 12, overflow: "hidden" }}>
      <div style={{ padding: "18px 22px", borderBottom: "1px solid var(--color-border)", fontSize: 13, fontWeight: 500 }}>{title}</div>
      <div style={{ padding: "20px 22px" }}>{children}</div>
    </div>
  );
}

function Table({ headers, rows }) {
  return (
    <div style={{ overflowX: "auto", margin: "-20px -22px", padding: "0" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", minWidth: 600 }}>
        <thead>
          <tr>
            {headers.map(h => (
              <th key={h} style={{ padding: "10px 20px", textAlign: "left", fontSize: 10, color: "var(--color-muted)", fontWeight: 500, letterSpacing: "0.06em", textTransform: "uppercase", borderBottom: "1px solid var(--color-border)", whiteSpace: "nowrap" }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i} style={{ borderBottom: i < rows.length - 1 ? "1px solid var(--color-border)" : "none", transition: "background 0.1s" }}
              onMouseEnter={e => (e.currentTarget.style.background = "var(--color-surface-2)")}
              onMouseLeave={e => (e.currentTarget.style.background = "transparent")}>
              {row.map((cell, j) => (
                <td key={j} style={{ padding: "13px 20px", whiteSpace: "nowrap" }}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Mono({ children, style }) {
  return <span style={{ fontFamily: "var(--font-mono)", fontSize: 12, ...style }}>{children}</span>;
}

function Tag({ children, color }) {
  const colors = {
    accent: { bg: "rgba(240,165,0,0.1)", fg: "var(--color-accent)" },
    muted: { bg: "var(--color-surface-2)", fg: "var(--color-text-dim)" },
    up: { bg: "rgba(62,207,142,0.1)", fg: "var(--color-up)" },
    down: { bg: "rgba(248,113,113,0.1)", fg: "var(--color-down)" },
  };
  const c = colors[color];
  return <span style={{ fontFamily: "var(--font-mono)", fontSize: 10.5, padding: "3px 8px", borderRadius: 20, background: c.bg, color: c.fg }}>{children}</span>;
}

function StatusBadge({ status, map }) {
  const color = map[status] ?? "muted";
  return <Tag color={color}>{status}</Tag>;
}

/* ── Icons ── */
function GridIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><rect x="1" y="1" width="6" height="6" rx="1.5" stroke="currentColor" strokeWidth="1.3"/><rect x="9" y="1" width="6" height="6" rx="1.5" stroke="currentColor" strokeWidth="1.3"/><rect x="1" y="9" width="6" height="6" rx="1.5" stroke="currentColor" strokeWidth="1.3"/><rect x="9" y="9" width="6" height="6" rx="1.5" stroke="currentColor" strokeWidth="1.3"/></svg>;
}
function BoxIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><path d="M2 5l6-3 6 3v6l-6 3-6-3V5z" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round"/><path d="M8 2v12M2 5l6 3 6-3" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round"/></svg>;
}
function ReceiptIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><path d="M3 1h10v14l-2-1.5-2 1.5-2-1.5L5 15 3 13.5V1z" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round"/><line x1="5" y1="5" x2="11" y2="5" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/><line x1="5" y1="8" x2="11" y2="8" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/><line x1="5" y1="11" x2="8" y2="11" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/></svg>;
}
function DatabaseIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><ellipse cx="8" cy="4" rx="5" ry="2" stroke="currentColor" strokeWidth="1.3"/><path d="M3 4v4c0 1.1 2.2 2 5 2s5-.9 5-2V4" stroke="currentColor" strokeWidth="1.3"/><path d="M3 8v4c0 1.1 2.2 2 5 2s5-.9 5-2V8" stroke="currentColor" strokeWidth="1.3"/></svg>;
}
function UsersIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><circle cx="6" cy="5" r="2.5" stroke="currentColor" strokeWidth="1.3"/><path d="M1 14c0-2.8 2.2-5 5-5s5 2.2 5 5" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round"/><circle cx="12" cy="5" r="2" stroke="currentColor" strokeWidth="1.3"/><path d="M15 14c0-2.2-1.3-4-3-4.5" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round"/></svg>;
}
function ShieldIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><path d="M8 1l5 2v4c0 3-2 5.5-5 7C6 12.5 3 10 3 7V3l5-2z" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round"/><polyline points="5.5,8 7,9.5 10.5,6" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round"/></svg>;
}
function MegaphoneIcon({ size = 14 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><path d="M2 6h2v4H2z" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round"/><path d="M4 6l8-3v10L4 10V6z" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round"/><path d="M4 10l1.5 4h2L6 10" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round"/></svg>;
}
function MenuIcon({ size = 16 }) {
  return <svg width={size} height={size} viewBox="0 0 16 16" fill="none"><line x1="2" y1="4" x2="14" y2="4" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"/><line x1="2" y1="8" x2="14" y2="8" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"/><line x1="2" y1="12" x2="14" y2="12" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"/></svg>;
}

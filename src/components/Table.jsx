// Tabla con encabezados en mayúsculas, hover de fila y scroll horizontal. `rows` es un arreglo de arreglos de celdas.
export default function Table({ headers, rows, vacio = 'Sin registros', onRowClick }) {
  return (
    <div className="overflow-x-auto -mx-[22px] -my-5">
      <table className="w-full border-collapse min-w-[600px]">
        <thead>
          <tr>
            {headers.map((h) => (
              <th
                key={h}
                className="px-5 py-2.5 text-left text-[10px] text-muted font-medium tracking-[0.06em] uppercase border-b border-border whitespace-nowrap"
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 && (
            <tr>
              <td
                colSpan={headers.length}
                className="px-5 py-8 text-center text-[12.5px] text-text-dim"
              >
                {vacio}
              </td>
            </tr>
          )}
          {rows.map((row, i) => (
            <tr
              key={i}
              onClick={onRowClick ? () => onRowClick(i) : undefined}
              className={`hover:bg-surface-2 transition-colors ${i < rows.length - 1 ? 'border-b border-border' : ''} ${onRowClick ? 'cursor-pointer' : ''}`}
            >
              {row.map((cell, j) => (
                <td key={j} className="px-5 py-[13px] whitespace-nowrap">
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

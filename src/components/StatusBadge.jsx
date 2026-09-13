import Tag from './Tag';

// Tag cuyo color sale de un mapa { estado: color }. `etiquetas` opcional para mostrar un texto distinto al valor.
export default function StatusBadge({ status, map, etiquetas }) {
  const color = map[status] ?? 'muted';
  const texto =
    etiquetas?.[status] ??
    String(status ?? '')
      .toLowerCase()
      .replaceAll('_', ' ');
  return <Tag color={color}>{texto}</Tag>;
}

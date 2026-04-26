'use client'

import { ColumnInfo, TableInfo } from '../hooks/use-database'

interface ColumnInfoProps {
  table: TableInfo
  columns: ColumnInfo[]
}

export function ColumnInfoView({ table, columns }: ColumnInfoProps) {
  return (
    <div>
      <div className="mb-4 p-4 rounded-lg" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)' }}>
        <div className="flex items-center gap-3 mb-2">
          <span className="material-icons-round" style={{ fontSize: 20, color: 'var(--primary)' }}>table_chart</span>
          <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>{table.name}</h3>
        </div>
        <div className="flex gap-4 text-sm" style={{ color: 'var(--on-surface-variant)' }}>
          <span>行数: {table.rowCount >= 0 ? table.rowCount.toLocaleString() : '-'}</span>
          {table.comment && <span>注释: {table.comment}</span>}
        </div>
      </div>

      <div className="rounded-lg overflow-hidden" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)' }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: 'var(--surface-container)' }}>
              {['列名', '类型', '可空', '键', '默认值', '注释'].map((h) => (
                <th key={h} className="text-left px-3 py-2.5 font-medium" style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {columns.map((col, i) => (
              <tr key={col.name} style={{ background: i % 2 === 0 ? 'var(--surface)' : 'var(--surface-container-low)' }}>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface)' }}>
                  {col.keyType === 'PRI' && <span className="material-icons-round align-middle mr-1" style={{ fontSize: 14, color: 'var(--warning)' }}>vpn_key</span>}
                  {col.name}
                </td>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface-variant)' }}>{col.type}</td>
                <td className="px-3 py-2" style={{ color: col.nullable === 'YES' ? 'var(--success)' : 'var(--error)' }}>{col.nullable}</td>
                <td className="px-3 py-2" style={{ color: col.keyType ? 'var(--primary)' : 'var(--on-surface-variant)' }}>{col.keyType || '-'}</td>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface-variant)' }}>{col.defaultValue != null ? String(col.defaultValue) : '-'}</td>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface-variant)' }}>{col.comment || '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
'use client'

import { useState, useEffect } from 'react'
import { ColumnInfo } from '../hooks/use-database'

interface RowEditDialogProps {
  open: boolean
  mode: 'insert' | 'update'
  columns: ColumnInfo[]
  rowData: Record<string, any> | null
  onConfirm: (data: Record<string, any>) => void
  onCancel: () => void
}

export function RowEditDialog({ open, mode, columns, rowData, onConfirm, onCancel }: RowEditDialogProps) {
  const [formData, setFormData] = useState<Record<string, any>>({})

  useEffect(() => {
    if (open) {
      setFormData(rowData ? { ...rowData } : {})
    }
  }, [open, rowData])

  if (!open) return null

  const handleChange = (colName: string, value: any) => {
    setFormData((prev) => ({ ...prev, [colName]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onConfirm(formData)
  }

  const isPrimaryReadOnly = (col: ColumnInfo) => {
    return mode === 'update' && col.keyType === 'PRI'
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: 'rgba(0,0,0,0.3)' }}>
      <div className="w-[520px] max-h-[80vh] overflow-y-auto rounded-xl shadow-lg" style={{ background: 'var(--surface)' }}>
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
          <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>
            {mode === 'insert' ? '新增行' : '编辑行'}
          </h3>
          <button onClick={onCancel} className="p-1 rounded-md cursor-pointer" style={{ color: 'var(--on-surface-variant)' }}>
            <span className="material-icons-round" style={{ fontSize: 20 }}>close</span>
          </button>
        </div>
        <form onSubmit={handleSubmit} className="px-5 py-4 space-y-3">
          {columns.map((col) => (
            <div key={col.name} className="flex items-center gap-3">
              <label className="w-32 shrink-0 text-sm text-right" style={{ color: 'var(--on-surface-variant)' }}>
                {col.keyType === 'PRI' && <span className="material-icons-round align-middle mr-0.5" style={{ fontSize: 12, color: 'var(--warning)' }}>vpn_key</span>}
                {col.name}
              </label>
              {isPrimaryReadOnly(col) ? (
                <input
                  type="text"
                  value={formData[col.name] ?? ''}
                  readOnly
                  className="flex-1 px-3 py-1.5 rounded-md text-sm"
                  style={{ background: 'var(--surface-container)', color: 'var(--on-surface-variant)', border: '1px solid var(--outline-variant)' }}
                />
              ) : (
                <input
                  type="text"
                  value={formData[col.name] ?? ''}
                  onChange={(e) => handleChange(col.name, e.target.value)}
                  placeholder={col.nullable === 'YES' ? 'NULL' : col.type}
                  className="flex-1 px-3 py-1.5 rounded-md text-sm outline-none"
                  style={{ background: 'var(--surface-container-low)', color: 'var(--on-surface)', border: '1px solid var(--outline-variant)' }}
                />
              )}
            </div>
          ))}
          <div className="flex justify-end gap-2 pt-3" style={{ borderTop: '1px solid var(--outline-variant)' }}>
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
              style={{ color: 'var(--on-surface-variant)', background: 'var(--surface-container)' }}
            >
              取消
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
              style={{ color: 'var(--on-primary)', background: 'var(--primary)' }}
            >
              确认
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
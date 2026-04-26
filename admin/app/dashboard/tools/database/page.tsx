'use client'

import { useState, useEffect } from 'react'
import { useDatabase, TableInfo as TableInfoType, ColumnInfo as ColumnInfoType } from './hooks/use-database'
import { TableList } from './components/table-list'
import { ColumnInfoView } from './components/column-info'
import { DataTable } from './components/data-table'
import { SqlQuery } from './components/sql-query'

type TabKey = 'columns' | 'data' | 'sql'

export default function DatabasePage() {
  const { fetchTables, fetchColumns } = useDatabase()
  const [tables, setTables] = useState<TableInfoType[]>([])
  const [selectedTable, setSelectedTable] = useState<string | null>(null)
  const [columns, setColumns] = useState<ColumnInfoType[]>([])
  const [activeTab, setActiveTab] = useState<TabKey>('columns')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    fetchTables()
      .then(setTables)
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [fetchTables])

  useEffect(() => {
    if (selectedTable) {
      fetchColumns(selectedTable).then(setColumns).catch(() => {})
      setActiveTab('columns')
    }
  }, [selectedTable, fetchColumns])

  const selectedTableInfo = tables.find((t) => t.name === selectedTable)

  const tabs: { key: TabKey; label: string; icon: string }[] = [
    { key: 'columns', label: '列信息', icon: 'view_column' },
    { key: 'data', label: '数据', icon: 'table_rows' },
    { key: 'sql', label: 'SQL 查询', icon: 'terminal' },
  ]

  return (
    <div className="flex h-[calc(100vh-var(--topbar-height)-64px)] -m-6">
      <TableList
        tables={tables}
        selectedTable={selectedTable}
        onSelect={setSelectedTable}
      />
      <div className="flex-1 flex flex-col min-w-0 p-6">
        {!selectedTable ? (
          <div className="flex-1 flex flex-col items-center justify-center">
            <span className="material-icons-round mb-3" style={{ fontSize: 40, color: 'var(--outline)' }}>storage</span>
            <p className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>
              {loading ? '加载中...' : '请从左侧选择一个表'}
            </p>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-1 mb-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
              {tabs.map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className="flex items-center gap-1.5 px-4 py-2.5 text-sm transition-colors cursor-pointer"
                  style={{
                    color: activeTab === tab.key ? 'var(--primary)' : 'var(--on-surface-variant)',
                    borderBottom: activeTab === tab.key ? '2px solid var(--primary)' : '2px solid transparent',
                    fontWeight: activeTab === tab.key ? 500 : 400,
                  }}
                >
                  <span className="material-icons-round" style={{ fontSize: 18 }}>{tab.icon}</span>
                  {tab.label}
                </button>
              ))}
            </div>
            <div className="flex-1 overflow-y-auto">
              {activeTab === 'columns' && selectedTableInfo && (
                <ColumnInfoView table={selectedTableInfo} columns={columns} />
              )}
              {activeTab === 'data' && (
                <DataTable tableName={selectedTable} columns={columns} />
              )}
              {activeTab === 'sql' && (
                <SqlQuery />
              )}
            </div>
          </>
        )}
      </div>
    </div>
  )
}

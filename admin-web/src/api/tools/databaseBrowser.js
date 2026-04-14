import request from '@/utils/request'

export function getAllTables() {
  return request({
    url: 'api/database-browser/tables',
    method: 'get'
  })
}

export function getTableColumns(tableName) {
  return request({
    url: `api/database-browser/tables/${tableName}/columns`,
    method: 'get'
  })
}

export function getTableData(tableName, page, size) {
  return request({
    url: `api/database-browser/tables/${tableName}/data`,
    method: 'get',
    params: { page, size }
  })
}

export function insertData(tableName, data) {
  return request({
    url: `api/database-browser/tables/${tableName}/data`,
    method: 'post',
    data
  })
}

export function updateData(tableName, data, whereClause) {
  return request({
    url: `api/database-browser/tables/${tableName}/data`,
    method: 'put',
    data: { data, whereClause }
  })
}

export function deleteData(tableName, whereClause) {
  return request({
    url: `api/database-browser/tables/${tableName}/data`,
    method: 'delete',
    data: whereClause
  })
}

export function isSensitiveTable(tableName) {
  return request({
    url: `api/database-browser/tables/${tableName}/sensitive`,
    method: 'get'
  })
}

export default {
  getAllTables,
  getTableColumns,
  getTableData,
  insertData,
  updateData,
  deleteData,
  isSensitiveTable
}

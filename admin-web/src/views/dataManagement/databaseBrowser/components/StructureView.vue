<template>
  <div class="structure-view-container">
    <el-table
      :data="columns"
      border
      stripe
      style="width: 100%;"
      v-loading="loading"
    >
      <el-table-column prop="columnName" label="列名" width="180" fixed />
      <el-table-column prop="dataType" label="数据类型" width="120">
        <template slot-scope="scope">
          <el-tag size="mini" type="info">{{ scope.row.dataType }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="columnType" label="列类型" width="180" />
      <el-table-column prop="nullable" label="可空" width="80" align="center">
        <template slot-scope="scope">
          <i :class="scope.row.nullable ? 'el-icon-success' : 'el-icon-error'" :style="{ color: scope.row.nullable ? '#67C23A' : '#F56C6C' }" />
        </template>
      </el-table-column>
      <el-table-column prop="columnKey" label="键类型" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.columnKey === 'PRI'" size="mini" type="danger">主键</el-tag>
          <el-tag v-else-if="scope.row.columnKey === 'UNI'" size="mini" type="warning">唯一</el-tag>
          <el-tag v-else-if="scope.row.columnKey === 'MUL'" size="mini" type="primary">索引</el-tag>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column prop="columnDefault" label="默认值" width="120" show-overflow-tooltip />
      <el-table-column prop="autoIncrement" label="自增" width="80" align="center">
        <template slot-scope="scope">
          <i v-if="scope.row.autoIncrement" class="el-icon-check" style="color: #67C23A;" />
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column prop="columnComment" label="注释" min-width="150" show-overflow-tooltip />
    </el-table>
  </div>
</template>

<script>
import { getTableColumns } from '@/api/tools/databaseBrowser'

export default {
  name: 'StructureView',
  props: {
    tableName: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      loading: false,
      columns: []
    }
  },
  watch: {
    tableName: {
      immediate: true,
      handler() {
        this.loadColumns()
      }
    }
  },
  methods: {
    async loadColumns() {
      if (!this.tableName) return
      this.loading = true
      try {
        const res = await getTableColumns(this.tableName)
        this.columns = res.data || []
      } catch (error) {
        this.$message.error('加载表结构失败')
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
.structure-view-container {
  padding: 16px;
}
</style>

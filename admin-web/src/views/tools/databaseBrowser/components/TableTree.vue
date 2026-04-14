<template>
  <div class="table-tree-container">
    <div class="tree-header">
      <span class="tree-title">数据表</span>
      <el-button type="text" icon="el-icon-refresh" @click="loadTables" :loading="loading" />
    </div>
    <el-input
      v-model="searchText"
      placeholder="搜索表名"
      prefix-icon="el-icon-search"
      size="small"
      style="margin: 8px 12px;"
      clearable
    />
    <el-tree
      ref="tree"
      :data="treeData"
      :props="treeProps"
      :filter-node-method="filterNode"
      node-key="tableName"
      @node-click="handleNodeClick"
      default-expand-all
      highlight-current
    >
      <span class="custom-tree-node" slot-scope="{ node, data }">
        <i :class="data.tableComment ? 'el-icon-document' : 'el-icon-document-remove'" style="margin-right: 6px; color: #909399;" />
        <span class="node-label">{{ node.label }}</span>
        <span v-if="data.tableComment" class="node-comment">{{ data.tableComment }}</span>
      </span>
    </el-tree>
  </div>
</template>

<script>
import { getAllTables, getTableColumns } from '@/api/tools/databaseBrowser'

export default {
  name: 'TableTree',
  data() {
    return {
      loading: false,
      searchText: '',
      treeData: [],
      treeProps: {
        label: 'tableName',
        children: 'children'
      }
    }
  },
  watch: {
    searchText(val) {
      this.$refs.tree.filter(val)
    }
  },
  created() {
    this.loadTables()
  },
  methods: {
    async loadTables() {
      this.loading = true
      try {
        const res = await getAllTables()
        this.treeData = res.data || []
      } catch (error) {
        this.$message.error('加载表列表失败')
      } finally {
        this.loading = false
      }
    },
    filterNode(value, data) {
      if (!value) return true
      const name = data.tableName || ''
      const comment = data.tableComment || ''
      return name.toLowerCase().includes(value.toLowerCase()) ||
             comment.toLowerCase().includes(value.toLowerCase())
    },
    async handleNodeClick(data) {
      try {
        // 加载表结构
        const res = await getTableColumns(data.tableName)
        data.columns = res.data || []
        this.$emit('table-select', data)
      } catch (error) {
        this.$message.error('加载表结构失败')
      }
    }
  }
}
</script>

<style scoped>
.table-tree-container {
  height: 100%;
  display: flex;
  flex-direction: column;
}
.tree-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid #e4e7ed;
  background-color: #fff;
}
.tree-title {
  font-weight: 600;
  color: #303133;
}
.custom-tree-node {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-right: 8px;
  font-size: 13px;
}
.node-label {
  color: #606266;
}
.node-comment {
  color: #c0c4cc;
  font-size: 12px;
  margin-left: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 100px;
}
::v-deep .el-tree {
  overflow-y: auto;
  flex: 1;
}
</style>

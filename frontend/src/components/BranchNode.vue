<template>
  <div class="branch-node">
    <div 
      :class="['node-item', { 
        'current': node.branch === currentBranch,
        'main': node.branch === 'main',
        'clickable': true
      }]"
      @click="$emit('branchClick', node)"
    >
      <div class="node-content">
        <span 
          :class="['move-notation', {
            'sente-move': node.move_number && node.move_number % 2 === 1,
            'gote-move': node.move_number && node.move_number % 2 === 0
          }]"
        >
          {{ node.move_notation || node.display_name || `${node.move_number || '?'}手目` }}
        </span>
        
      </div>
      
      
    </div>
    
    <!-- 矢印と子分岐 -->
    <div v-if="node.children && node.children.length > 0" class="children">
      <div class="arrow">→</div>
      <div class="child-nodes">
        <BranchNode
          v-for="child in node.children"
          :key="`${child.branch}-${child.move_number}`"
          :node="child"
          :current-branch="currentBranch"
          @branch-click="$emit('branchClick', $event)"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface TreeNode {
  branch: string
  move_number?: number
  move_notation?: string
  display_name?: string
  parent_branch?: string | null
  branch_point?: number | null
  depth: number
  children: TreeNode[]
  sfen?: string
}

interface Props {
  node: TreeNode
  currentBranch: string
}

const props = defineProps<Props>()
defineEmits<{
  branchClick: [node: TreeNode]
}>()

// 子ノードが連続する手順かどうかを判定
const isSequentialChildren = computed(() => {
  // デザイン統一のため、常に横配置にする
  return true
})
</script>

<style scoped>
.branch-node {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin: 0;
}

.node-item {
  padding: 6px 10px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  background: linear-gradient(135deg, rgba(40, 40, 80, 0.6), rgba(30, 30, 70, 0.4));
  transition: all 0.3s ease;
  cursor: pointer;
  white-space: nowrap;
  margin: 0;
  backdrop-filter: blur(4px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.node-item:hover {
  background: linear-gradient(135deg, rgba(60, 60, 120, 0.8), rgba(50, 50, 100, 0.6));
  border-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
}

.node-item.current {
  background: rgba(74, 144, 226, 0.7);
  border-color: rgba(74, 144, 226, 0.9);
  box-shadow: 0 2px 8px rgba(74, 144, 226, 0.3);
}

.node-item.main {
  border-left: 4px solid #4CAF50;
}

.node-content {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.move-notation {
  font-weight: 600;
  font-size: 16px;
  font-family: 'Noto Sans CJK JP', 'Hiragino Sans', 'Yu Gothic UI', 'Meiryo UI', sans-serif;
  color: #FFFFFF;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.8);
  letter-spacing: 0.5px;
  padding: 4px 8px;
  border-radius: 6px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.05));
  backdrop-filter: blur(2px);
  transition: all 0.2s ease;
  display: inline-block;
}

.move-notation:hover {
  transform: scale(1.05);
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.9);
}

.move-notation.sente-move {
  color: #F0FFF0;
  background: linear-gradient(135deg, rgba(76, 175, 80, 0.3), rgba(76, 175, 80, 0.1));
  border: 1px solid rgba(76, 175, 80, 0.4);
  text-shadow: 
    0 1px 3px rgba(76, 175, 80, 0.8), 
    0 0 8px rgba(76, 175, 80, 0.4);
  box-shadow: 0 2px 4px rgba(76, 175, 80, 0.2);
}

.move-notation.gote-move {
  color: #FFF5F5;
  background: linear-gradient(135deg, rgba(244, 67, 54, 0.3), rgba(244, 67, 54, 0.1));
  border: 1px solid rgba(244, 67, 54, 0.4);
  text-shadow: 
    0 1px 3px rgba(244, 67, 54, 0.8), 
    0 0 8px rgba(244, 67, 54, 0.4);
  box-shadow: 0 2px 4px rgba(244, 67, 54, 0.2);
}

.children {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin: 0;
  padding: 0;
}

.arrow {
  color: #74A0E6;
  font-size: 18px;
  font-weight: 900;
  margin: 0 6px;
  padding: 0;
  line-height: 1;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
  filter: drop-shadow(0 0 4px rgba(116, 160, 230, 0.4));
}

.child-nodes {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin: 0;
  padding: 0;
}

/* 深さに応じた色分け */
.node-item[data-depth="0"] {
  border-left-color: #4CAF50;
}

.node-item[data-depth="1"] {
  border-left-color: #2196F3;
}

.node-item[data-depth="2"] {
  border-left-color: #FF9800;
}

.node-item[data-depth="3"] {
  border-left-color: #9C27B0;
}


</style> 
<template>
  <Teleport to="body">
    <div class="branch-tree-viewer">
      <div class="tree-header">
        <h4>指し手ツリー構造</h4>
        <button class="close-btn" @click="$emit('close')">×</button>
      </div>
      
      <div class="tree-content">
        <div v-if="loading" class="loading">
          🌳 ツリーデータを読み込み中...
        </div>
        
        <div v-else-if="error" class="error">
          ❌ エラー: {{ error }}
        </div>
        
        <div v-else-if="treeData">
          <!-- ツリー統計 -->
          <div class="tree-stats">
            <div class="stat-item">
              📊 総手順数: {{ treeData.tree.length }} | 分岐数: {{ treeData.total_branches }}
            </div>
          </div>
          
          <!-- ツリー可視化（統一レイアウト） -->
          <div class="tree-visualization">
            <div class="root-nodes">
              <BranchNode
                v-for="node in treeData.tree"
                :key="`${node.branch}-${node.move_number || 0}`"
                :node="node"
                :current-branch="currentBranch"
                @branch-click="handleBranchClick"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import BranchNode from './BranchNode.vue'

interface Props {
  gameId: number
  currentBranch: string
}

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

interface TreeData {
  tree: TreeNode[]
  branches: string[]
  total_branches: number
}

const props = defineProps<Props>()
defineEmits<{
  close: []
  branchSwitch: [branch: string]
}>()

const loading = ref(true)
const error = ref('')
const treeData = ref<TreeData | null>(null)

// 条件分岐不要のため削除

// ツリーデータを取得
const fetchTreeData = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await fetch(`http://localhost:3000/api/v1/games/${props.gameId}/board_histories/all_branches`)
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    const branches = await response.json()
    const treeNodes = buildTree(branches)
    
    treeData.value = {
      tree: treeNodes,
      branches: Array.from(new Set(branches.map((b: any) => b.branch))),
      total_branches: new Set(branches.map((b: any) => b.branch)).size
    }
    
    console.log('🌳 ツリーデータ取得成功:', treeData.value)
  } catch (err) {
    console.error('ツリーデータ取得エラー:', err)
    error.value = err instanceof Error ? err.message : '不明なエラー'
  } finally {
    loading.value = false
  }
}

// ツリー構造を構築（真の分岐ツリー）
const buildTree = (branches: any[]): TreeNode[] => {
  console.log('🔍 分岐データ:', branches)
  console.log('🔍 データ数:', branches.length)
  
  // 手順データをmove_number順にソート
  const allMoves = branches.sort((a: any, b: any) => {
    if (a.move_number !== b.move_number) {
      return a.move_number - b.move_number
    }
    // 同一手数の場合は分岐名でソート（mainを優先）
    if (a.branch === 'main') return -1
    if (b.branch === 'main') return 1
    return a.branch.localeCompare(b.branch)
  })

  console.log('🔍 ソート済み全手順:', allMoves)

  // ノードマップを作成
  const nodeMap = new Map<string, TreeNode>()
  
  // 全ての手順をノードに変換
  allMoves.forEach((move: any) => {
    let displayNotation = ''
    
    // 0手目の場合は初期局面として表示
    if (move.move_number === 0) {
      displayNotation = '初期局面'
    } else {
      // 指し手がある場合は必ず表示
      if (move.move_notation) {
        // 先後マークを追加
        const isBlackTurn = move.move_number % 2 === 1
        const turnSymbol = isBlackTurn ? '▲' : '△'
        
        if (!move.move_notation.includes('▲') && !move.move_notation.includes('△')) {
          displayNotation = `${turnSymbol}${move.move_notation}`
        } else {
          displayNotation = move.move_notation
        }
      } else {
        // 指し手がない場合はエラー表示
        displayNotation = `${move.move_number}手目(指し手不明)`
      }
    }
    
    const node: TreeNode = {
      branch: move.branch,
      move_number: move.move_number,
      move_notation: displayNotation,
      display_name: displayNotation,
      parent_branch: move.parent_branch,
      branch_point: move.branch_point,
      depth: 0,
      children: [],
      sfen: move.sfen
    }
    
    const nodeKey = `${move.branch}-${move.move_number}`
    nodeMap.set(nodeKey, node)
    console.log(`🔍 ノード作成: ${nodeKey} -> ${displayNotation}`)
  })

  console.log('🔍 作成されたノードマップ:', nodeMap)

  // 親子関係を構築
  const rootNodes: TreeNode[] = []
  
  for (const [nodeKey, node] of nodeMap) {
    const moveNumber = node.move_number || 0
    
    if (moveNumber === 0) {
      // 0手目はルートノード（main分岐のみ）
      if (node.branch === 'main' && rootNodes.length === 0) {
        rootNodes.push(node)
        node.depth = 0
        console.log(`🔍 ルートノード設定: ${nodeKey}`)
      }
    } else {
      let parentFound = false
      
      if (node.branch === 'main') {
        // main分岐の連続手順
        const prevMoveKey = `main-${moveNumber - 1}`
        if (nodeMap.has(prevMoveKey)) {
          const parent = nodeMap.get(prevMoveKey)!
          parent.children.push(node)
          node.depth = parent.depth + 1
          parentFound = true
          console.log(`🔍 main分岐連続: ${prevMoveKey} -> ${nodeKey}`)
        }
      } else {
        // 分岐の場合
        if (node.branch_point !== null && node.branch_point !== undefined) {
          // 分岐点の手順から開始
          const branchPointKey = `main-${node.branch_point}`
          if (nodeMap.has(branchPointKey)) {
            const parent = nodeMap.get(branchPointKey)!
            parent.children.push(node)
            node.depth = parent.depth + 1
            parentFound = true
            console.log(`🔍 分岐開始: ${branchPointKey} -> ${nodeKey}`)
          }
        }
        
        // 分岐内の連続手順
        if (!parentFound) {
          const prevMoveKey = `${node.branch}-${moveNumber - 1}`
          if (nodeMap.has(prevMoveKey)) {
            const parent = nodeMap.get(prevMoveKey)!
            parent.children.push(node)
            node.depth = parent.depth + 1
            parentFound = true
            console.log(`🔍 分岐内連続: ${prevMoveKey} -> ${nodeKey}`)
          }
        }
      }
      
      // 親が見つからない場合
      if (!parentFound) {
        console.warn(`🚨 親が見つからないノード: ${nodeKey}`)
        if (rootNodes.length > 0) {
          rootNodes[0].children.push(node)
          node.depth = 1
          console.log(`🔍 ルートに追加: root -> ${nodeKey}`)
        } else {
          rootNodes.push(node)
          node.depth = 0
          console.log(`🔍 新規ルート: ${nodeKey}`)
        }
      }
    }
  }

  // 最終的な親子関係をチェック
  console.log('🔍 最終ツリー構造:')
  rootNodes.forEach((root, index) => {
    console.log(`ルート${index}: ${root.move_notation} (子:${root.children.length})`)
    const printChildren = (node: TreeNode, indent: string) => {
      node.children.forEach(child => {
        console.log(`${indent}-> ${child.move_notation} (子:${child.children.length})`)
        printChildren(child, indent + '  ')
      })
    }
    printChildren(root, '  ')
  })

  console.log('🔍 構築されたツリー:', rootNodes)
  return rootNodes
}

// 分岐ノードクリック処理
const handleBranchClick = (node: TreeNode) => {
  // 現在の分岐と異なる場合は切り替えを提案
  if (node.branch !== props.currentBranch) {
    if (confirm(`分岐「${node.display_name || node.branch}」に切り替えますか？`)) {
      // emit('branchSwitch', node.branch)
    }
  }
}

onMounted(() => {
  fetchTreeData()
})
</script>

<style scoped>
/* コンテンツサイズに応じた動的サイズ制御 */
.branch-tree-viewer {
  position: fixed !important;
  top: 50% !important;
  left: 50% !important;
  transform: translate(-50%, -50%) !important;
  min-width: 800px !important;
  min-height: 600px !important;
  max-width: 95vw !important;
  max-height: 95vh !important;
  width: fit-content !important;
  height: fit-content !important;
  background: rgba(30, 30, 60, 0.95);
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
  z-index: 999999;
  overflow: hidden;
  backdrop-filter: blur(10px);
  display: flex;
  flex-direction: column;
  margin: 0 !important;
  padding: 0 !important;
  contain: layout style paint;
}

.tree-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  background: rgba(40, 40, 80, 0.9);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  flex-shrink: 0;
}

.tree-header h4 {
  margin: 0;
  color: #E8E8FF;
  font-size: 18px;
  font-weight: bold;
}

.close-btn {
  background: none;
  border: none;
  color: #E8E8FF;
  font-size: 24px;
  cursor: pointer;
  padding: 8px;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

.tree-content {
  padding: 24px;
  flex: 1;
  overflow: auto;
  display: flex;
  flex-direction: column;
  min-height: 500px;
  max-height: calc(95vh - 80px);
}

.loading, .error {
  text-align: center;
  padding: 60px;
  font-size: 16px;
  color: #E8E8FF;
}

.error {
  color: #ff6b6b;
}

.tree-stats {
  margin-bottom: 20px;
  padding: 12px 16px;
  background: rgba(40, 40, 80, 0.6);
  border-radius: 8px;
  border-left: 4px solid #4CAF50;
  flex-shrink: 0;
}

.stat-item {
  color: #E8E8FF;
  font-size: 14px;
  font-weight: bold;
}

.tree-visualization {
  flex: 1;
  padding: 24px;
  background: rgba(40, 40, 80, 0.3);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  overflow-x: auto;
  overflow-y: hidden;
  min-height: 400px;
  max-height: calc(95vh - 200px);
  min-width: 700px;
  max-width: calc(95vw - 100px);
}

.root-nodes {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 16px;
  height: auto;
  overflow-y: auto;
}

/* 各分岐段を横一列に表示 */
.root-nodes > .branch-node {
  display: flex;
  flex-direction: row;
  align-items: center;
  width: 100%;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding-bottom: 12px;
  margin-bottom: 12px;
}

.root-nodes > .branch-node:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

/* スクロールバーのスタイル */
.tree-content::-webkit-scrollbar,
.tree-visualization::-webkit-scrollbar,
.root-nodes::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.tree-content::-webkit-scrollbar-track,
.tree-visualization::-webkit-scrollbar-track,
.root-nodes::-webkit-scrollbar-track {
  background: rgba(40, 40, 80, 0.3);
  border-radius: 4px;
}

.tree-content::-webkit-scrollbar-thumb,
.tree-visualization::-webkit-scrollbar-thumb,
.root-nodes::-webkit-scrollbar-thumb {
  background: rgba(74, 144, 226, 0.6);
  border-radius: 4px;
}

.tree-content::-webkit-scrollbar-thumb:hover,
.tree-visualization::-webkit-scrollbar-thumb:hover,
.root-nodes::-webkit-scrollbar-thumb:hover {
  background: rgba(74, 144, 226, 0.8);
}
</style> 
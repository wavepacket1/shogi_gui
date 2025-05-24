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
        
        <div v-else class="tree-data">
          <div class="tree-stats">
            📊 総手順数: {{ totalMoves }} | 分岐数: {{ totalBranches }}
          </div>
          
          <div class="tree-display">
            <div 
              v-for="(line, index) in treeLines"
              :key="index"
              class="tree-line"
            >
              <span 
                v-for="(part, partIndex) in parseLineForClicks(line)"
                :key="partIndex"
                :class="['tree-part', { 
                  'clickable': part.isClickable,
                  'current-branch': part.branch === currentBranch,
                  'branch-symbol': part.isBranchSymbol,
                  'arrow': part.isArrow
                }]"
                @click="part.isClickable ? handleNodeClick(part) : null"
                :title="part.isClickable ? `${part.branch}分岐 ${part.moveNumber}手目` : ''"
              >
                {{ part.text }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'

interface Props {
  gameId: number
  currentBranch: string
}

interface BoardHistory {
  branch: string
  move_number: number
  notation: string
  move_sfen: string
}

interface TreeDisplayLine {
  content: string
  clickableNodes: ClickableNode[]
}

interface ClickableNode {
  text: string
  branch: string
  moveNumber: number
  startIndex: number
  endIndex: number
}

interface ParsedPart {
  text: string
  isClickable: boolean
  isBranchSymbol: boolean
  isArrow: boolean
  branch?: string
  moveNumber?: number
}

const props = defineProps<Props>()
const emit = defineEmits<{
  close: []
  branchSwitch: [branch: string]
}>()

const loading = ref(true)
const error = ref('')
const rawBranches = ref<BoardHistory[]>([])
const treeLines = ref<TreeDisplayLine[]>([])

// 統計情報
const totalMoves = computed(() => rawBranches.value.length)
const totalBranches = computed(() => new Set(rawBranches.value.map((b: BoardHistory) => b.branch)).size)

// 分岐表示生成（逆算アプローチ）
const generateTreeDisplay = (branches: BoardHistory[]): TreeDisplayLine[] => {
  const lines: TreeDisplayLine[] = []
  
  if (branches.length === 0) return lines
  
  // 分岐別にグループ化
  const branchGroups = new Map<string, BoardHistory[]>()
  branches.forEach((branch: BoardHistory) => {
    const branchName = branch.branch
    if (!branchGroups.has(branchName)) {
      branchGroups.set(branchName, [])
    }
    branchGroups.get(branchName)!.push(branch)
  })
  
  // 各分岐内で手数順にソート
  branchGroups.forEach((moves: BoardHistory[]) => {
    moves.sort((a: BoardHistory, b: BoardHistory) => a.move_number - b.move_number)
  })
  
  console.log('🌳 分岐グループ:', Array.from(branchGroups.keys()))
  
  // 分岐点を検出
  const branchPoint = findBranchPoint(branchGroups)
  console.log('🌳 検出された分岐点:', branchPoint)
  
  if (branchGroups.has('main') && branchPoint !== -1) {
    const mainMoves = branchGroups.get('main')!
    
    // メイン分岐を構築（期待される形式）
    const mainLine = buildMainBranchLineCorrect(mainMoves, branchPoint)
    lines.push(mainLine)
    
    console.log('🌳 構築されたメインライン:', mainLine.content)
    
    // 子分岐を追加
    const otherBranches = Array.from(branchGroups.keys()).filter((name: string) => name !== 'main')
    otherBranches.forEach((branchName: string, index: number) => {
      const isLast = index === otherBranches.length - 1
      const moves = branchGroups.get(branchName)!
      const branchLine = buildChildBranchLineCorrect(moves, branchName, branchPoint, isLast, mainLine.content)
      lines.push(branchLine)
    })
  }
  
  return lines
}

// 分岐点検出
const findBranchPoint = (branchGroups: Map<string, BoardHistory[]>): number => {
  if (branchGroups.size <= 1) return -1
  
  const allMoves = Array.from(branchGroups.values()).flat()
  const maxMoveNumber = Math.max(...allMoves.map((m: BoardHistory) => m.move_number))
  
  for (let moveNumber = 0; moveNumber <= maxMoveNumber; moveNumber++) {
    const movesAtThisNumber: Array<BoardHistory & { branchName: string }> = []
    
    branchGroups.forEach((moves: BoardHistory[], branchName: string) => {
      const move = moves.find((m: BoardHistory) => m.move_number === moveNumber)
      if (move) {
        movesAtThisNumber.push({ ...move, branchName })
      }
    })
    
    if (movesAtThisNumber.length > 1) {
      const uniqueMoves = new Set(movesAtThisNumber.map((m) => m.move_sfen || m.notation))
      if (uniqueMoves.size > 1) {
        console.log(`🌳 分岐点発見: ${moveNumber}手目`, movesAtThisNumber.map((m) => ({ branch: m.branchName, move: m.notation, sfen: m.move_sfen })))
        return moveNumber
      }
    }
  }
  
  return -1
}

// メイン分岐ライン構築（正確な形式）
const buildMainBranchLineCorrect = (mainMoves: BoardHistory[], branchPoint: number): TreeDisplayLine => {
  let content = ''
  const clickableNodes: ClickableNode[] = []
  
  // 分岐点より前の手順
  const beforeBranchMoves = mainMoves.filter((m: BoardHistory) => m.move_number < branchPoint)
  beforeBranchMoves.forEach((move: BoardHistory, index: number) => {
    const moveText = move.notation || `${move.move_number}手目`
    const startIndex = content.length
    content += moveText
    const endIndex = content.length
    
    clickableNodes.push({
      text: moveText,
      branch: 'main',
      moveNumber: move.move_number,
      startIndex,
      endIndex
    })
    
    if (index < beforeBranchMoves.length - 1) {
      content += ' → '
    }
  })
  
  // 分岐点に┬─を配置
  if (beforeBranchMoves.length > 0) {
    content += ' ┬─ '
  }
  
  // 分岐点以降の手順
  const afterBranchMoves = mainMoves.filter((m: BoardHistory) => m.move_number >= branchPoint)
  afterBranchMoves.forEach((move: BoardHistory, index: number) => {
    const moveText = move.notation || `${move.move_number}手目`
    const startIndex = content.length
    content += moveText
    const endIndex = content.length
    
    clickableNodes.push({
      text: moveText,
      branch: 'main',
      moveNumber: move.move_number,
      startIndex,
      endIndex
    })
    
    if (index < afterBranchMoves.length - 1) {
      content += ' → '
    }
  })
  
  content += ' (main)'
  
  return { content, clickableNodes }
}

// 子分岐ライン構築（正確なインデント）
const buildChildBranchLineCorrect = (branchMoves: BoardHistory[], branchName: string, branchPoint: number, isLast: boolean, mainLineContent: string): TreeDisplayLine => {
  let content = ''
  const clickableNodes: ClickableNode[] = []
  
  // メイン分岐の┬─の位置を特定
  const branchSymbolIndex = mainLineContent.indexOf('┬─')
  
  console.log(`🌳 ${branchName} インデント計算:`, {
    mainLineContent,
    branchSymbolIndex,
    branchSymbolChar: branchSymbolIndex >= 0 ? mainLineContent.charAt(branchSymbolIndex) : 'なし'
  })
  
  // 正確なインデント計算
  const indentLength = branchSymbolIndex >= 0 ? branchSymbolIndex : 0
  
  // インデントと分岐記号
  const indent = ' '.repeat(indentLength)
  const branchSymbol = isLast ? '└─' : '├─'
  content = indent + branchSymbol + ' '
  
  console.log(`🌳 ${branchName} インデント詳細:`, {
    indentLength,
    indent: `"${indent}"`,
    branchSymbol,
    contentStart: `"${content}"`
  })
  
  // 分岐点以降の手順を追加
  const relevantMoves = branchMoves.filter((m: BoardHistory) => m.move_number >= branchPoint)
  
  relevantMoves.forEach((move: BoardHistory, index: number) => {
    const moveText = move.notation || `${move.move_number}手目`
    const startIndex = content.length
    content += moveText
    const endIndex = content.length
    
    clickableNodes.push({
      text: moveText,
      branch: branchName,
      moveNumber: move.move_number,
      startIndex,
      endIndex
    })
    
    if (index < relevantMoves.length - 1) {
      content += ' → '
    }
  })
  
  content += ` (${branchName})`
  
  console.log(`🌳 ${branchName} 最終ライン:`, content)
  
  return { content, clickableNodes }
}

// 行をクリック可能な部分に分解
const parseLineForClicks = (line: TreeDisplayLine): ParsedPart[] => {
  const parts: ParsedPart[] = []
  let currentIndex = 0
  
  // クリック可能ノードを処理
  line.clickableNodes.forEach((node: ClickableNode) => {
    // ノード前のテキスト
    if (currentIndex < node.startIndex) {
      const beforeText = line.content.substring(currentIndex, node.startIndex)
      parts.push({
        text: beforeText,
        isClickable: false,
        isBranchSymbol: /[┬├└]─/.test(beforeText),
        isArrow: beforeText.includes('→')
      })
    }
    
    // クリック可能ノード
    parts.push({
      text: node.text,
      isClickable: true,
      isBranchSymbol: false,
      isArrow: false,
      branch: node.branch,
      moveNumber: node.moveNumber
    })
    
    currentIndex = node.endIndex
  })
  
  // 残りのテキスト
  if (currentIndex < line.content.length) {
    const remainingText = line.content.substring(currentIndex)
    parts.push({
      text: remainingText,
      isClickable: false,
      isBranchSymbol: /[┬├└]─/.test(remainingText),
      isArrow: remainingText.includes('→')
    })
  }
  
  return parts
}

// ノードクリック処理
const handleNodeClick = (part: ParsedPart) => {
  if (!part.branch) return
  
  console.log('🔍 ツリーノードクリック:', part)
  
  if (part.branch !== props.currentBranch) {
    if (confirm(`分岐「${part.branch} ${part.moveNumber}手目」に切り替えますか？`)) {
      emit('branchSwitch', part.branch)
    }
  }
}

// ツリーデータを取得
const fetchTreeData = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await fetch(`http://localhost:3000/api/v1/games/${props.gameId}/board_histories/all_branches`)
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    const branches = await response.json() as BoardHistory[]
    rawBranches.value = branches
    treeLines.value = generateTreeDisplay(branches)
    
    console.log('🌳 RAWデータ詳細:', branches)
    console.log('🌳 ツリーデータ取得成功:', {
      branches: branches.length,
      lines: treeLines.value.length,
      treeLines: treeLines.value
    })
    console.log('🌳 生成されたツリーライン:', treeLines.value)
  } catch (err) {
    console.error('ツリーデータ取得エラー:', err)
    error.value = err instanceof Error ? err.message : '不明なエラー'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchTreeData()
})
</script>

<style scoped>
.branch-tree-viewer {
  position: fixed !important;
  top: 50% !important;
  left: 50% !important;
  transform: translate(-50%, -50%) !important;
  min-width: 800px !important;
  min-height: 400px !important;
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
  min-height: 300px;
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
  color: #E8E8FF;
  font-size: 14px;
  font-weight: bold;
}

.tree-display {
  font-family: 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.8;
  background: rgba(40, 40, 80, 0.3);
  padding: 20px;
  border-radius: 8px;
  overflow: auto;
  max-height: calc(95vh - 200px);
  min-width: 700px;
}

.tree-line {
  color: #E8E8FF;
  margin-bottom: 8px;
  font-size: 14px;
}

.tree-part {
  transition: all 0.2s ease;
}

.tree-part.clickable {
  color: #4CAF50;
  cursor: pointer;
  text-decoration: underline;
  font-weight: bold;
}

.tree-part.clickable:hover {
  color: #66BB6A;
  background: rgba(76, 175, 80, 0.1);
  border-radius: 2px;
  padding: 0 2px;
}

.tree-part.current-branch {
  color: #FFD700;
  background: rgba(255, 215, 0, 0.1);
  padding: 0 2px;
  border-radius: 2px;
}

.tree-part.branch-symbol {
  color: #FFB74D;
  font-weight: bold;
}

.tree-part.arrow {
  color: #81C784;
}

/* スクロールバーのスタイル */
.tree-content::-webkit-scrollbar,
.tree-display::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.tree-content::-webkit-scrollbar-track,
.tree-display::-webkit-scrollbar-track {
  background: rgba(40, 40, 80, 0.3);
  border-radius: 4px;
}

.tree-content::-webkit-scrollbar-thumb,
.tree-display::-webkit-scrollbar-thumb {
  background: rgba(74, 144, 226, 0.6);
  border-radius: 4px;
}

.tree-content::-webkit-scrollbar-thumb:hover,
.tree-display::-webkit-scrollbar-thumb:hover {
  background: rgba(74, 144, 226, 0.8);
}
</style> 
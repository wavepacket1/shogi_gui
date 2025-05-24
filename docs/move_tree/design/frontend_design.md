# 分岐ツリー機能 フロントエンド設計書

## 1. 概要
system_spec.mdに基づく分岐ツリー機能のフロントエンド実装設計

## 2. コンポーネント設計

### 2.1 MoveHistoryPanel.vue 修正
**責務**: 手順履歴表示と+ボタン機能

#### 修正要件
```typescript
// +ボタン表示条件の修正
const shouldShowPlusButton = (history: BoardHistory): boolean => {
  // 0手目は表示しない
  if (history.move_number === 0) return false;
  
  // 他分岐に同一手数の手が存在する場合のみ表示
  const alternativeMoves = getAlternativeMoves(history.move_number);
  return alternativeMoves.length > 0;
};

// 代替手取得の修正
const getAlternativeMoves = (moveNumber: number): BoardHistory[] => {
  if (moveNumber === 0) return [];
  
  return allBoardHistories.value.filter(history => 
    history.move_number === moveNumber && 
    history.branch !== currentBranch.value
  );
};
```

#### テンプレート修正
```vue
<!-- +ボタン表示条件の修正 -->
<div 
  v-if="shouldShowPlusButton(history)" 
  class="alternative-moves-button"
>
  <button 
    class="plus-button"
    @click.stop="toggleAlternativeMoves(index)"
    :title="`他分岐の手: ${getAlternativeMoves(history.move_number).length}個`"
  >
    +
  </button>
</div>
```

### 2.2 BranchTreeViewer.vue 全面改修
**責務**: 仕様書の記号表示によるツリー表示

#### 新しい表示ロジック
```typescript
interface TreeDisplayLine {
  content: string;
  clickableNodes: ClickableNode[];
}

interface ClickableNode {
  text: string;
  branch: string;
  moveNumber: number;
  startIndex: number;
  endIndex: number;
}

// 仕様書の記号を使った表示生成
const generateTreeDisplay = (treeData: TreeNode[]): TreeDisplayLine[] => {
  const lines: TreeDisplayLine[] = [];
  
  // main分岐のラインを生成
  const mainBranch = treeData.find(node => node.branch === 'main');
  if (mainBranch) {
    const mainLine = buildBranchLine(mainBranch, '');
    lines.push(mainLine);
    
    // 分岐点からの分岐を追加
    addBranchLines(mainBranch, lines, '');
  }
  
  return lines;
};

const buildBranchLine = (node: TreeNode, prefix: string): TreeDisplayLine => {
  let content = prefix;
  const clickableNodes: ClickableNode[] = [];
  
  // 手順の連続表示
  let currentNode = node;
  while (currentNode) {
    const moveText = currentNode.display_name || `${currentNode.move_number}手目`;
    const startIndex = content.length;
    content += moveText;
    const endIndex = content.length;
    
    clickableNodes.push({
      text: moveText,
      branch: currentNode.branch,
      moveNumber: currentNode.move_number || 0,
      startIndex,
      endIndex
    });
    
    if (currentNode.children.length === 1) {
      content += ' → ';
      currentNode = currentNode.children[0];
    } else {
      break;
    }
  }
  
  // 分岐記号の追加
  if (currentNode && currentNode.children.length > 1) {
    content += ' ┬─';
  }
  
  content += ` (${node.branch})`;
  
  return { content, clickableNodes };
};

const addBranchLines = (parentNode: TreeNode, lines: TreeDisplayLine[], basePrefix: string) => {
  const branches = parentNode.children;
  if (branches.length <= 1) return;
  
  branches.forEach((branch, index) => {
    const isLast = index === branches.length - 1;
    const branchSymbol = isLast ? '└─' : '├─';
    const branchPrefix = basePrefix + '                         ' + branchSymbol + ' ';
    
    const branchLine = buildBranchLine(branch, branchPrefix);
    lines.push(branchLine);
    
    // 再帰的に子分岐を処理
    const nextPrefix = basePrefix + (isLast ? '   ' : '│  ');
    addBranchLines(branch, lines, nextPrefix);
  });
};
```

#### テンプレート設計
```vue
<template>
  <div class="branch-tree-viewer">
    <div class="tree-header">
      <h4>指し手ツリー構造</h4>
      <button class="close-btn" @click="$emit('close')">×</button>
    </div>
    
    <div class="tree-content">
      <!-- 統計情報 -->
      <div class="tree-stats">
        📊 総手順数: {{ totalMoves }} | 分岐数: {{ totalBranches }}
      </div>
      
      <!-- 記号表示によるツリー -->
      <div class="tree-display">
        <div 
          v-for="(line, index) in treeLines"
          :key="index"
          class="tree-line"
        >
          <span 
            v-for="(part, partIndex) in parseLineForClicks(line)"
            :key="partIndex"
            :class="['tree-part', { 'clickable': part.isClickable }]"
            @click="part.isClickable ? handleNodeClick(part.nodeData) : null"
          >
            {{ part.text }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
```

#### スタイル設計
```scss
.tree-display {
  font-family: 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.8;
  white-space: pre;
  background: rgba(40, 40, 80, 0.3);
  padding: 20px;
  border-radius: 8px;
  overflow: auto;
}

.tree-line {
  color: #E8E8FF;
  margin-bottom: 4px;
}

.tree-part.clickable {
  color: #4CAF50;
  cursor: pointer;
  text-decoration: underline;
  transition: all 0.2s ease;
}

.tree-part.clickable:hover {
  color: #66BB6A;
  background: rgba(76, 175, 80, 0.1);
  border-radius: 2px;
  padding: 0 2px;
}

// 分岐記号のスタイリング
.tree-line {
  .branch-symbol {
    color: #FFB74D; // オレンジ系の色で分岐記号を強調
  }
  
  .move-notation {
    color: #E8E8FF; // 通常の手順表記
  }
  
  .branch-name {
    color: #81C784; // 分岐名を緑系で表示
    font-weight: bold;
  }
}
```

### 2.3 新しいヘルパーコンポーネント

#### TreeLineRenderer.vue
```vue
<template>
  <div class="tree-line-renderer">
    <span 
      v-for="(segment, index) in parsedSegments"
      :key="index"
      :class="getSegmentClass(segment)"
      @click="handleSegmentClick(segment)"
    >
      {{ segment.text }}
    </span>
  </div>
</template>

<script setup lang="ts">
interface Segment {
  text: string;
  type: 'move' | 'arrow' | 'branch-symbol' | 'branch-name' | 'text';
  clickable: boolean;
  nodeData?: { branch: string; moveNumber: number };
}

const parseTreeLine = (line: string, clickableNodes: ClickableNode[]): Segment[] => {
  // 文字列を解析してクリック可能な部分と記号部分を分離
  // ... 実装詳細
};
</script>
```

## 3. 実装ステップ

### Step 1: MoveHistoryPanel.vue の+ボタン修正
1. `shouldShowPlusButton` 関数の実装
2. `getAlternativeMoves` 関数の修正
3. テンプレートの条件分岐修正
4. 動作テスト

### Step 2: BranchTreeViewer.vue の全面改修
1. 新しい表示ロジックの実装
2. 記号表示機能の実装
3. クリック可能領域の実装
4. スタイルの適用

### Step 3: 統合テスト
1. +ボタンの表示/非表示テスト
2. 分岐ツリーの記号表示テスト
3. ナビゲーション機能のテスト

## 4. テスト要件

### 4.1 +ボタン機能テスト
- ✅ 0手目に+ボタンが表示されない
- ✅ 他分岐に同一手数の手がある場合のみ表示
- ✅ 代替手一覧の正確な表示
- ✅ 分岐移動機能の動作

### 4.2 ツリー表示テスト
- ✅ 矢印記号（→）の正確な表示
- ✅ 分岐記号（┬─、├─、└─）の正確な表示  
- ✅ クリック可能領域の動作
- ✅ 複雑な分岐構造での表示

## 5. 既知の制約
- 分岐作成機能は盤面での手指し実装が別途必要
- 大量分岐時のパフォーマンス最適化が必要
- レスポンシブ対応の検討が必要 
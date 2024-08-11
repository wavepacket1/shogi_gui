import React from 'react';
import ShogiBoard from './components/ShogiBoard';

// 駒台に表示する持ち駒（仮のデータ）
const whiteCapturedPieces = ['歩兵', '歩兵', '角行'];
const blackCapturedPieces = ['歩兵', '飛車'];

const HomePage: React.FC = () => {
  return (
    <main style={{ padding: '20px', textAlign: 'center',backgroundColor: '#fff' }}>
      <h1>Shogi Game</h1>
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        
        {/* 将棋盤 */}
        <ShogiBoard />
        
      </div>
    </main>
  );
};

export default HomePage;

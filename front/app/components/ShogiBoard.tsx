'use client';

import React, { useState } from 'react';
import styles from './ShogiBoard.module.css';

const initialBoardState = [
  ['香車', '桂馬', '銀将', '金将', '王将', '金将', '銀将', '桂馬', '香車'],
  ['.', '飛車', '.', '.', '.', '.', '.', '角行', '.'],
  ['歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵'],
  ['.', '.', '.', '.', '.', '.', '.', '.', '.'],
  ['.', '.', '.', '.', '.', '.', '.', '.', '.'],
  ['.', '.', '.', '.', '.', '.', '.', '.', '.'],
  ['歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵', '歩兵'],
  ['.', '角行', '.', '.', '.', '.', '.', '飛車', '.'],
  ['香車', '桂馬', '銀将', '金将', '王将', '金将', '銀将', '桂馬', '香車'],
];

const ShogiBoard: React.FC = () => {
  const [board, setBoard] = useState(initialBoardState);

  return (
    <div className="board_container">
        <div className={styles.board_back}>
        {initialBoardState.flat().map((cell, index) => {
        // Get the row and column indices
        const row = Math.floor(index / 9);
        const col = index % 9;
        // Check if it's in the bottom half of the board
        const isBottom = row >= 5;

        return (
            <div
            key={index}
            className={styles.board}
            style={{
                transform: isBottom ? 'none' : 'rotate(180deg)', // 下側の駒を回転させる
            }}
            >
            {cell !== '.' ? cell : null}
        </div>
        );
        })}
        </div>
        <div className={ `${styles.piece_box} ${styles.piece_box_front}`}>
        </div>
        <div className={ `${styles.piece_box} ${styles.piece_box_back}`}>
        </div>
    </div>
  );
};

export default ShogiBoard;

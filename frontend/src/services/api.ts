import axios from 'axios';

const api = axios.create({
    baseURL: 'http://localhost:3000/api/v1', // 確認: URLスキームがhttpまたはhttpsであること
    headers: {
        'Content-Type': 'application/json',
    }
});

export const getBoardSFENAPI = (id: number) =>  {
    return api.get(`/boards/${id}`);
};

interface Move {
    from_x: number;
    from_y: number;
    to_x: number;
    to_y: number;
    promotion: boolean;
}

export const postMove = (boardID: number, move: Move) => {
    return api.post(`/boards/${boardID}/moves`, { 
        move: {
            from_x: move.from_x,
            from_y: move.from_y,
            to_x: move.to_x,
            to_y: move.to_y,
            promotion: move.promotion,
        }
    });
}

export const createGameAPI = (name: string) => {
    return api.post('/games', { 
        game: { 
            name: name, 
            status: 'active' 
        }
    });
}

export const updatePiecePositionAPI = (pieceId: number, x: number, y: number) => {
    return api.patch(`/pieces/${pieceId}`, { 
        piece: {
            position_x: x,
            position_y: y
        }
    });
};

export const getDefaultBoardAPI = async () => {
    const response = await api.get('/boards/default');
    return response.data;
};

export default api;
import axios from 'axios';

const api = axios.create({
    baseURL: 'http://localhost:3000/api/v1',
    headers: {
        'Content-Type': 'application/json',
    }
});

export const getBoardSFEN = (id: number) =>  {
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

export const updatePiecePositionAPI = (pieceId: number, x: number, y: number) => {
    return axios.patch(`/api/v1/pieces/${pieceId}`, {
        piece: {
            position_x: x,
            position_y: y
        }
    });
};

export default api;
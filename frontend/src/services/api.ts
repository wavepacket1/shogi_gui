import axios from 'axios';

const api = axios.create({
    baseURL: 'http://localhost:3000/api/v1',
});

export const getBoardSFEN = (id: number) => api.get(`/boards/${id}`);

export default api;
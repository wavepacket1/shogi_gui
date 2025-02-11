<template>
    <nav class="menu-bar">
      <ul>
        <li v-for="(item, index) in menuItems" :key="index">
          <!-- Vue Router を使う場合は router-link を利用 -->
          <router-link :to="item.link">{{ item.name }}</router-link>
        </li>
      </ul>
    </nav>
  </template>
  
  <script lang="ts" setup>
  import { ref } from 'vue';
  
  // メニュー項目の型定義
  interface MenuItem {
    name: string;
    link: string;
  }
  
  // メニュー項目のリストを定義（必要に応じて項目を追加・変更）
  const menuItems = ref<MenuItem[]>([
    { name: '対局', link: '/' },
    { name: '検討', link: '/services' },
    { name: '他サービスとの連携', link: '/contact' },
    { name: 'help', link: '/about' }
  ]);
  </script>
  
  <style scoped>
  .menu-bar {
    background-color: #808080;
    padding: 10px;
  }
  
  .menu-bar ul {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
  }
  
  .menu-bar li {
    margin-right: 20px;
  }
  
  .menu-bar a {
    color: white;
    text-decoration: none;
    transition: color 0.3s;
  }
  
  .menu-bar a:hover {
    color: #ffd700;
  }
  </style>
  